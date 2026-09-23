#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Abre workspaces do VS Code via menu numerado ou por parâmetro.

.DESCRIPTION
    Equivalente PowerShell de vscode-open-workspace.zsh.

    Apresenta uma lista de workspaces pré-definidos e permite selecionar
    um número correspondente para abrir no VS Code.

    Diferente da versão zsh, aqui a ordem de exibição e o mapeamento
    id -> caminho vivem numa única estrutura ([ordered] hashtable), em
    vez de um array IDS separado só para controlar a ordem. Isso existia
    no zsh porque arrays associativos (typeset -A) não preservam ordem de
    inserção; [ordered] no PowerShell já resolve isso nativamente.

.PARAMETER Selection
    Número do workspace a abrir diretamente, pulando o menu interativo.

.NOTES
    Autor:  Jeann Andrade
    Versão: 2.3 (convertido de vscode-open-workspace.zsh / abrir-workspace-vscode.zsh)

.EXAMPLE
    ./vscode-workspace-open.ps1
    ./vscode-workspace-open.ps1 3
#>

param(
    [Parameter(Position = 0)]
    [string]$Selection
)

$ErrorActionPreference = 'Stop'

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

# Verifica se o comando 'code' existe
Assert-CommandAvailable -Command 'code' -Message "o comando 'code' não está disponível no PATH."

# ==============================
# WORKSPACES (ordem de exibição + mapeamento em uma única estrutura)
# ==============================
# Join-Path monta o separador correto para o SO em uso — no zsh original os
# caminhos eram fixados com "/", o que só funciona em Linux/macOS.
$workspaces = [ordered]@{
    CodeMaze           = Join-Path $HOME 'repo/github/CodeMaze/CodeMaze.code-workspace'
    DockerExamples     = Join-Path $HOME 'repo/gitlab/dockerexamples/dockerexamples.code-workspace'
    JeannandradeGithub = Join-Path $HOME 'repo/github/jeannandrade.github.io/jeannandrade.github.io.code-workspace'
    LearningBlazor     = Join-Path $HOME 'repo/github/Learning-Blazor/Learning-Blazor.code-workspace'
    LearningCSharp     = Join-Path $HOME 'repo/github/Learning-CSharp/Learning-CSharp.code-workspace'
    LumiaFoundation    = Join-Path $HOME 'repo/github/Lumia.Foundation/Lumia.Foundation.code-workspace'
    myscripts          = Join-Path $HOME 'bin/myscripts.code-workspace'
    MelhorPrecoCerveja = Join-Path $HOME 'repo/github/MelhorPrecoCerveja/MelhorPrecoCerveja.code-workspace'
    Vault              = Join-Path $HOME 'repo/github/Vault/Vault.code-workspace'
    zshrc              = Join-Path $HOME '.zshrc'
}

# Extrai as chaves em array para permitir indexação numérica (menu 1-based)
$ids = @($workspaces.Keys)

# ==============================
# OBTÉM A OPÇÃO: PARÂMETRO OU MENU INTERATIVO
# ==============================
if ($Selection) {
    # Parâmetro informado — pula o menu e usa o valor direto
    $opcao = $Selection
}
else {
    # Nenhum parâmetro — comportamento original (menu numerado)
    Clear-Host
    Write-InfoMessage "Workspaces disponíveis:"
    Write-InfoMessage "--------------------------"

    for ($i = 0; $i -lt $ids.Count; $i++) {
        Write-Host (" {0}) {1}" -f ($i + 1), $ids[$i])
    }

    Write-Host ''
    $opcao = Read-Host "Digite o número do workspace que deseja abrir"
}

# ==============================
# VALIDAÇÃO
# ==============================
if ($opcao -notmatch '^\d+$') {
    Write-ErrMessage "Digite apenas números."
    exit 1
}

$opcaoInt = [int]$opcao
if ($opcaoInt -lt 1 -or $opcaoInt -gt $ids.Count) {
    Write-ErrMessage "Opção inválida."
    exit 1
}

$selecionadoId = $ids[$opcaoInt - 1]
$workspacePath = $workspaces[$selecionadoId]

if (-not (Test-Path $workspacePath)) {
    Write-ErrMessage "O path '$workspacePath' não existe."
    exit 1
}

# ==============================
# ABRIR VS CODE
# ==============================
Write-InfoMessage "Abrindo workspace '$selecionadoId'..."
code $workspacePath