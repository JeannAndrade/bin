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