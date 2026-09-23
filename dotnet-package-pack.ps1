#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Empacota um projeto .NET em um pacote NuGet (.nupkg).

.DESCRIPTION
    Equivalente PowerShell de dotnet-pack-package.zsh.

    Empacota um projeto .NET em um pacote NuGet (.nupkg), incluindo os
    símbolos de depuração (--include-symbols). A pasta de saída "nupkgs"
    é limpa antes de cada execução para evitar pacotes obsoletos.

.PARAMETER ProjectName
    Nome do projeto a ser empacotado (com ou sem a extensão .csproj).

.NOTES
    Autor:  Jeann Andrade
    Criado: 2026-07-11
    Versão: 1.0 (convertido de dotnet-pack-package.zsh)

    Depende da nova função Find-CsprojByName em DotnetCommon.psm1
    (equivalente a find_csproj_by_name() do dotnet-common.zsh).

.EXAMPLE
    ./dotnet-package-pack.ps1 MinhaLib
#>

param(
  [Parameter(Position = 0)]
  [string]$ProjectName
)

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

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
  Write-ErrMessage "Informe o nome do projeto."
  exit 1
}

$csprojFile = Find-CsprojByName -Name $ProjectName

Write-SuccessMessage "Projeto encontrado: $csprojFile"

# ---------------------------------------------------------------------------
# Limpa a pasta de saída antes de empacotar
# ---------------------------------------------------------------------------
if (Test-Path 'nupkgs') {
  Write-InfoMessage "Limpando pasta nupkgs..."
  Remove-Item -Path 'nupkgs' -Recurse -Force
}
New-Item -Path 'nupkgs' -ItemType Directory -Force | Out-Null

# ---------------------------------------------------------------------------
# Executa o dotnet pack
# ---------------------------------------------------------------------------
Write-InfoMessage "Executando: dotnet pack `"$csprojFile`" --include-symbols --output nupkgs"
Write-Host ''

dotnet pack $csprojFile --include-symbols --output nupkgs
$exitCode = $LASTEXITCODE

Write-Host ''
if ($exitCode -eq 0) {
  Write-SuccessMessage "Pack concluído com sucesso. Pacotes em: ./nupkgs"
}
else {
  Write-ErrMessage "Falha no dotnet pack. Código de saída: $exitCode"
}

exit $exitCode