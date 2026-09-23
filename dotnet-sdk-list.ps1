#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Lista os SDKs .NET instalados na máquina.

.DESCRIPTION
    Equivalente PowerShell de dotnet-sdks.zsh.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.0 (convertido de dotnet-sdks.zsh)

.EXAMPLE
    ./dotnet-sdks-get.ps1
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

dotnet --list-sdks