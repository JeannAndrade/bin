#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Instala ou atualiza o Bootstrap via libman no projeto selecionado.

.DESCRIPTION
    Equivalente PowerShell de dotnet-add-bootstrap.zsh.

    Roda na raiz do repositório e:
      1. Localiza .csproj recursivamente (via Find-AndSelectCsproj, de
         DotnetCommon.psm1) e pede para você escolher onde instalar.
      2. Garante libman.json (via "libman init -p cdnjs"), de forma
         idempotente.
      3. Resolve a última versão ESTÁVEL do Bootstrap publicada no cdnjs.
      4. Instala ou atualiza, removendo a instalação antiga antes de
         trocar de versão (evita arquivos órfãos de versões anteriores).

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.0 (convertido de dotnet-add-bootstrap.zsh)

    Pré-requisitos: dotnet SDK, libman CLI já instalado (rode o script de
    setup do libman antes).

    Diferente da versão zsh, não há checagem de "curl" nem de "jq": o
    PowerShell já traz Invoke-RestMethod (faz a chamada HTTP e devolve o
    JSON já convertido em objeto) nativamente, então essas duas
    dependências externas deixam de existir.

    Depende da nova função Find-AndSelectCsproj em DotnetCommon.psm1
    (equivalente a find_and_select_csproj() do dotnet-common.zsh).

.EXAMPLE
    ./dotnet-add-bootstrap.ps1
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
# Validação: dotnet e libman disponíveis
# ---------------------------------------------------------------------------
Assert-DotnetCli
Assert-CommandAvailable -Command 'libman' -Message "libman CLI não encontrado. Rode o script de setup do libman primeiro."

# --- 1. Buscar e selecionar o projeto (lógica compartilhada) ---------------

$selectedProj = Find-AndSelectCsproj -SearchRoot '.'
if (-not $selectedProj) {
  exit 1
}

$projDir = Split-Path -Path $selectedProj -Parent

Write-InfoMessage "Projeto selecionado: $selectedProj"

# Sinal de alerta (não bloqueante): Bootstrap normalmente só faz sentido em
# projetos que usam o SDK Web (Microsoft.NET.Sdk.Web), não em class
# libraries ou console apps. Find-AndSelectCsproj não distingue isso
# porque varre o filesystem cru, sem saber nada sobre o tipo de cada
# projeto.
$projContent = Get-Content -Path $selectedProj -Raw -ErrorAction SilentlyContinue
$projSdk = $null
if ($projContent -match 'Sdk="[^"]*"') {
  $projSdk = $Matches[0]
}

if ($projSdk -notlike '*Sdk.Web*') {
  $sdkLabel = if ($projSdk) { $projSdk } else { 'um Sdk não identificado' }
  Write-WarnMessage "O projeto selecionado usa ${sdkLabel}, não Microsoft.NET.Sdk.Web."
  Write-WarnMessage "Confirma que é esse mesmo o projeto certo para receber assets estáticos?"
}

Write-InfoMessage "Entrando em: $projDir"
Set-Location -Path $projDir

# --- 2. Garantir wwwroot ----------------------------------------------------

if (-not (Test-Path -Path 'wwwroot' -PathType Container)) {
  Write-WarnMessage "Pasta wwwroot não existe em $projDir. Criando..."
  New-Item -Path 'wwwroot' -ItemType Directory -Force | Out-Null
}

# --- 3. Garantir libman.json (idempotente) ----------------------------------

if (Test-Path -Path 'libman.json') {
  Write-InfoMessage "libman.json já existe em $projDir. Pulando 'libman init'."
}
else {
  Write-InfoMessage "Inicializando libman com provider cdnjs..."
  libman init -p cdnjs
}

# --- 4. Resolver a última versão estável do Bootstrap no cdnjs -------------
#
# Optamos por resolver a versão explicitamente via API do cdnjs, em vez de
# confiar em omitir a versão no "libman install" (comportamento que varia
# entre versões da CLI e não é documentado de forma consistente para todos
# os providers). Isso também nos dá o valor exato pra logar antes de agir.

Write-InfoMessage "Consultando cdnjs pela última versão estável do Bootstrap..."

$latestVersion = $null
try {
  $cdnjsResponse = Invoke-RestMethod -Uri 'https://api.cdnjs.com/libraries/bootstrap?fields=version' -ErrorAction Stop
  $latestVersion = $cdnjsResponse.version
}
catch {
  Write-ErrMessage "Não foi possível resolver a versão mais recente do Bootstrap via cdnjs."
  exit 1
}

if ([string]::IsNullOrWhiteSpace($latestVersion) -or $latestVersion -eq 'null') {
  Write-ErrMessage "Não foi possível resolver a versão mais recente do Bootstrap via cdnjs."
  exit 1
}

Write-InfoMessage "Última versão estável disponível: $latestVersion"

# --- 5. Instalar ou atualizar, evitando arquivos órfãos ----------------------

$destination = Join-Path 'wwwroot' (Join-Path 'lib' 'bootstrap')

$currentVersion = $null
if (Test-Path -Path 'libman.json') {
  $libmanContent = Get-Content -Path 'libman.json' -Raw -ErrorAction SilentlyContinue
  if ($libmanContent -match '"library":\s*"bootstrap@([^"]*)"') {
    $currentVersion = $Matches[1]
  }
}

if ($currentVersion -and $currentVersion -eq $latestVersion) {
  Write-InfoMessage "Bootstrap já está na versão mais recente ($latestVersion) em $destination. Nada a fazer."
}
elseif ($currentVersion) {
  Write-InfoMessage "Versão instalada ($currentVersion) difere da mais recente ($latestVersion)."
  Write-InfoMessage "Removendo entrada e arquivos antigos antes de reinstalar (evita arquivos órfãos de versão anterior)..."
  libman uninstall bootstrap
  libman install "bootstrap@${latestVersion}" -d $destination
}
else {
  Write-InfoMessage "Instalando Bootstrap ${latestVersion} em ${destination}..."
  libman install "bootstrap@${latestVersion}" -d $destination
}

Write-InfoMessage "Concluído. Entrada final no libman.json:"
$bootstrapEntry = Select-String -Path 'libman.json' -Pattern '"bootstrap@' -Context 0, 3 -ErrorAction SilentlyContinue
if ($bootstrapEntry) {
  Write-Host $bootstrapEntry.Line
  $bootstrapEntry.Context.PostContext | ForEach-Object { Write-Host $_ }
}