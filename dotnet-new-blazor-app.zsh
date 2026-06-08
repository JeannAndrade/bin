#!/usr/bin/env zsh

# Sai imediatamente se algum comando falhar e Trata variáveis não definidas como erro
set -euo pipefail

# --- Cores para output ---
if [[ -t 1 ]]; then
  BOLD='\033[1m'
  RED='\033[0;31m'
  YELLOW='\033[0;33m'
  GREEN='\033[0;32m'
  CYAN='\033[0;36m'
  NC='\033[0m'
else
  BOLD=''
  RED=''
  YELLOW=''
  GREEN=''
  CYAN=''
  NC=''
fi

# Helpers para mensagens padronizadas
err() { echo "${RED}${BOLD}Erro:${NC} $*"; }
warn() { echo "${YELLOW}Aviso:${NC} $*"; }
info() { echo "${CYAN}Info:${NC} $*"; }
success() { echo "${GREEN}$*${NC}"; }

info "=== Criador de Projeto Blazor (.NET) ==="

# Solicita o nome da solução
echo -n "Informe o nome da solução: "
read -r solution_name

# Validação do nome da solução
if [[ -z "$solution_name" ]]; then
  err "O nome da solução é obrigatório."
  exit 1
fi

# Solicita o nome do projeto
echo -n "Informe o nome do projeto: "
read -r project_name

# Validação do nome do projeto
if [[ -z "$project_name" ]]; then
  err "O nome do projeto é obrigatório."
  exit 1
fi

# Verifica se o dotnet está instalado
if ! command -v dotnet >/dev/null 2>&1; then
  err "O comando 'dotnet' não foi encontrado."
  info "Instale o .NET SDK antes de continuar."
  exit 1
fi

# Descobre a versão do SDK em uso
SDK_VERSION=$(dotnet --version)

if [[ -z "$SDK_VERSION" ]]; then
  err "Não foi possível identificar a versão do SDK."
  exit 1
fi

SDK_MAJOR=${SDK_VERSION%%.*}
FRAMEWORK="net${SDK_MAJOR}.0"

info "SDK encontrado: $SDK_VERSION"
info "Framework: $FRAMEWORK"
echo

echo
info "Criando solução '$solution_name' com projeto '$project_name'..."

# Cria o global.json com a versão do SDK
dotnet new globaljson \
  --sdk-version "$SDK_VERSION" \
  --output "$solution_name"

# Cria a solução
dotnet new sln -o "$solution_name"

# Cria o projeto Blazor
dotnet new blazor \
  --name "$project_name" \
  --output "$solution_name" \
  --framework "$FRAMEWORK" \
  --interactivity Auto \
  --auth None \
  --all-interactive false

info "Ajustando arquivo de solução para novo formato slnx"

# Remove o arquivo de solução criado automaticamente dentro do projeto
rm -rf "$solution_name/$project_name.sln"

# Adiciona o projeto à solução
dotnet sln "$solution_name" add "$solution_name/$project_name/$project_name.csproj"

echo
info "Inicializando repositório Git..."

cd "$solution_name"

git init -b main
dotnet new gitignore

git add .
git commit -m "Initial commit"

echo
success "Projeto Blazor criado e versionado com Git!"
