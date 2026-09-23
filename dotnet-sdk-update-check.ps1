#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Atualiza o índice do apt, verifica se há um SDK .NET mais novo e,
    se houver, oferece instalar.

.DESCRIPTION
    1. Roda 'sudo apt update' para garantir que o apt enxerga os feeds
       mais recentes.
    2. Compara a versão do SDK instalada (via 'dotnet --version') com o
       candidato do apt para o pacote da mesma major
       ('apt-cache policy dotnet-sdk-<major>.0' — Instalado vs Candidato).
    3. Verifica também se existe uma major mais nova nos feeds (ex.:
       dotnet-sdk-11 aparecer enquanto você está no 10), o que o passo 2
       sozinho não detectaria.
    4. Se qualquer uma das duas checagens indicar atualização disponível,
       pergunta se você quer instalar agora.

    A instalação segue a mesma estratégia do dotnet-update-sdk.zsh: remove
    TODOS os pacotes dotnet-sdk-* atualmente instalados antes de instalar
    o pacote alvo, evitando conviver com versões antigas.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.2
    Requer: Ubuntu/Debian (apt, apt-cache, dpkg-query), dotnet SDK instalado, sudo

.EXAMPLE
    ./dotnet-sdk-update-check.ps1
#>

$ErrorActionPreference = 'Stop'
Clear-Host

# ---------------------------------------------------------------------------
# Carrega módulos compartilhados
# ---------------------------------------------------------------------------
$scriptDir = $PSScriptRoot

$styleModule = Join-Path $scriptDir 'SharedStyle.psm1'
if (-not (Test-Path $styleModule)) {
    Write-Host "Erro: arquivo de biblioteca '$styleModule' não encontrado." -ForegroundColor Red
    exit 1
}
Import-Module $styleModule -Force

$commonModule = Join-Path $scriptDir 'DotnetCommon.psm1'
if (-not (Test-Path $commonModule)) {
    Write-ErrMessage "Arquivo de biblioteca '$commonModule' não encontrado."
    exit 1
}
Import-Module $commonModule -Force

# ---------------------------------------------------------------------------
# Validações iniciais
# ---------------------------------------------------------------------------
Assert-DotnetCli
Assert-CommandAvailable -Command 'apt-cache' -Message "O comando 'apt-cache' não está disponível. Este script requer Ubuntu/Debian."
Assert-CommandAvailable -Command 'apt' -Message "O comando 'apt' não está disponível. Este script requer Ubuntu/Debian."
Assert-CommandAvailable -Command 'dpkg-query' -Message "O comando 'dpkg-query' não está disponível."

# ---------------------------------------------------------------------------
# Funções locais
# ---------------------------------------------------------------------------

# Extrai um [version] "limpo" (major.minor.patch) do início de uma string,
# descartando sufixos de build do apt (ex.: "10.0.100-1" -> 10.0.100).
function Convert-ToCleanVersion {
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return $null }
    if ($Raw -match '(\d+(?:\.\d+){1,3})') {
        return [version]$Matches[1]
    }
    return $null
}

# Equivalente a "apt-cache policy <pacote>", extraindo as linhas
# Instalado/Installed e Candidato/Candidate independente do idioma
# configurado no sistema.
function Get-AptPolicyInfo {
    param([Parameter(Mandatory)][string]$Package)

    $output = apt-cache policy $Package 2>$null
    if (-not $output) {
        return [pscustomobject]@{ Package = $Package; Installed = $null; Candidate = $null; Found = $false }
    }

    $installedLine = $output | Select-String -Pattern '^\s*(Instalado|Installed):\s*(.+)$'
    $candidateLine = $output | Select-String -Pattern '^\s*(Candidato|Candidate):\s*(.+)$'

    $installedRaw = if ($installedLine) { $installedLine.Matches[0].Groups[2].Value.Trim() } else { $null }
    $candidateRaw = if ($candidateLine) { $candidateLine.Matches[0].Groups[2].Value.Trim() } else { $null }

    [pscustomobject]@{
        Package   = $Package
        Installed = $installedRaw
        Candidate = $candidateRaw
        Found     = $true
    }
}

# Lista os pacotes dotnet-sdk-* disponíveis no apt e retorna o de maior
# versão (mesma lógica de find_latest_sdk_package em dotnet-update-sdk.zsh).
function Get-LatestSdkPackageName {
    $searchOutput = apt-cache search '^dotnet-sdk-[0-9]' 2>$null
    if (-not $searchOutput) { return $null }

    $packages = $searchOutput |
        ForEach-Object { ($_ -split '\s+')[0] } |
        Where-Object { $_ -match '^dotnet-sdk-\d+(\.\d+)?$' }

    if (-not $packages) { return $null }

    $packages |
        Sort-Object -Property @{ Expression = {
            if ($_ -match 'dotnet-sdk-(\d+)(?:\.(\d+))?$') {
                [version]"$($Matches[1]).$(if ($Matches[2]) { $Matches[2] } else { '0' })"
            }
            else { [version]'0.0' }
        } } |
        Select-Object -Last 1
}

# Lista os pacotes dotnet-sdk-* atualmente instalados no sistema (via
# dpkg-query), equivalente a list_installed_sdk_packages em
# dotnet-update-sdk.zsh.
function Get-InstalledSdkPackages {
    $installedOutput = dpkg-query -W -f='${Package}\n' 2>$null
    if (-not $installedOutput) { return @() }

    @($installedOutput -split "`n" | Where-Object { $_ -match '^dotnet-sdk-\d+(\.\d+)?$' })
}

# ---------------------------------------------------------------------------
# Etapa 0 — Atualizar índice de pacotes
# ---------------------------------------------------------------------------
Write-SectionTitle "Etapa 0 — Atualizando índice de pacotes"

Write-InfoMessage "Executando: sudo apt update -y"
sudo apt update -y
if ($LASTEXITCODE -ne 0) {
    Write-ErrMessage "Falha ao atualizar o índice de pacotes."
    exit 1
}
Write-SuccessMessage "Índice de pacotes atualizado."

# ---------------------------------------------------------------------------
# Etapa 1 — Versão atualmente instalada
# ---------------------------------------------------------------------------
Write-SectionTitle "Etapa 1 — Versão instalada"

$installedVersionRaw = dotnet --version
$installedVersion = Convert-ToCleanVersion $installedVersionRaw
$installedMajor = $installedVersion.Major
$currentPackage = "dotnet-sdk-$installedMajor.0"

Write-Field "SDK instalado" $installedVersionRaw
Write-Field "Pacote apt correspondente" $currentPackage

# ---------------------------------------------------------------------------
# Etapa 2 — Atualização de patch dentro da major atual
# ---------------------------------------------------------------------------
Write-SectionTitle "Etapa 2 — Verificando atualizações em $currentPackage"

$currentPolicy = Get-AptPolicyInfo -Package $currentPackage
$patchUpdateAvailable = $false

if (-not $currentPolicy.Found -or -not $currentPolicy.Candidate) {
    Write-WarnMessage "Não foi possível consultar '$currentPackage' via apt-cache policy."
    Write-InfoMessage "Confira se o SDK foi instalado por fora do apt (ex.: dotnet-install.sh)."
}
else {
    $candidateVersion = Convert-ToCleanVersion $currentPolicy.Candidate
    Write-Field "Instalado (apt)" ($currentPolicy.Installed ?? "(nenhum)")
    Write-Field "Candidato (apt)" ($currentPolicy.Candidate ?? "desconhecido")

    if ($candidateVersion -and $installedVersion -and $candidateVersion -gt $installedVersion) {
        $patchUpdateAvailable = $true
        Write-SuccessMessage "Atualização disponível dentro da mesma major: $installedVersionRaw -> $($currentPolicy.Candidate)"
    }
    else {
        Write-InfoMessage "Nenhuma atualização de patch pendente para $currentPackage."
    }
}

# ---------------------------------------------------------------------------
# Etapa 3 — Existência de uma major mais nova
# ---------------------------------------------------------------------------
Write-SectionTitle "Etapa 3 — Verificando se há uma major mais nova"

$latestPackage = Get-LatestSdkPackageName
$newMajorAvailable = $false
$latestMajor = $installedMajor

if (-not $latestPackage) {
    Write-WarnMessage "Nenhum pacote dotnet-sdk-* encontrado nos feeds do apt."
}
else {
    if ($latestPackage -match 'dotnet-sdk-(\d+)') {
        $latestMajor = [int]$Matches[1]
    }

    Write-Field "Pacote mais recente nos feeds" $latestPackage

    if ($latestMajor -gt $installedMajor) {
        $newMajorAvailable = $true
        $latestPolicy = Get-AptPolicyInfo -Package $latestPackage
        $latestVersionLabel = if ($latestPolicy.Candidate) { $latestPolicy.Candidate } else { "$latestMajor.0.x" }
        Write-SuccessMessage "Nova major disponível: .NET $latestMajor (via $latestPackage, candidato: $latestVersionLabel)"
    }
    else {
        Write-InfoMessage "Você já está na major mais recente disponível ($installedMajor)."
    }
}

# ---------------------------------------------------------------------------
# Resumo
# ---------------------------------------------------------------------------
Write-SectionTitle "Resumo"

Write-Field "SDK instalado" $installedVersionRaw
Write-Field "Atualização de patch" $(if ($patchUpdateAvailable) { "Sim" } else { "Não" })
Write-Field "Nova major disponível" $(if ($newMajorAvailable) { "Sim ($latestPackage)" } else { "Não" })

# ---------------------------------------------------------------------------
# Instalação opcional
# ---------------------------------------------------------------------------
if (-not $patchUpdateAvailable -and -not $newMajorAvailable) {
    Write-Host ''
    Write-SuccessMessage "Você já está com a versão mais recente do .NET SDK."
    exit 0
}

# Prioriza instalar a major mais nova quando ambas as checagens acusam
# atualização — instalar a major mais nova já cobre o caso de patch.
$targetPackage = if ($newMajorAvailable) { $latestPackage } else { $currentPackage }

Write-Host ''
Write-InfoMessage "Pacote alvo para instalação: $targetPackage"
$confirm = Read-Host "Deseja instalar agora? (s/N)"

if ($confirm -notmatch '^[sS]$') {
    Write-InfoMessage "Instalação não realizada."
    exit 0
}

# ---------------------------------------------------------------------------
# Remove versões de SDK já instaladas antes de instalar a nova
# ---------------------------------------------------------------------------
Write-SectionTitle "Removendo versões existentes"

$installedPkgs = Get-InstalledSdkPackages

if ($installedPkgs.Count -eq 0) {
    Write-InfoMessage "Nenhum pacote dotnet-sdk-* instalado. Nada a remover."
}
else {
    Write-InfoMessage "Pacotes encontrados:"
    foreach ($pkg in $installedPkgs) {
        $installedVer = (dpkg-query -W -f='${Version}' $pkg 2>$null)
        if (-not $installedVer) { $installedVer = "?" }
        Write-ListItem "$pkg ($installedVer)"
    }

    Write-Host ''
    Write-InfoMessage "Removendo..."
    sudo apt remove -y @installedPkgs
    if ($LASTEXITCODE -ne 0) {
        Write-ErrMessage "Falha ao remover os pacotes existentes. Abortando."
        exit 1
    }

    sudo apt autoremove -y
    if ($LASTEXITCODE -ne 0) {
        Write-WarnMessage "Falha no autoremove. Pode haver dependências residuais."
    }

    Write-SuccessMessage "Versões anteriores removidas."
}

# ---------------------------------------------------------------------------
# Instala a versão nova
# ---------------------------------------------------------------------------
Write-SectionTitle "Instalando $targetPackage"
Write-InfoMessage "Executando: sudo apt install -y $targetPackage"

sudo apt install -y $targetPackage
if ($LASTEXITCODE -ne 0) {
    Write-ErrMessage "Falha ao instalar $targetPackage."
    exit 1
}

Assert-DotnetCli
Write-SuccessMessage "SDK atualizado com sucesso: $(dotnet --version)"