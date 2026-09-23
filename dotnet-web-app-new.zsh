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
# Leitura dos parâmetros
# =========================

SOLUTION=""
PROJECT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --solution)
            SOLUTION="$2"
            shift 2
            ;;
        --project)
            PROJECT="$2"
            shift 2
            ;;
        *)
            err "Parâmetro inválido: $1"
            info "Uso: $0 --solution NomeSolution --project NomeProjeto"
            exit 1
            ;;
    esac
done

# =========================
# Validação dos parâmetros
# =========================

if [[ -z "$SOLUTION" ]]; then
    err "Parâmetro --solution é obrigatório."
    exit 1
fi

if [[ -z "$PROJECT" ]]; then
    err "Parâmetro --project é obrigatório."
    exit 1
fi

# =========================
# Descobre SDK mais recente
# =========================

SDK_VERSION=$(get_sdk_version)
FRAMEWORK=$(framework_from_sdk "$SDK_VERSION" "major_minor")

PROJECT_PATH="${SOLUTION}/${PROJECT}"

info "Solution: $SOLUTION"
info "Projeto: $PROJECT"
info "SDK: $SDK_VERSION"
info "Framework: $FRAMEWORK"

# =========================
# Criação dos artefatos
# =========================

dotnet new globaljson \
    --sdk-version "$SDK_VERSION" \
    --output "$SOLUTION" \
    --roll-forward latestMajor

dotnet new web \
    --no-https \
    --framework "$FRAMEWORK" \
    --output "$PROJECT_PATH"

dotnet new xunit \
    --framework "$FRAMEWORK" \
    --output "$PROJECT_PATH.Tests"

dotnet new sln \
    -o "$SOLUTION"

dotnet sln "$SOLUTION" add "$PROJECT_PATH"
dotnet sln "$SOLUTION" add "$PROJECT_PATH.Tests"
dotnet add "$PROJECT_PATH.Tests" reference "$PROJECT_PATH"
echo ""
success "Projeto criado com sucesso."