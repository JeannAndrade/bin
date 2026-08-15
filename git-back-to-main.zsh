#!/usr/bin/env zsh

# ---------------------------------
# Nome: git-back-to-main.zsh
# Versão: 1.0
# Autor: Jeann Andrade
# Descrição: Retorna para a branch principal (main/master), busca e aplica atualizações
# ---------------------------------

# Sai imediatamente se algum comando falhar e trata variáveis não definidas como erro
set -euo pipefail
clear

lib="$(dirname "$0")/shared-style.zsh"
if [[ ! -f "$lib" ]]; then
  echo "Erro: arquivo de biblioteca '$lib' não encontrado." >&2
  exit 1
fi
source "$lib"

# ==============================
# VALIDAÇÕES E DETECÇÃO
# ==============================

section_title "Git Retorno à Branch Principal"

# Verifica se o git está instalado
if ! command -v git &>/dev/null; then
  err "O Git não está instalado na máquina."
  exit 1
fi

# Verifica se o diretório atual é um repositório Git
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  err "O diretório atual não é um repositório Git."
  exit 1
fi

# Detecta a branch principal padrao (main ou master)
default_branch=""

# 1. Tenta identificar via ref simbólica do remote 'origin'
if git symbolic-ref refs/remotes/origin/HEAD &>/dev/null; then
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
fi

# 2. Se não encontrou, verifica se 'main' existe localmente ou no remote
if [[ -z "$default_branch" ]]; then
  if git show-ref --verify --quiet "refs/heads/main" || git show-ref --verify --quiet "refs/remotes/origin/main"; then
    default_branch="main"
  elif git show-ref --verify --quiet "refs/heads/master" || git show-ref --verify --quiet "refs/remotes/origin/master"; then
    default_branch="master"
  fi
fi

# 3. Caso não consiga detectar automaticamente
if [[ -z "$default_branch" ]]; then
  err "Não foi possível detectar se a branch principal é 'main' ou 'master'."
  exit 1
fi

current_branch=$(git branch --show-current 2>/dev/null || echo "Desconhecida")

print_field "Branch Atual"      "$current_branch"
print_field "Branch Principal"  "$default_branch"
echo

# ==============================
# EXECUÇÃO DOS COMANDOS
# ==============================

# Executa checkout se já não estiver na branch principal
if [[ "$current_branch" != "$default_branch" ]]; then
  info "Alternando para a branch '$default_branch' (git checkout $default_branch)..."
  if git checkout "$default_branch"; then
    success "Troca para '$default_branch' realizada com sucesso."
  else
    err "Falha ao trocar para a branch '$default_branch'."
    exit 1
  fi
  echo
else
  info "Você já está na branch '$default_branch'."
  echo
fi

info "Buscando atualizações do repositório remoto (git fetch --all --prune)..."
if git fetch --all --prune; then
  success "Fetch concluído com sucesso!"
else
  err "Falha ao executar o git fetch."
  exit 1
fi

echo

info "Atualizando a branch '$default_branch' (git pull)..."
if git pull; then
  echo
  success "Branch '$default_branch' atualizada com sucesso!"
else
  echo
  err "Falha ao executar o git pull."
  exit 1
fi

echo