#!/usr/bin/env zsh

# Sai imediatamente se algum comando falhar e trata variáveis não definidas como erro
set -euo pipefail
clear

style_lib="$(dirname "$0")/shared-style.zsh"
if [[ ! -f "$style_lib" ]]; then
  echo "Erro: arquivo de biblioteca '$style_lib' não encontrado." >&2
  exit 1
fi
source "$style_lib"

common_lib="$(dirname "$0")/dotnet-common.zsh"
if [[ ! -f "$common_lib" ]]; then
  echo "Erro: arquivo de biblioteca '$common_lib' não encontrado." >&2
  exit 1
fi
source "$common_lib"

# ---------------------------------------------------------------------------
# Validação: dotnet disponível
# ---------------------------------------------------------------------------
check_dotnet

# =========================
# Validação: solution .slnx na pasta atual
# =========================

setopt local_options nullglob
slnx_files=(*.slnx)
unsetopt nullglob

if [[ ${#slnx_files[@]} -eq 0 ]]; then
    err "Nenhum arquivo .slnx encontrado na pasta atual."
    info "Execute este script a partir da raiz de uma solution válida."
    exit 1
fi

if [[ ${#slnx_files[@]} -gt 1 ]]; then
    err "Mais de um arquivo .slnx encontrado na pasta atual."
    info "Certifique-se de que existe apenas uma solution na pasta."
    exit 1
fi

SOLUTION_FILE="${slnx_files[1]}"
PROJECT_PATH="."

# =========================
# Validação: global.json ainda não existe
# =========================

if [[ -f "${PROJECT_PATH}/global.json" ]]; then
    err "Arquivo global.json já existe na pasta atual."
    exit 1
fi

# =========================
# Descobre SDK mais recente
# =========================

SDK_VERSION=$(get_sdk_version)

info "Solution: $SOLUTION_FILE"
info "SDK: $SDK_VERSION"

# =========================
# Criação do artefato
# =========================

dotnet new globaljson \
    --sdk-version "$SDK_VERSION" \
    --output "$PROJECT_PATH" \
    --roll-forward latestMajor

echo ""
success "Arquivo global.json criado com sucesso."