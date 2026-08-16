#!/usr/bin/env zsh

# ---------------------------------
# Nome: dotnet-install-ef-tools.zsh
# Versão: 1.0
# Autor: Jeann Andrade
# Descrição: Instala globalmente a ferramenta dotnet-ef (Entity Framework
#            Core Tools). Se já estiver instalada, oferece atualizar.
# Uso:       dotnet-install-ef-tools.zsh
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
# Constantes
# ---------------------------------------------------------------------------

readonly TOOL_NAME="dotnet-ef"

# ---------------------------------------------------------------------------
# Validações iniciais
# ---------------------------------------------------------------------------

check_dotnet

# ==============================
# ETAPA 1 — VERIFICAR SE JÁ ESTÁ INSTALADA
# ==============================

section_title "Etapa 1 — Verificando instalação existente"

if dotnet tool list --global | awk '{print $1}' | grep -qx "$TOOL_NAME"; then
  INSTALLED_VERSION=$(dotnet tool list --global | awk -v tool="$TOOL_NAME" '$1 == tool {print $2}')
  info "'${TOOL_NAME}' já está instalada globalmente (versão ${INSTALLED_VERSION})."
  info "Atualizando para a versão mais recente..."

  if ! dotnet tool update --global "$TOOL_NAME"; then
    err "Falha ao atualizar '${TOOL_NAME}'."
    exit 1
  fi

  success "'${TOOL_NAME}' atualizada com sucesso."
else
  # ==============================
  # ETAPA 2 — INSTALAR
  # ==============================

  section_title "Etapa 2 — Instalando ${TOOL_NAME}"
  info "Executando: dotnet tool install --global ${TOOL_NAME}"

  if ! dotnet tool install --global "$TOOL_NAME"; then
    err "Falha ao instalar '${TOOL_NAME}'."
    exit 1
  fi

  success "'${TOOL_NAME}' instalada com sucesso."
fi

# ==============================
# RESUMO FINAL
# ==============================

section_title "Resumo"

EF_VERSION=$(dotnet ef --version 2>/dev/null | tail -n 1 || echo "desconhecida")
print_field "Ferramenta"  "$TOOL_NAME"
print_field "Versão"      "$EF_VERSION"

echo ""
success "dotnet-ef pronta para uso."