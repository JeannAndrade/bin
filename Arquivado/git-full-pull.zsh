#!/usr/bin/env zsh

# ---------------------------------
# Nome: git-full-pull.zsh
# Versão: 1.0
# Autor: Jeann Andrade
# Descrição: Executa atualização completa do repositório via git fetch e git pull
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
# VALIDAÇÕES
# ==============================

section_title "Git Full Pull"

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

# Obter informações do repositório para exibição
current_branch=$(git branch --show-current 2>/dev/null || echo "Desconhecida")
remote_name=$(git config --get branch."${current_branch}".remote || echo "origin")

print_field "Branch Atual" "$current_branch"
print_field "Remoto"       "$remote_name"
echo

# ==============================
# EXECUÇÃO DOS COMANDOS
# ==============================

info "Buscando atualizações do repositório remoto (git fetch --all --prune)..."
if git fetch --all --prune; then
  success "Fetch concluído com sucesso!"
else
  err "Falha ao executar o git fetch."
  exit 1
fi

echo

info "Aplicando atualizações na branch atual (git pull)..."
if git pull; then
  echo
  success "Repositório atualizado com sucesso!"
else
  echo
  err "Falha ao executar o git pull."
  exit 1
fi

echo