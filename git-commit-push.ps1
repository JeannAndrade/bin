#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Automatiza os comandos de git add, git commit e git push.

.DESCRIPTION
    Equivalente PowerShell de git-commit-push.zsh.

.PARAMETER CommitMessage
    Mensagem do commit.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.0 (convertido de git-commit-push.zsh)

.EXAMPLE
    ./git-commit-push.ps1 "Minha mensagem de commit"
#>

param(
    [Parameter(Position = 0)]
    [string]$CommitMessage
)

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

Write-SectionTitle "Git Workflow"

# Verifica se o git está instalado
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ErrMessage "O Git não está instalado na máquina."
    exit 1
}

# Verifica se o parâmetro com a mensagem de commit foi fornecido
if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
    Write-ErrMessage "Você precisa fornecer uma mensagem de commit."
    Write-Host ''
    Write-InfoMessage "Uso: $($MyInvocation.MyCommand.Name) `"Sua mensagem de commit aqui`""
    Write-Host ''
    exit 1
}

# Verifica se o diretório atual é um repositório Git
git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) {
    Write-ErrMessage "O diretório atual não é um repositório Git."
    exit 1
}

# ==============================
# EXECUÇÃO DOS COMANDOS
# ==============================

Write-Field "Mensagem de commit" $CommitMessage
Write-Host ''

Write-InfoMessage "Adicionando arquivos modificados (git add .)..."
git add .
if ($LASTEXITCODE -ne 0) {
    Write-ErrMessage "Falha ao adicionar os arquivos."
    exit 1
}
Write-SuccessMessage "Arquivos adicionados com sucesso."

Write-Host ''

Write-InfoMessage "Criando commit (git commit -a -m)..."
git commit -a -m $CommitMessage
if ($LASTEXITCODE -ne 0) {
    Write-ErrMessage "Falha ao criar o commit."
    exit 1
}
Write-SuccessMessage "Commit realizado com sucesso."

Write-Host ''

Write-InfoMessage "Enviando alterações (git push)..."
git push
if ($LASTEXITCODE -eq 0) {
    Write-Host ''
    Write-SuccessMessage "Alterações enviadas para o repositório remoto com sucesso!"
}
else {
    Write-Host ''
    Write-ErrMessage "Falha ao realizar o git push."
    exit 1
}

Write-Host ''