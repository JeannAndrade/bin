#!/usr/bin/env zsh

# Sai imediatamente se algum comando falhar
set -e

# Trata variáveis não definidas como erro
set -u

echo "=== Criador de Projeto Blazor (.NET) ==="

# Solicita o nome da solução
echo -n "Informe o nome da solução: "
read solution_name

# Validação do nome da solução
if [[ -z "$solution_name" ]]; then
  echo "❌ Erro: o nome da solução é obrigatório."
  exit 1
fi

# Solicita o nome do projeto
echo -n "Informe o nome do projeto: "
read project_name

# Validação do nome do projeto
if [[ -z "$project_name" ]]; then
  echo "❌ Erro: o nome do projeto é obrigatório."
  exit 1
fi

# Verifica se o dotnet está instalado
if ! command -v dotnet >/dev/null 2>&1; then
  echo "❌ Erro: o comando 'dotnet' não foi encontrado."
  echo "Instale o .NET SDK antes de continuar."
  exit 1
fi

echo
echo "✅ Criando solução '$solution_name' com projeto '$project_name'..."

# Cria o global.json com a versão do SDK
dotnet new globaljson --sdk-version 10.0.100 --output "$solution_name"

# Cria a solução
dotnet new sln -o "$solution_name"

# Cria o projeto Blazor
dotnet new blazor \
  --name "$project_name" \
  --output "$solution_name" \
  --framework net10.0 \
  --interactivity Auto \
  --auth None \
  --all-interactive false

echo "✅ Ajustando arquivo de solução para novo formato slnx"

# Remove o arquivo de solução criado automaticamente dentro do projeto
rm -rf "$solution_name/$project_name.sln"

# Adiciona o projeto à solução
dotnet sln "$solution_name" add "$solution_name/$project_name/$project_name.csproj"

echo
echo "🔧 Inicializando repositório Git..."

cd "$solution_name"

git init -b main
dotnet new gitignore

git add .
git commit -m "Initial commit"

echo
echo "🎉 Projeto Blazor criado e versionado com Git!"
