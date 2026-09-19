#!/usr/bin/env zsh

# =============================================================================
# Script:   dotnet-start.zsh
# Versão:   1.1
# Autor:    Jeann Andrade
# Criado:   2026-07-11
#
# Descrição:
#   Localiza projetos .NET executáveis (Service ou Presentation, seguindo
#   a arquitetura em camadas da solution) na pasta atual e subpastas, limpa
#   as pastas bin/obj, executa "dotnet build" e depois "dotnet run" no
#   projeto encontrado. Se houver apenas um projeto, executa diretamente;
#   se houver mais de um, exibe um menu numerado para escolha.
#
#   Projetos de biblioteca (Application, Persistence, Domain, etc.) e de
#   teste não são considerados, pois não são executáveis.
#
# Uso:
#   ./dotnet-start.zsh
#
# =============================================================================

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

run_project() {
  local project="$1"

  info "Limpando as pastas bin e obj dos projetos..."
  find . -type d \( -name 'bin' -o -name 'obj' \) -prune -exec rm -rf {} +

  info "Compilando projeto: $project"
  dotnet build "$project"

  info "Executando projeto: $project"
  dotnet run --project "$project"
}

# Busca apenas projetos executáveis: Service.csproj / *.Service.csproj (API)
# e Presentation.csproj / *.Presentation.csproj (Web). Projetos de biblioteca
# (Application, Persistence, Domain, etc.) e de teste ficam automaticamente
# de fora, pois não seguem esses nomes/sufixos.
projects=()
while IFS= read -r -d $'\0' file; do
  projects+=("$file")
done < <(find . -type f \( \
    -name 'Service.csproj' -o -name '*.Service.csproj' \
    -o -name 'Presentation.csproj' -o -name '*.Presentation.csproj' \
  \) -print0)

n=${#projects[@]}

if [ "$n" -eq 0 ]; then
  err "Nenhum projeto executável (Service ou Presentation) encontrado neste diretório."
  exit $?
elif [ "$n" -eq 1 ]; then
  proj="${projects[1]}"
  info "Encontrado 1 projeto: $proj"
  run_project "$proj"
  exit $?
else
  info "Foram encontrados $n projetos executáveis:"
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
  run_project "$selected"
  exit $?
fi