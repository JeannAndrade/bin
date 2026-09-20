#!/usr/bin/env zsh

# =============================================================================
# Script:   dotnet-publish-package.zsh
# Versão:   1.2.0
# Autor:    Jeann Andrade
# Criado:   2026-07-11
#
# Descrição:
#   Publica o pacote NuGet (.nupkg) mais recente da pasta "nupkgs":
#     1. No NuGet.org, usando "dotnet nuget push".
#     2. Na pasta local /home/jeann/NuGetPackages, usada como feed local.
#
# Uso:
#   ./dotnet-publish-package.zsh
#
# Pré-requisitos:
#   - A pasta "nupkgs" deve existir e conter ao menos um pacote gerado
#     previamente (ex.: via dotnet-pack-package.zsh).
#
# Dependências:
#   - shared-style.zsh   (formatação visual: success, info, err, etc.)
#   - dotnet-common.zsh  (validações: check_dotnet, find_latest_nupkg, etc.)
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

# Pasta local usada como feed de pacotes NuGet
local_feed_dir="/home/jeann/NuGetPackages"

# ---------------------------------------------------------------------------
# Validação: dotnet disponível
# ---------------------------------------------------------------------------
check_dotnet

require_dir "nupkgs" "Pasta 'nupkgs' não encontrada."
nupkg_file=$(find_latest_nupkg)

success "Pacote encontrado: $nupkg_file"

# ---------------------------------------------------------------------------
# Validação: API key do NuGet definida via variável de ambiente
# ---------------------------------------------------------------------------
if [[ -z "${NUGET_API_KEY:-}" ]]; then
  err "Variável de ambiente NUGET_API_KEY não definida."
  echo "Defina-a antes de executar este script, por exemplo:" >&2
  echo "  export NUGET_API_KEY=\"sua-chave-aqui\"" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Publicação no NuGet.org
# ---------------------------------------------------------------------------
section_title "1. Publicando no NuGet.org"

info "Executando: dotnet nuget push \"$nupkg_file\" --api-key \$NUGET_API_KEY --source https://api.nuget.org/v3/index.json"
echo ""

nuget_org_exit_code=0
dotnet nuget push "$nupkg_file" \
  --api-key "$NUGET_API_KEY" \
  --source https://api.nuget.org/v3/index.json || nuget_org_exit_code=$?

echo ""
if [[ $nuget_org_exit_code -eq 0 ]]; then
  success "Pacote publicado com sucesso no NuGet.org."
else
  err "Falha ao publicar o pacote no NuGet.org. Código de saída: $nuget_org_exit_code"
fi

# ---------------------------------------------------------------------------
# 2. Publicação na pasta local
# ---------------------------------------------------------------------------
section_title "2. Publicando na pasta local"

if [[ ! -d "$local_feed_dir" ]]; then
  info "Pasta local '$local_feed_dir' não existe. Criando..."
  mkdir -p "$local_feed_dir"
fi

info "Executando: dotnet nuget push \"$nupkg_file\" --source \"$local_feed_dir\""
echo ""

local_exit_code=0
dotnet nuget push "$nupkg_file" \
  --source "$local_feed_dir" || local_exit_code=$?

echo ""
if [[ $local_exit_code -eq 0 ]]; then
  success "Pacote publicado com sucesso na pasta local."
else
  err "Falha ao publicar o pacote na pasta local. Código de saída: $local_exit_code"
fi

# ---------------------------------------------------------------------------
# Resumo final
# ---------------------------------------------------------------------------
section_title "Resumo"

print_field "Pacote" "$nupkg_file"
print_field "NuGet.org" "$([[ $nuget_org_exit_code -eq 0 ]] && echo 'Sucesso' || echo "Falha ($nuget_org_exit_code)")"
print_field "Pasta local" "$([[ $local_exit_code -eq 0 ]] && echo 'Sucesso' || echo "Falha ($local_exit_code)")"

if [[ $nuget_org_exit_code -ne 0 || $local_exit_code -ne 0 ]]; then
  exit 1
fi

exit 0