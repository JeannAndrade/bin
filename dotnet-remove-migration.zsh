#!/usr/bin/env zsh

# ---------------------------------
# Nome: dotnet-remove-migration.zsh
# Versão: 1.0
# Autor: Jeann Andrade
# Descrição: Remove a última migration usando o Entity Framework Core
#            Tools (dotnet-ef).
# Uso:       dotnet-remove-migration.zsh [--project <path>] [--startup-project <path>] [--force]
#            --project           Projeto onde a migration será removida (onde fica o DbContext).
#            --startup-project   Projeto de inicialização, usado para resolver a connection string.
#            --force             Reverte a migration no banco de dados, se já tiver sido aplicada.
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
  err "Uso: $(basename "$0") [--project <path>] [--startup-project <path>] [--force]"
}

PROJECT_PATH=""
STARTUP_PROJECT_PATH=""
FORCE_FLAG=false

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
    --force)
      FORCE_FLAG=true
      shift
      ;;
    *)
      err "Opção desconhecida: $1"
      usage
      exit 1
      ;;
  esac
done

# ==============================
# ETAPA 1 — REMOVER ÚLTIMA MIGRATION
# ==============================

EF_ARGS=(migrations remove)

if [[ -n "$PROJECT_PATH" ]]; then
  EF_ARGS+=(--project "$PROJECT_PATH")
fi

if [[ -n "$STARTUP_PROJECT_PATH" ]]; then
  EF_ARGS+=(--startup-project "$STARTUP_PROJECT_PATH")
fi

if [[ "$FORCE_FLAG" == true ]]; then
  EF_ARGS+=(--force)
fi

section_title "Etapa 1 — Removendo a última migration"
info "Executando: dotnet ef ${EF_ARGS[*]}"

if ! dotnet ef "${EF_ARGS[@]}"; then
  err "Falha ao remover a migration."
  err "Se ela já foi aplicada ao banco de dados, use a opção --force."
  exit 1
fi

success "Migration removida com sucesso."

# ==============================
# RESUMO FINAL
# ==============================

section_title "Resumo"

print_field "Projeto"            "${PROJECT_PATH:-(diretório atual)}"
print_field "Projeto de startup" "${STARTUP_PROJECT_PATH:-(diretório atual)}"
print_field "Force"              "$FORCE_FLAG"

echo ""
success "Operação concluída."