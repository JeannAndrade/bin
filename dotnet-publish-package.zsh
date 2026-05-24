#!/usr/bin/env zsh

# =============================================================================
# dotnet-publish-package2.zsh
# Publica o pacote .nupkg mais recente da pasta nupkgs no NuGet.
# Uso: ./dotnet-publish-package2.zsh
# =============================================================================

# --- Cores para output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Verifica se o dotnet está disponível
if ! command -v dotnet &>/dev/null; then
  echo "${RED}Erro:${NC} O comando 'dotnet' não foi encontrado."
  echo "Instale o .NET SDK em: https://dotnet.microsoft.com/download"
  exit 1
fi

echo "${CYAN}dotnet SDK encontrado:${NC} $(dotnet --version)"

# Verifica se a pasta nupkgs existe
if [[ ! -d "nupkgs" ]]; then
  echo "${RED}Erro:${NC} Pasta 'nupkgs' não encontrada."
  echo "Execute o dotnet-pack-package.zsh antes deste script."
  exit 1
fi

# Recupera o .nupkg mais recente (exclui .symbols.nupkg)
nupkg_file=$(find nupkgs -maxdepth 1 -type f -name "*.nupkg" ! -name "*.symbols.nupkg" \
  -print0 | xargs -0 ls -t 2>/dev/null | head -n 1)

if [[ -z "$nupkg_file" ]]; then
  echo "${RED}Erro:${NC} Nenhum arquivo .nupkg encontrado em ./nupkgs"
  exit 1
fi

echo "${GREEN}Pacote encontrado:${NC} $nupkg_file"

# Executa o dotnet nuget push
echo "${CYAN}Executando:${NC} dotnet nuget push \"$nupkg_file\" --api-key <api-key> --source https://api.nuget.org/v3/index.json"
echo ""

dotnet nuget push "$nupkg_file" \
  --api-key oy2j7droqw2kyo23l7jq5qxxslrjpqwefl2cibhhpyzkd4 \
  --source https://api.nuget.org/v3/index.json
exit_code=$?

echo ""
if [[ $exit_code -eq 0 ]]; then
  echo "${GREEN}✔ Pacote publicado com sucesso no NuGet!${NC}"
else
  echo "${RED}✘ Falha ao publicar o pacote.${NC} Código de saída: $exit_code"
fi

exit $exit_code