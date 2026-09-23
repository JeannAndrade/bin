#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Cria o arquivo global.json na pasta atual, fixando o SDK .NET em uso.

.DESCRIPTION
    Equivalente PowerShell de dotnet-add-global.zsh.

    Valida que exista exatamente um arquivo .slnx na pasta atual e que
    ainda não exista um global.json, então cria o global.json com a
    versão do SDK .NET atualmente instalada.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.0 (convertido de dotnet-add-global.zsh)

    O "setopt local_options nullglob" do zsh (usado para que *.slnx vire
    um array vazio, em vez de um erro, quando não há nenhum arquivo .slnx)
    não tem equivalente necessário aqui: Get-ChildItem com -Filter já
    retorna uma coleção vazia nesse caso, sem precisar de nenhuma opção
    especial.

.EXAMPLE
    ./dotnet-global-add.ps1
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

# =========================
# Validação: global.json ainda não existe
# =========================

if (Test-Path -Path (Join-Path $projectPath 'global.json')) {
  Write-ErrMessage "Arquivo global.json já existe na pasta atual."
  exit 1
}

# =========================
# Descobre SDK mais recente
# =========================

$sdkVersion = dotnet --version

Write-InfoMessage "Solution: $solutionFile"
Write-InfoMessage "SDK: $sdkVersion"

# =========================
# Criação do artefato
# =========================

dotnet new globaljson `
  --sdk-version $sdkVersion `
  --output $projectPath `
  --roll-forward latestMajor

Write-Host ''
Write-SuccessMessage "Arquivo global.json criado com sucesso."