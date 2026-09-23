#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Atualiza o global.json existente com a versão do SDK .NET atual.

.DESCRIPTION
    Equivalente PowerShell de dotnet-global-update.zsh.

    Valida que exista exatamente um arquivo .slnx e um global.json na
    pasta atual, remove o global.json antigo e recria com a versão do
    SDK .NET atualmente instalada.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.0 (convertido de dotnet-global-update.zsh, antigo
             dotnet-update-global.zsh)

.EXAMPLE
    ./dotnet-global-update.ps1
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

# =========================
# Validação: solution .slnx na pasta atual
# =========================

$slnxFiles = @(Get-ChildItem -Path . -File -Filter '*.slnx' -ErrorAction SilentlyContinue)

if ($slnxFiles.Count -eq 0) {
  Write-ErrMessage "Nenhum arquivo .slnx encontrado na pasta atual."
  Write-InfoMessage "Execute este script a partir da raiz de uma solution válida."
  exit 1
}

if ($slnxFiles.Count -gt 1) {
  Write-ErrMessage "Mais de um arquivo .slnx encontrado na pasta atual."
  Write-InfoMessage "Certifique-se de que existe apenas uma solution na pasta."
  exit 1
}

$solutionFile = $slnxFiles[0].Name
$projectPath = '.'
$globalJson = Join-Path $projectPath 'global.json'

# =========================
# Validação: global.json precisa existir
# =========================

if (-not (Test-Path -Path $globalJson)) {
  Write-ErrMessage "Nenhum arquivo global.json encontrado na pasta atual."
  Write-InfoMessage "Use o script dotnet-add-global.ps1 para criá-lo primeiro."
  exit 1
}

# =========================
# Descobre SDK mais recente
# =========================

$sdkVersion = dotnet --version

Write-InfoMessage "Solution: $solutionFile"
Write-InfoMessage "SDK: $sdkVersion"

# =========================
# Remove o global.json antigo para evitar duplicidade
# =========================

Remove-Item -Path $globalJson -Force -ErrorAction SilentlyContinue

# =========================
# Recria o artefato com a versão mais recente
# =========================

dotnet new globaljson `
  --sdk-version $sdkVersion `
  --output $projectPath `
  --roll-forward latestMajor

Write-Host ''
Write-SuccessMessage "Arquivo global.json atualizado com sucesso."