#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Executa atualização completa do repositório via git fetch e git pull.

.DESCRIPTION
    Equivalente PowerShell de git-full-pull.zsh.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.0 (convertido de git-full-pull.zsh)

.EXAMPLE
    ./git-pull-full.ps1
#>

$ErrorActionPreference = 'Stop'
Clear-Host

# ---------------------------------------------------------------------------
# Carrega módulo compartilhado
# ---------------------------------------------------------------------------
$scriptDir = $PSScriptRoot

$styleModule = Join-Path $scriptDir 'SharedStyle.psm1'
if (-not (Test-Path $styleModule)) {
    Write-Host "Erro: arquivo de biblioteca '$styleModule' não encontrado." -ForegroundColor Red
    exit 1
}
Import-Module $styleModule -Force

# ==============================
# VALIDAÇÕES
# ==============================

Write-SectionTitle "Git Full Pull"

# Verifica se o git está instalado
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ErrMessage "O Git não está instalado na máquina."
    exit 1
}

# Verifica se o diretório atual é um repositório Git
git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) {
    Write-ErrMessage "O diretório atual não é um repositório Git."
    exit 1
}

# Obtém informações do repositório para exibição
$currentBranch = git branch --show-current 2>$null
if ([string]::IsNullOrWhiteSpace($currentBranch)) { $currentBranch = "Desconhecida" }

$remoteName = git config --get "branch.$currentBranch.remote" 2>$null
if ([string]::IsNullOrWhiteSpace($remoteName)) { $remoteName = "origin" }

Write-Field "Branch Atual" $currentBranch
Write-Field "Remoto" $remoteName
Write-Host ''

# ==============================
# EXECUÇÃO DOS COMANDOS
# ==============================

Write-InfoMessage "Buscando atualizações do repositório remoto (git fetch --all --prune)..."
git fetch --all --prune
if ($LASTEXITCODE -eq 0) {
    Write-SuccessMessage "Fetch concluído com sucesso!"
}
else {
    Write-ErrMessage "Falha ao executar o git fetch."
    exit 1
}

Write-Host ''

Write-InfoMessage "Aplicando atualizações na branch atual (git pull)..."
git pull
if ($LASTEXITCODE -eq 0) {
    Write-Host ''
    Write-SuccessMessage "Repositório atualizado com sucesso!"
}
else {
    Write-Host ''
    Write-ErrMessage "Falha ao executar o git pull."
    exit 1
}

Write-Host ''