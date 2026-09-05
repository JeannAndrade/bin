#!/usr/bin/env zsh
#
# dotnet-add-bootstrap.zsh
#
# Roda na raiz do repositório e:
#   1. Localiza .csproj recursivamente (via find_and_select_csproj, de
#      dotnet-common.zsh) e pede para você escolher onde instalar.
#   2. Garante libman.json (via `libman init -p cdnjs`), de forma idempotente.
#   3. Resolve a última versão ESTÁVEL do Bootstrap publicada no cdnjs.
#   4. Instala ou atualiza, removendo a instalação antiga antes de trocar
#      de versão (evita arquivos órfãos de versões anteriores).
#
# Pré-requisitos: dotnet SDK, libman CLI já instalado (rode o script de
# setup do libman antes), curl. jq é opcional (usado se disponível).
# Reusa shared-style.zsh (info/warn/err) e dotnet-common.zsh (check_dotnet,
# find_and_select_csproj) do mesmo toolkit do dotnet-start.zsh.

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
# Validação: dotnet, libman e curl disponíveis
# ---------------------------------------------------------------------------
check_dotnet

command -v libman >/dev/null 2>&1 || { err "libman CLI não encontrado. Rode o script de setup do libman primeiro."; exit 1; }
command -v curl   >/dev/null 2>&1 || { err "curl não encontrado no PATH."; exit 1; }

HAS_JQ=0
command -v jq >/dev/null 2>&1 && HAS_JQ=1

# --- 1. Buscar e selecionar o projeto (lógica compartilhada) ---------------

find_and_select_csproj "." || exit 1
selected_proj="$SELECTED_PROJECT"
proj_dir="${selected_proj:h}"   # :h = modificador zsh equivalente a dirname

info "Projeto selecionado: $selected_proj"

# Sinal de alerta (não bloqueante): Bootstrap normalmente só faz sentido em
# projetos que usam o SDK Web (Microsoft.NET.Sdk.Web), não em class libraries
# ou console apps. find_and_select_csproj não distingue isso porque varre
# o filesystem cru, sem saber nada sobre o tipo de cada projeto.
proj_sdk="$(grep -o 'Sdk="[^"]*"' "$selected_proj" 2>/dev/null | head -n1)"
if [[ "$proj_sdk" != *"Sdk.Web"* ]]; then
  warn "O projeto selecionado usa ${proj_sdk:-um Sdk não identificado}, não Microsoft.NET.Sdk.Web."
  warn "Confirma que é esse mesmo o projeto certo para receber assets estáticos?"
fi

info "Entrando em: $proj_dir"
cd "$proj_dir"

# --- 2. Garantir wwwroot ----------------------------------------------------

if [[ ! -d "wwwroot" ]]; then
  warn "Pasta wwwroot não existe em $proj_dir. Criando..."
  mkdir -p wwwroot
fi

# --- 3. Garantir libman.json (idempotente) ----------------------------------

if [[ -f "libman.json" ]]; then
  info "libman.json já existe em $proj_dir. Pulando 'libman init'."
else
  info "Inicializando libman com provider cdnjs..."
  libman init -p cdnjs
fi

# --- 4. Resolver a última versão estável do Bootstrap no cdnjs -------------
#
# Optamos por resolver a versão explicitamente via API do cdnjs, em vez de
# confiar em omitir a versão no `libman install` (comportamento que varia
# entre versões da CLI e não é documentado de forma consistente para todos
# os providers). Isso também nos dá o valor exato pra logar antes de agir.

info "Consultando cdnjs pela última versão estável do Bootstrap..."
cdnjs_response="$(curl -fsSL 'https://api.cdnjs.com/libraries/bootstrap?fields=version')"

if (( HAS_JQ )); then
  latest_version="$(print -r -- "$cdnjs_response" | jq -r '.version')"
else
  latest_version="$(print -r -- "$cdnjs_response" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')"
fi

if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
  err "Não foi possível resolver a versão mais recente do Bootstrap via cdnjs."
  exit 1
fi

info "Última versão estável disponível: $latest_version"

# --- 5. Instalar ou atualizar, evitando arquivos órfãos ----------------------

destination="wwwroot/lib/bootstrap"
current_entry="$(grep -o '"library": *"bootstrap@[^"]*"' libman.json 2>/dev/null || true)"
current_version="${current_entry#*bootstrap@}"
current_version="${current_version%\"}"

if [[ -n "$current_version" && "$current_version" == "$latest_version" ]]; then
  info "Bootstrap já está na versão mais recente ($latest_version) em $destination. Nada a fazer."
elif [[ -n "$current_version" ]]; then
  info "Versão instalada ($current_version) difere da mais recente ($latest_version)."
  info "Removendo entrada e arquivos antigos antes de reinstalar (evita arquivos órfãos de versão anterior)..."
  libman uninstall bootstrap
  libman install "bootstrap@${latest_version}" -d "$destination"
else
  info "Instalando Bootstrap ${latest_version} em ${destination}..."
  libman install "bootstrap@${latest_version}" -d "$destination"
fi

info "Concluído. Entrada final no libman.json:"
grep -A 3 '"bootstrap@' libman.json || true