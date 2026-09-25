#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Adiciona (ou atualiza) um pacote NuGet em um projeto .NET.

.DESCRIPTION
    Equivalente PowerShell de dotnet-package-add.zsh (antigo
    dotnet-add-package.zsh).

    Adiciona (ou atualiza) um pacote NuGet em um projeto .NET, com
    checagem prévia de instalação (avisa se o pacote já estiver
    referenciado) e confirmação interativa antes de executar o comando.

.PARAMETER ProjectName
    Nome do projeto que receberá o pacote (com ou sem a extensão
    .csproj).

.PARAMETER PackageName
    Nome do pacote NuGet a ser adicionado.

.PARAMETER Version
    Opcional. Versão específica do pacote.

.NOTES
    Autor:  Jeann Andrade
    Criado: 2026-07-11
    Versão: 1.0 (convertido de dotnet-package-add.zsh)

    Depende de Find-CsprojByName em DotnetCommon.psm1.

    O destaque em negrito (${BOLD}...${NC}) usado em algumas mensagens do
    zsh não foi replicado — assim como nas demais conversões desta
    coleção, as mensagens de Write-InfoMessage/Write-Field seguem em
    texto simples.

.EXAMPLE
    ./dotnet-package-add.ps1 MyApp Newtonsoft.Json

.EXAMPLE
    ./dotnet-package-add.ps1 MyApp Serilog 3.1.1

.EXAMPLE
    ./dotnet-package-add.ps1 src/MyApp/MyApp.csproj Serilog.AspNetCore 8.0.0
#>

param(
  [Parameter(Position = 0)]
  [string]$ProjectName,

  [Parameter(Position = 1)]
  [string]$PackageName,

  [Parameter(Position = 2)]
  [string]$Version
)

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
# Validação: dotnet disponível
# ---------------------------------------------------------------------------
Write-SectionTitle "Adicionando Pacote NuGet ao Projeto .NET"
Assert-DotnetCli

# ---------------------------------------------------------------------------
# Validação dos parâmetros
# ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($ProjectName) -or [string]::IsNullOrWhiteSpace($PackageName)) {
  Write-ErrMessage "Uso: $($MyInvocation.MyCommand.Name) <nome_projeto> <nome_package> [versao]"
  Write-Host ''
  Write-Host '  <nome_projeto>   - Nome do projeto que receberá o pacote'
  Write-Host '  <nome_package>   - Nome do pacote NuGet a ser adicionado'
  Write-Host '  [versao]         - (Opcional) Versão específica do pacote'
  Write-Host ''
  Write-Host 'Exemplos:'
  Write-Host "  $($MyInvocation.MyCommand.Name) MyApp Newtonsoft.Json"
  Write-Host "  $($MyInvocation.MyCommand.Name) MyApp Serilog 3.1.1"
  Write-Host "  $($MyInvocation.MyCommand.Name) src/MyApp/MyApp.csproj Serilog.AspNetCore 8.0.0"
  exit 1
}

Write-InfoMessage "Projeto destino: $ProjectName"
Write-InfoMessage "Pacote: $PackageName"
if (-not [string]::IsNullOrWhiteSpace($Version)) {
  Write-InfoMessage "Versão: $Version"
}
else {
  Write-InfoMessage "Versão: (última estável)"
}

# ---------------------------------------------------------------------------
# Localização do projeto usando Find-CsprojByName
# ---------------------------------------------------------------------------
Write-Host ''
Write-InfoMessage "Localizando projeto..."

# Remove extensão .csproj se existir para usar como nome
$projectNameNoExt = $ProjectName -replace '\.csproj$', ''

# Encontra o projeto (Find-CsprojByName já encerra o script com erro se não achar)
$projectPath = Find-CsprojByName -Name $projectNameNoExt

Write-Host ''
Write-Field "Projeto encontrado" $projectPath

# ---------------------------------------------------------------------------
# Verifica se o pacote já está instalado
# ---------------------------------------------------------------------------
Write-Host ''
Write-InfoMessage "Verificando se o pacote '$PackageName' já está instalado..."

# Busca por PackageReference no .csproj. [regex]::Escape evita que
# caracteres do nome do pacote (como o ".") sejam interpretados como
# metacaracteres de regex.
$escapedPackageName = [regex]::Escape($PackageName)
$csprojContent = Get-Content -Path $projectPath -Raw -ErrorAction SilentlyContinue

$alreadyInstalled = $csprojContent -match "<PackageReference Include=`"$escapedPackageName`""

if ($alreadyInstalled) {
  $currentVersion = $null
  if ($csprojContent -match "<PackageReference Include=`"$escapedPackageName`" Version=`"([^`"]*)`"") {
    $currentVersion = $Matches[1]
  }

  if ($currentVersion) {
    Write-WarnMessage "O pacote '$PackageName' já está instalado no projeto com a versão $currentVersion."
  }
  else {
    Write-WarnMessage "O pacote '$PackageName' já está instalado no projeto."
  }

  Write-Host ''
  $confirmExisting = Read-Host "Deseja adicionar/atualizar mesmo assim? (s/N)"
  if ($confirmExisting -notmatch '^[Ss]$') {
    Write-InfoMessage "Operação cancelada."
    exit 0
  }
}
else {
  Write-SuccessMessage "Pacote não encontrado no projeto."
}

# ---------------------------------------------------------------------------
# Montagem do comando
# ---------------------------------------------------------------------------
Write-Host ''

# Monta os argumentos do comando (array, em vez da string + eval do zsh —
# evita problemas de escaping e injeção de shell).
$cmdArgs = @('add', $projectPath, 'package', $PackageName)
if (-not [string]::IsNullOrWhiteSpace($Version)) {
  $cmdArgs += @('--version', $Version)
}

$cmdDisplay = "dotnet add `"$projectPath`" package `"$PackageName`""
if (-not [string]::IsNullOrWhiteSpace($Version)) {
  $cmdDisplay += " --version $Version"
}

Write-InfoMessage "Comando a ser executado:"
Write-Host "  $cmdDisplay"
Write-Host ''

# Confirmação antes de executar
$confirmRun = Read-Host "Confirmar execução? (S/n)"
if ($confirmRun -match '^[Nn]$') {
  Write-InfoMessage "Operação cancelada."
  exit 0
}

# ---------------------------------------------------------------------------
# Execução do comando
# ---------------------------------------------------------------------------
Write-Host ''
Write-InfoMessage "Executando comando..."

dotnet @cmdArgs

if ($LASTEXITCODE -eq 0) {
  Write-Host ''
  Write-SuccessMessage "✅ Pacote adicionado com sucesso!"
  Write-Host ''
  Write-Field "Projeto" (Split-Path -Path $projectPath -Leaf)
  Write-Field "Pacote" $PackageName
  if (-not [string]::IsNullOrWhiteSpace($Version)) {
    Write-Field "Versão" $Version
  }
  else {
    Write-Field "Versão" "Última estável"
  }
}
else {
  Write-ErrMessage "Falha ao adicionar o pacote '$PackageName'."
  exit 1
}