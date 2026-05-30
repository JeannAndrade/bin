#!/usr/bin/env zsh

set -euo pipefail

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
            echo "Parâmetro inválido: $1"
            echo "Uso: $0 --solution NomeSolution --project NomeProjeto"
            exit 1
            ;;
    esac
done

# =========================
# Validação dos parâmetros
# =========================

if [[ -z "$SOLUTION" ]]; then
    echo "Erro: parâmetro --solution é obrigatório."
    exit 1
fi

if [[ -z "$PROJECT" ]]; then
    echo "Erro: parâmetro --project é obrigatório."
    exit 1
fi

# =========================
# Validação do .NET
# =========================

if ! command -v dotnet >/dev/null 2>&1; then
    echo "Erro: .NET SDK não encontrado."
    exit 1
fi

# =========================
# Descobre SDK mais recente
# =========================

SDK_VERSION=$(dotnet --version)

if [[ -z "$SDK_VERSION" ]]; then
    echo "Erro: não foi possível identificar a versão do SDK."
    exit 1
fi

# Exemplo:
# 10.0.108 -> net10.0
SDK_MAJOR=$(echo "$SDK_VERSION" | cut -d'.' -f1)
SDK_MINOR=$(echo "$SDK_VERSION" | cut -d'.' -f2)

FRAMEWORK="net${SDK_MAJOR}.${SDK_MINOR}"

PROJECT_PATH="${SOLUTION}/${PROJECT}"

echo "Solution : $SOLUTION"
echo "Projeto  : $PROJECT"
echo "SDK      : $SDK_VERSION"
echo "Framework: $FRAMEWORK"

# =========================
# Criação dos artefatos
# =========================

dotnet new globaljson \
    --sdk-version "$SDK_VERSION" \
    --output "$PROJECT_PATH"

dotnet new web \
    --no-https \
    --framework "$FRAMEWORK" \
    --output "$PROJECT_PATH"

dotnet new sln \
    -o "$SOLUTION"

dotnet sln "$SOLUTION" add "$PROJECT_PATH"

echo ""
echo "Projeto criado com sucesso."