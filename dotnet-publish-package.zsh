#!/usr/bin/env zsh

# Sai imediatamente se algum comando falhar e trata variáveis não definidas como erro
set -euo pipefail
clear

# =============================================================================
# dotnet-publish-package2.zsh
# Publica o pacote .nupkg mais recente da pasta nupkgs no NuGet.
# Uso: ./dotnet-publish-package2.zsh
# =============================================================================

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

# Verifica se a pasta nupkgs existe
if [[ ! -d "nupkgs" ]]; then
  err "Pasta 'nupkgs' não encontrada."
  info "Execute o dotnet-pack-package.zsh antes deste script."
  exit 1
fi

# Recupera o .nupkg mais recente (exclui .symbols.nupkg)
nupkg_file=$(find nupkgs -maxdepth 1 -type f -name "*.nupkg" ! -name "*.symbols.nupkg" \
  -print0 | xargs -0 ls -t 2>/dev/null | head -n 1)

if [[ -z "$nupkg_file" ]]; then
  err "Nenhum arquivo .nupkg encontrado em ./nupkgs"
  exit 1
fi

success "Pacote encontrado: $nupkg_file"

# Executa o dotnet nuget push
info "Executando: dotnet nuget push \"$nupkg_file\" --api-key <api-key> --source https://api.nuget.org/v3/index.json"
echo ""

dotnet nuget push "$nupkg_file" \
  --api-key oy2j7droqw2kyo23l7jq5qxxslrjpqwefl2cibhhpyzkd4 \
  --source https://api.nuget.org/v3/index.json
exit_code=$?

echo ""
if [[ $exit_code -eq 0 ]]; then
  success "Pacote publicado com sucesso no NuGet."
else
  err "Falha ao publicar o pacote. Código de saída: $exit_code"
fi

exit $exit_code