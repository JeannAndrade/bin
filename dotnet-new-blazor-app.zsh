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

# Descobre a versão do SDK em uso
SDK_VERSION=$(get_sdk_version)
FRAMEWORK=$(framework_from_sdk "$SDK_VERSION" "major_zero")

info "SDK encontrado: $SDK_VERSION"
info "Framework: $FRAMEWORK"
echo

echo
info "Criando solução '$solution_name' com projeto '$project_name'..."

# Cria o global.json com a versão do SDK
dotnet new globaljson \
  --sdk-version "$SDK_VERSION" \
  --output "$solution_name" \
  --roll-forward latestMajor

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
