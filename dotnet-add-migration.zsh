#!/usr/bin/env zsh

# ---------------------------------
# Nome: dotnet-add-migration.zsh
# Versão: 1.0
# Autor: Jeann Andrade
# Descrição: Adiciona uma nova migration usando o Entity Framework Core
#            Tools (dotnet-ef).
# Uso:       dotnet-add-migration.zsh <nome-da-migration> [--project <path>] [--startup-project <path>]
#            --project           Projeto onde a migration será criada (onde fica o DbContext).
#            --startup-project   Projeto de inicialização, usado para resolver a connection string.
#            Permite rodar o script de qualquer diretório, sem precisar
#            estar dentro da pasta do projeto.
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

common_lib="$(dirname "$0")/dotnet-common.zsh"
if [[ ! -f "$common_lib" ]]; then
  echo "Erro: arquivo de biblioteca '$common_lib' não encontrado." >&2
  exit 1
fi
source "$common_lib"

# ---------------------------------------------------------------------------
# Validações iniciais
# ---------------------------------------------------------------------------

check_dotnet
require_command dotnet-ef "o comando 'dotnet-ef' não está disponível. Instale com: dotnet tool install --global dotnet-ef"

usage() {
  err "Uso: $(basename "$0") <nome-da-migration> [--project <path>] [--startup-project <path>]"
}

if [[ $# -lt 1 || -z "${1// }" ]]; then
  err "Nome da migration não informado."
  usage
  exit 1
fi

MIGRATION_NAME="$1"
shift

PROJECT_PATH=""
STARTUP_PROJECT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      if [[ $# -lt 2 || -z "${2// }" ]]; then
        err "A opção --project exige um valor."
        usage
        exit 1
      fi
      PROJECT_PATH="$2"
      shift 2
      ;;
    --startup-project)
      if [[ $# -lt 2 || -z "${2// }" ]]; then
        err "A opção --startup-project exige um valor."
        usage
        exit 1
      fi
      STARTUP_PROJECT_PATH="$2"
      shift 2
      ;;
    *)
      err "Opção desconhecida: $1"
      usage
      exit 1
      ;;
  esac
done

# ==============================
# ETAPA 1 — ADICIONAR MIGRATION
# ==============================

EF_ARGS=(migrations add "$MIGRATION_NAME")

if [[ -n "$PROJECT_PATH" ]]; then
  EF_ARGS+=(--project "$PROJECT_PATH")
fi

if [[ -n "$STARTUP_PROJECT_PATH" ]]; then
  EF_ARGS+=(--startup-project "$STARTUP_PROJECT_PATH")
fi

section_title "Etapa 1 — Adicionando migration '${MIGRATION_NAME}'"
info "Executando: dotnet ef ${EF_ARGS[*]}"

if ! dotnet ef "${EF_ARGS[@]}"; then
  err "Falha ao adicionar a migration '${MIGRATION_NAME}'."
  exit 1
fi

success "Migration '${MIGRATION_NAME}' adicionada com sucesso."

# ==============================
# RESUMO FINAL
# ==============================

section_title "Resumo"

print_field "Migration"          "$MIGRATION_NAME"
print_field "Projeto"            "${PROJECT_PATH:-(diretório atual)}"
print_field "Projeto de startup" "${STARTUP_PROJECT_PATH:-(diretório atual)}"

echo ""
success "Operação concluída."