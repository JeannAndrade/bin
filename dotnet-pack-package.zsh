#!/usr/bin/env zsh

# =============================================================================
# dotnet-publish-package.zsh
# Empacota um projeto .NET com symbols.
# Uso: ./dotnet-publish-package.zsh <nome-do-projeto>
# =============================================================================

# --- Cores para output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Valida o parâmetro
if [[ -z "$1" ]]; then
  echo "${RED}Erro:${NC} Informe o nome do projeto."
  echo "Uso: $0 <nome-do-projeto>"
  exit 1
fi

# Verifica se o dotnet está disponível
if ! command -v dotnet &>/dev/null; then
  echo "${RED}Erro:${NC} O comando 'dotnet' não foi encontrado."
  echo "Instale o .NET SDK em: https://dotnet.microsoft.com/download"
  exit 1
fi

echo "${CYAN}dotnet SDK encontrado:${NC} $(dotnet --version)"

# Pesquisa pelo arquivo .csproj na pasta local e subpastas
csproj_file=$(find . -type f -name "${1}.csproj" 2>/dev/null | head -n 1)

if [[ -z "$csproj_file" ]]; then
  echo "${RED}Erro:${NC} Arquivo '${1}.csproj' não encontrado."
  exit 1
fi

echo "${GREEN}Projeto encontrado:${NC} $csproj_file"

# Limpa a pasta de saída antes de empacotar
if [[ -d "nupkgs" ]]; then
  echo "${CYAN}Limpando pasta nupkgs...${NC}"
  rm -rf nupkgs
fi
mkdir -p nupkgs

# Executa o dotnet pack
echo "${CYAN}Executando:${NC} dotnet pack \"$csproj_file\" --include-symbols --output nupkgs"
echo ""

dotnet pack "$csproj_file" --include-symbols --output nupkgs
exit_code=$?

echo ""
if [[ $exit_code -eq 0 ]]; then
  echo "${GREEN}✔ Pack concluído com sucesso!${NC} Pacotes em: ./nupkgs"
else
  echo "${RED}✘ Falha no dotnet pack.${NC} Código de saída: $exit_code"
fi

exit $exit_code
