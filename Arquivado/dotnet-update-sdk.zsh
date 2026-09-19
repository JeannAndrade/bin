#!/usr/bin/env zsh

# =============================================================================
# Script:   dotnet-update-sdk.zsh
# Autor:    Jeann Andrade
# Criado:   2026-07-11
#
# Descrição:
#   Atualiza o .NET SDK instalado via feeds nativos do apt (Ubuntu) para a
#   versão mais recente disponível (dotnet-sdk-*). O processo é feito em
#   4 etapas: (1) atualiza o índice de pacotes, (2) identifica a versão
#   mais recente disponível, (3) remove as versões do SDK atualmente
#   instaladas e (4) instala a nova versão. A remoção antes da instalação
#   é proposital, para evitar que a limpeza de pacotes antigos derrube a
#   versão recém-instalada.
#
# Uso:
#   ./dotnet-update-sdk.zsh
#
#   Requer privilégios de sudo (apt update/remove/autoremove/install).
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
# Constantes
# ---------------------------------------------------------------------------

readonly DOTNET_PKG_PREFIX="dotnet-sdk"

# ---------------------------------------------------------------------------
# Funções locais
# ---------------------------------------------------------------------------

# Lista todos os pacotes dotnet-sdk-* disponíveis no apt e retorna o nome
# do pacote com a versão mais recente (ex: dotnet-sdk-10)
find_latest_sdk_package() {
  local latest_pkg
  latest_pkg=$(
    apt-cache search "^${DOTNET_PKG_PREFIX}-[0-9]" 2>/dev/null \
      | awk '{print $1}' \
      | grep -E "^${DOTNET_PKG_PREFIX}-[0-9]+(\.[0-9]+)?$" \
      | sort -t'-' -k3 -V \
      | tail -n 1
  )
  if [[ -z "$latest_pkg" ]]; then
    err "Nenhum pacote ${DOTNET_PKG_PREFIX}-* encontrado nos feeds do apt."
    err "Verifique se os repositórios do Ubuntu estão atualizados (sudo apt update)."
    exit 1
  fi
  printf "%s" "$latest_pkg"
}

# Lista todos os pacotes dotnet-sdk-* atualmente instalados
list_installed_sdk_packages() {
  dpkg-query -W -f='${Package}\n' 2>/dev/null \
    | grep -E "^${DOTNET_PKG_PREFIX}-[0-9]+(\.[0-9]+)?$" \
    | sort -t'-' -k3 -V \
    || true
}

# ---------------------------------------------------------------------------
# Validações iniciais
# ---------------------------------------------------------------------------

require_command apt          "O comando 'apt' não está disponível. Este script requer Ubuntu."
require_command apt-cache    "O comando 'apt-cache' não está disponível."
require_command dpkg-query   "O comando 'dpkg-query' não está disponível."

# ---------------------------------------------------------------------------
# Etapa 1 — Atualizar índice de pacotes
# ---------------------------------------------------------------------------

section_title "Etapa 1 — Atualizando índice de pacotes"

info "Executando apt update..."
if ! sudo apt update -y 2>&1; then
  err "Falha ao atualizar o índice de pacotes."
  exit 1
fi
success "Índice de pacotes atualizado."

# ---------------------------------------------------------------------------
# Etapa 2 — Identificar versão mais recente disponível
# ---------------------------------------------------------------------------

section_title "Etapa 2 — Identificando versão mais recente do .NET SDK"

LATEST_PKG=$(find_latest_sdk_package)
info "Pacote mais recente disponível: ${LATEST_PKG}"

# Obtém a versão exata que será instalada
LATEST_APT_VERSION=$(apt-cache policy "$LATEST_PKG" 2>/dev/null \
  | grep "Candidato:" \
  | awk '{print $2}' \
  || true)

if [[ -z "$LATEST_APT_VERSION" ]]; then
  # Fallback para sistemas com locale em inglês
  LATEST_APT_VERSION=$(apt-cache policy "$LATEST_PKG" 2>/dev/null \
    | grep -E "Candidate:" \
    | awk '{print $2}' \
    || true)
fi

print_field "Pacote"  "$LATEST_PKG"
print_field "Versão"  "${LATEST_APT_VERSION:-desconhecida}"

# ---------------------------------------------------------------------------
# Etapa 3 — Desinstalar versões existentes
# ---------------------------------------------------------------------------

section_title "Etapa 3 — Desinstalando versões existentes"

INSTALLED_PKGS=("${(@f)$(list_installed_sdk_packages)}")
[[ -z "${INSTALLED_PKGS[1]:-}" ]] && INSTALLED_PKGS=()

if [[ ${#INSTALLED_PKGS[@]} -eq 0 ]]; then
  info "Nenhum pacote ${DOTNET_PKG_PREFIX}-* instalado. Nada a remover."
else
  info "Pacotes encontrados:"
  for pkg in "${INSTALLED_PKGS[@]}"; do
    installed_ver=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "?")
    print_list_item "${pkg} (${installed_ver})"
  done

  echo ""
  info "Removendo..."
  if ! sudo apt remove -y "${INSTALLED_PKGS[@]}" 2>&1; then
    err "Falha ao remover os pacotes existentes. Abortando."
    exit 1
  fi
  if ! sudo apt autoremove -y 2>&1; then
    warn "Falha no autoremove. Pode haver dependências residuais."
  fi
  success "Versões anteriores removidas."
fi

# ---------------------------------------------------------------------------
# Etapa 4 — Instalar versão mais recente
# ---------------------------------------------------------------------------

section_title "Etapa 4 — Instalando ${LATEST_PKG}"

info "Instalando ${LATEST_PKG}..."
if ! sudo apt install -y "$LATEST_PKG" 2>&1; then
  err "Falha ao instalar ${LATEST_PKG}."
  exit 1
fi

# Confirma que a instalação foi bem-sucedida verificando o binário
check_dotnet
NEW_SDK_VERSION=$(get_sdk_version)
success "SDK instalado com sucesso: ${NEW_SDK_VERSION}"

# ---------------------------------------------------------------------------
# Resumo final
# ---------------------------------------------------------------------------

section_title "Resumo"

print_field "SDK instalado"  "$(get_sdk_version)"
print_field "Pacote"         "$LATEST_PKG"

echo ""
success "Atualização do .NET SDK concluída com sucesso."