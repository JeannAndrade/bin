#!/usr/bin/env zsh

# =============================================================================
# Script:   dotnet-pack-package.zsh
# Autor:    Jeann Andrade
# Criado:   2026-07-11
#
# Descrição:
#   Empacota um projeto .NET em um pacote NuGet (.nupkg), incluindo os
#   símbolos de depuração (--include-symbols). A pasta de saída "nupkgs"
#   é limpa antes de cada execução para evitar pacotes obsoletos.
#
# Uso:
#   ./dotnet-pack-package.zsh <nome-do-projeto>
#
# Exemplo:
#   ./dotnet-pack-package.zsh MinhaLib
#
# Dependências:
#   - shared-style.zsh   (formatação visual: success, info, err, etc.)
#   - dotnet-common.zsh  (validações: check_dotnet, find_csproj_by_name, etc.)
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

require_non_empty "${1:-}" "Informe o nome do projeto."
csproj_file=$(find_csproj_by_name "$1")

success "Projeto encontrado: $csproj_file"

# Limpa a pasta de saída antes de empacotar
if [[ -d "nupkgs" ]]; then
  info "Limpando pasta nupkgs..."
  rm -rf nupkgs
fi
mkdir -p nupkgs

# Executa o dotnet pack
info "Executando: dotnet pack \"$csproj_file\" --include-symbols --output nupkgs"
echo ""

dotnet pack "$csproj_file" --include-symbols --output nupkgs
exit_code=$?

echo ""
if [[ $exit_code -eq 0 ]]; then
  success "Pack concluído com sucesso. Pacotes em: ./nupkgs"
else
  err "Falha no dotnet pack. Código de saída: $exit_code"
fi

exit $exit_code