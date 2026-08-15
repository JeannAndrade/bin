#!/usr/bin/env zsh

# ---------------------------------
# Nome: git-commit-push.zsh
# Versão: 1.0
# Autor: Jeann Andrade
# Descrição: Automatiza os comandos de git add, git commit e git push
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

section_title "Git Workflow"

# Verifica se o git está instalado
if ! command -v git &>/dev/null; then
  err "O Git não está instalado na máquina."
  exit 1
fi

# Verifica se o parâmetro com a mensagem de commit foi fornecido
if [[ $# -eq 0 || -z "${1:-}" ]]; then
  err "Você precisa fornecer uma mensagem de commit."
  echo
  info "Uso: $0 \"Sua mensagem de commit aqui\""
  echo
  exit 1
fi

commit_message="$1"

# Verifica se o diretório atual é um repositório Git
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  err "O diretório atual não é um repositório Git."
  exit 1
fi

# ==============================
# EXECUÇÃO DOS COMANDOS
# ==============================

print_field "Mensagem de commit" "$commit_message"
echo

info "Adicionando arquivos modificados (git add .)..."
git add .
success "Arquivos adicionados com sucesso."

echo

info "Criando commit (git commit -a -m)..."
git commit -a -m "$commit_message"
success "Commit realizado com sucesso."

echo

info "Enviando alterações (git push)..."
if git push; then
  echo
  success "Alterações enviadas para o repositório remoto com sucesso!"
else
  echo
  err "Falha ao realizar o git push."
  exit 1
fi

echo