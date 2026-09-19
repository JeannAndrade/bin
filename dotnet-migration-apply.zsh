#!/usr/bin/env zsh

# ---------------------------------
# Nome: dotnet-update-database.zsh
# Versão: 1.1
# Autor: Jeann Andrade
# Descrição: Aplica as migrations pendentes ao banco de dados usando o
#            Entity Framework Core Tools (dotnet-ef).
# Uso:       dotnet-update-database.zsh [migration] [--project <path>] [--startup-project <path>] [--connection <string>] [--context <nome>]
#            migration            Opcional. Nome da migration alvo. Se omitido,
#                                 aplica todas as migrations pendentes. Use "0"
#                                 para reverter todas (voltar ao banco vazio).
#            --project            Projeto onde ficam as migrations (onde fica o DbContext).
#            --startup-project    Projeto de inicialização, usado para resolver a connection string.
#            --connection         Connection string customizada, sobrepõe a do appsettings.
#            --context            Nome do DbContext a ser usado, quando houver mais de um no projeto.
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
  err "Uso: $(basename "$0") [migration] [--project <path>] [--startup-project <path>] [--connection <string>] [--context <nome>]"
}

TARGET_MIGRATION=""
PROJECT_PATH=""
STARTUP_PROJECT_PATH=""
CONNECTION_STRING=""
CONTEXT_NAME=""

# O nome da migration (posicional) só é aceito se vier antes das flags e
# ainda não tiver sido definido.
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
    --connection)
      if [[ $# -lt 2 || -z "${2// }" ]]; then
        err "A opção --connection exige um valor."
        usage
        exit 1
      fi
      CONNECTION_STRING="$2"
      shift 2
      ;;
    --context)
      if [[ $# -lt 2 || -z "${2// }" ]]; then
        err "A opção --context exige um valor."
        usage
        exit 1
      fi
      CONTEXT_NAME="$2"
      shift 2
      ;;
    --*)
      err "Opção desconhecida: $1"
      usage
      exit 1
      ;;
    *)
      if [[ -n "$TARGET_MIGRATION" ]]; then
        err "Apenas um nome de migration pode ser informado."
        usage
        exit 1
      fi
      TARGET_MIGRATION="$1"
      shift
      ;;
  esac
done

# ==============================
# ETAPA 1 — APLICAR MIGRATION(S)
# ==============================

EF_ARGS=(database update)

if [[ -n "$TARGET_MIGRATION" ]]; then
  EF_ARGS+=("$TARGET_MIGRATION")
fi

if [[ -n "$PROJECT_PATH" ]]; then
  EF_ARGS+=(--project "$PROJECT_PATH")
fi

if [[ -n "$STARTUP_PROJECT_PATH" ]]; then
  EF_ARGS+=(--startup-project "$STARTUP_PROJECT_PATH")
fi

if [[ -n "$CONNECTION_STRING" ]]; then
  EF_ARGS+=(--connection "$CONNECTION_STRING")
fi

if [[ -n "$CONTEXT_NAME" ]]; then
  EF_ARGS+=(--context "$CONTEXT_NAME")
fi

if [[ -n "$TARGET_MIGRATION" ]]; then
  section_title "Etapa 1 — Atualizando o banco de dados até '${TARGET_MIGRATION}'"
else
  section_title "Etapa 1 — Aplicando migrations pendentes ao banco de dados"
fi

info "Executando: dotnet ef ${EF_ARGS[*]}"

if ! dotnet ef "${EF_ARGS[@]}"; then
  err "Falha ao atualizar o banco de dados."
  exit 1
fi

success "Banco de dados atualizado com sucesso."

# ==============================
# RESUMO FINAL
# ==============================

section_title "Resumo"

print_field "Migration alvo"       "${TARGET_MIGRATION:-(todas as pendentes)}"
print_field "Projeto"              "${PROJECT_PATH:-(diretório atual)}"
print_field "Projeto de startup"   "${STARTUP_PROJECT_PATH:-(diretório atual)}"
print_field "Connection string"    "${CONNECTION_STRING:-(padrão do appsettings)}"
print_field "DbContext"            "${CONTEXT_NAME:-(não especificado)}"

echo ""
success "Operação concluída."