#!/usr/bin/env zsh

# Sai imediatamente se algum comando falhar e trata variáveis não definidas como erro
set -euo pipefail
clear

lib="$(dirname "$0")/shared-style.zsh"
if [[ ! -f "$lib" ]]; then
  echo "Erro: arquivo de biblioteca '$lib' não encontrado." >&2
  exit 1
fi
source "$lib"

# Verifica se o dotnet está disponível
if ! command -v dotnet &>/dev/null; then
  err "O comando 'dotnet' não foi encontrado."
  info "Instale o .NET SDK em: https://dotnet.microsoft.com/download"
  exit 1
fi

info "dotnet SDK encontrado: $(dotnet --version)"

# Busca por arquivos .csproj na pasta atual e subpastas
projects=()
while IFS= read -r -d $'\0' file; do
  projects+=("$file")
done < <(find . -type f -name '*.csproj' -print0)

n=${#projects[@]}

if [ "$n" -eq 0 ]; then
  err "Nenhum arquivo .csproj encontrado neste diretório."
  exit $?
elif [ "$n" -eq 1 ]; then
  proj="${projects[1]}"
  info "Encontrado 1 projeto: $proj"
  dotnet run --project "$proj"
  exit $?
else
  info "Foram encontrados $n projetos:"
  i=1
  for proj in "${projects[@]}"; do
    printf "%3d) %s\n" "$i" "$proj"
    i=$((i+1))
  done

  while true; do
    printf "Escolha o número do projeto: "
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      if [ "$choice" -ge 1 ] && [ "$choice" -le "$n" ]; then
        break
      fi
    fi
    warn "Entrada inválida. Tente novamente."
  done

  selected="${projects[$choice]}"
  info "Executando projeto: $selected"
  dotnet run --project "$selected"
  exit $?
fi