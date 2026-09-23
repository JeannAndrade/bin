#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Cria uma nova solução .NET com um projeto Blazor, já versionada no Git.

.DESCRIPTION
    Equivalente PowerShell de dotnet-blazor-app-new.zsh.

    Solicita interativamente o nome da solução e do projeto, cria a
    solução (.slnx) e um projeto Blazor com framework .NET detectado a
    partir do SDK instalado, interatividade Auto e sem autenticação,
    ajusta o arquivo de solução, inicializa um repositório Git, adiciona
    um .gitignore e faz o commit inicial.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.0 (convertido de dotnet-blazor-app-new.zsh)

    Assim como a versão zsh, este script é totalmente interativo (não
    aceita os nomes via parâmetro de linha de comando) — fiel ao
    comportamento original.

    Depende de Get-FrameworkFromSdk em DotnetCommon.psm1 (equivalente a
    framework_from_sdk() do dotnet-common.zsh).

.EXAMPLE
    ./dotnet-blazor-app-new.ps1
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
# Validação: dotnet disponível
# ---------------------------------------------------------------------------
Assert-DotnetCli

Write-InfoMessage "=== Criador de Projeto Blazor (.NET) ==="

# Solicita o nome da solução
$solutionName = Read-Host "Informe o nome da solução"

if ([string]::IsNullOrWhiteSpace($solutionName)) {
  Write-ErrMessage "O nome da solução é obrigatório."
  exit 1
}

# Solicita o nome do projeto
$projectName = Read-Host "Informe o nome do projeto"

if ([string]::IsNullOrWhiteSpace($projectName)) {
  Write-ErrMessage "O nome do projeto é obrigatório."
  exit 1
}

# Descobre a versão do SDK em uso
$sdkVersion = dotnet --version
$framework = Get-FrameworkFromSdk -SdkVersion $sdkVersion -Mode major_zero

Write-InfoMessage "SDK encontrado: $sdkVersion"
Write-InfoMessage "Framework: $framework"
Write-Host ''

Write-Host ''
Write-InfoMessage "Criando solução '$solutionName' com projeto '$projectName'..."

# Cria o global.json com a versão do SDK
dotnet new globaljson `
  --sdk-version $sdkVersion `
  --output $solutionName `
  --roll-forward latestMajor

# Cria a solução
dotnet new sln -o $solutionName

# Cria o projeto Blazor
dotnet new blazor `
  --name $projectName `
  --output $solutionName `
  --framework $framework `
  --interactivity Auto `
  --auth None `
  --all-interactive false

Write-InfoMessage "Ajustando arquivo de solução para novo formato slnx"

# Remove o arquivo de solução criado automaticamente dentro do projeto
$autoSlnPath = Join-Path $solutionName "$projectName.sln"
Remove-Item -Path $autoSlnPath -Force -ErrorAction SilentlyContinue

# Adiciona o projeto à solução
$csprojPath = Join-Path $solutionName (Join-Path $projectName "$projectName.csproj")
dotnet sln $solutionName add $csprojPath

Write-Host ''
Write-InfoMessage "Inicializando repositório Git..."

Set-Location -Path $solutionName

git init -b main
dotnet new gitignore

git add .
git commit -m "Initial commit"

Write-Host ''
Write-SuccessMessage "Projeto Blazor criado e versionado com Git!"