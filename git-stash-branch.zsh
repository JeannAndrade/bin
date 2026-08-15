#!/usr/bin/env zsh

# ---------------------------------
# Nome: git-stash-branch.zsh
# Versão: 1.0
# Autor: Jeann Andrade
# Descrição: Salva as alterações não comitadas no stash e cria uma nova branch com elas
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

section_title "Git Stash & Nova Branch"

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

# Verifica se o parâmetro com o nome da branch foi fornecido
if [[ $# -eq 0 || -z "${1:-}" ]]; then
  err "Você precisa fornecer o nome da nova branch."
  echo
  info "Uso: $0 <nome_da_branch>"
  echo
  exit 1
fi

new_branch="$1"
current_branch=$(git branch --show-current 2>/dev/null || echo "Desconhecida")

# Verifica se existem alterações para guardar no stash
if [[ -z "$(git status --porcelain)" ]]; then
  warn "Não há alterações pendentes no diretório atual para mover para a nova branch."
  exit 0
fi

# Verifica se a branch já existe localmente
if git show-ref --verify --quiet "refs/heads/$new_branch"; then
  err "A branch '$new_branch' já existe localmente."
  exit 1
fi

print_field "Branch Atual" "$current_branch"
print_field "Nova Branch"  "$new_branch"
echo

# ==============================
# EXECUÇÃO DOS COMANDOS
# ==============================

info "Guardando alterações locais no stash (git stash)..."
git stash push -m "Stash temporario gerado por git-stash-branch"
success "Alterações guardadas temporariamente."

echo

info "Criando branch '$new_branch' e aplicando as alterações (git stash branch)..."
if git stash branch "$new_branch"; then
  echo
  success "Branch '$new_branch' criada e alterações aplicadas com sucesso!"
else
  echo
  err "Falha ao criar a branch a partir do stash."
  exit 1
fi

echo