#!/usr/bin/env zsh

# Sai imediatamente se algum comando falhar e Trata variáveis não definidas como erro
set -euo pipefail

clear

# Definições de cores usadas no script (fallback quando não for TTY)
if [[ -t 1 ]]; then
  BOLD='\033[1m'
  RED='\033[0;31m'
  YELLOW='\033[0;33m'
  GREEN='\033[0;32m'
  CYAN='\033[0;36m'
  NC='\033[0m'
else
  BOLD=''
  RED=''
  YELLOW=''
  GREEN=''
  CYAN=''
  NC=''
fi

# Helpers para mensagens padronizadas
err() { echo "${RED}${BOLD}Erro:${NC} $*"; }
warn() { echo "${YELLOW}Aviso:${NC} $*"; }
info() { echo "${CYAN}Info:${NC} $*"; }
success() { echo "${GREEN}$*${NC}"; }

# Verifica se o dotnet está disponível
if ! command -v dotnet &>/dev/null; then
  err "O comando 'dotnet' não foi encontrado."
  info "Instale o .NET SDK em: https://dotnet.microsoft.com/download"
  exit 1
fi

info "dotnet SDK encontrado: $(dotnet --version)"

dotnet --list-sdks
