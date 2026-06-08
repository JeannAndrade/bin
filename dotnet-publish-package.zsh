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

require_dir "nupkgs" "Pasta 'nupkgs' não encontrada."
nupkg_file=$(find_latest_nupkg)

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