#!/usr/bin/env zsh

# Sai imediatamente se algum comando falhar e Trata variáveis não definidas como erro
set -euo pipefail

clear

# Definições de cores usadas no script (fallback quando não for TTY)
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