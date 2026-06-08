#!/usr/bin/env zsh

# Sai imediatamente se algum comando falhar e trata variáveis não definidas como erro
set -euo pipefail
clear

# =============================================================================
# dotnet-publish-package.zsh
# Empacota um projeto .NET com symbols.
# Uso: ./dotnet-publish-package.zsh <nome-do-projeto>
# =============================================================================

lib="$(dirname "$0")/shared-style.zsh"
if [[ ! -f "$lib" ]]; then
  echo "Erro: arquivo de biblioteca '$lib' não encontrado." >&2
  exit 1
fi
source "$lib"

# Valida o parâmetro
if [[ -z "$1" ]]; then
  err "Informe o nome do projeto."
  info "Uso: $0 <nome-do-projeto>"
  exit 1
fi

# Verifica se o dotnet está disponível
if ! command -v dotnet &>/dev/null; then
  err "O comando 'dotnet' não foi encontrado."
  info "Instale o .NET SDK em: https://dotnet.microsoft.com/download"
  exit 1
fi

info "dotnet SDK encontrado: $(dotnet --version)"

# Pesquisa pelo arquivo .csproj na pasta local e subpastas
csproj_file=$(find . -type f -name "${1}.csproj" 2>/dev/null | head -n 1)

if [[ -z "$csproj_file" ]]; then
  err "Arquivo '${1}.csproj' não encontrado."
  exit 1
fi

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
