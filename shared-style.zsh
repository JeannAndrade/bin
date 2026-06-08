# Este arquivo não é executável diretamente.
# Carregue-o via: source "$(dirname "$0")/shared-style.zsh"

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
err()     { echo "${RED}${BOLD}Erro:${NC} $*"; }
warn()    { echo "${YELLOW}Aviso:${NC} $*"; }
info()    { echo "${CYAN}Info:${NC} $*"; }
success() { echo "${GREEN}$*${NC}"; }