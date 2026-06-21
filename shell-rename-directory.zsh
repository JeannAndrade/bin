#!/usr/bin/env zsh

# ---------------------------------
# Nome: rename-directory.zsh
# Versão: 1.0
# Autor: Jeann Andrade
# Descrição: Renomeia um diretório a partir de dois parâmetros:
#             nome_repositorio_antigo e nome_repositorio_novo
# ---------------------------------

set -euo pipefail
clear

# ==============================
# BIBLIOTECAS
# ==============================

lib_style="$(dirname "$0")/shared-style.zsh"
if [[ ! -f "$lib_style" ]]; then
  echo "Erro: arquivo de biblioteca '$lib_style' não encontrado." >&2
  exit 1
fi
source "$lib_style"

lib_common="$(dirname "$0")/dotnet-common.zsh"
if [[ ! -f "$lib_common" ]]; then
  echo "Erro: arquivo de biblioteca '$lib_common' não encontrado." >&2
  exit 1
fi
source "$lib_common"

# ==============================
# PARÂMETROS
# ==============================

section_title "Renomear Diretório"

if [[ $# -ne 2 ]]; then
  err "Uso: $(basename "$0") <nome_repositorio_antigo> <nome_repositorio_novo>"
  exit 1
fi

OLD_NAME="$1"
NEW_NAME="$2"

require_non_empty "$OLD_NAME" "O parâmetro 'nome_repositorio_antigo' não pode ser vazio."
require_non_empty "$NEW_NAME" "O parâmetro 'nome_repositorio_novo' não pode ser vazio."

# ==============================
# VALIDAÇÕES
# ==============================

section_title "Validações"

require_dir "$OLD_NAME" "O diretório '$OLD_NAME' não existe."
info "Diretório de origem encontrado: $OLD_NAME"

if [[ -e "$NEW_NAME" ]]; then
  err "Já existe um arquivo ou diretório com o nome '$NEW_NAME'."
  exit 1
fi

# ==============================
# EXECUÇÃO
# ==============================

section_title "Executando"

print_field "De" "$OLD_NAME"
print_field "Para" "$NEW_NAME"

mv "$OLD_NAME" "$NEW_NAME"

echo
success "Diretório renomeado com sucesso: '$OLD_NAME' → '$NEW_NAME'"
echo