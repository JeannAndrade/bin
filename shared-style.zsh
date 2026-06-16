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
err() { echo "${RED}${BOLD}Erro:${NC} $*" >&2; }
warn()    { echo "${YELLOW}Aviso:${NC} $*"; }
info()    { echo "${CYAN}Info:${NC} $*"; }
success() { echo "${GREEN}$*${NC}"; }

# Exibe um título de seção com separador
# Uso: section_title "Título da Seção"
section_title() {
  local title="$*"
  local sep="────────────────────────────"
  echo
  echo "${BOLD}${CYAN}${title}${NC}"
  echo "${CYAN}${sep}${NC}"
}

# Exibe um par label: valor formatado
# Uso: print_field "Label" "valor"
print_field() {
  local label="$1"
  local value="$2"
  printf "  ${BOLD}%-20s${NC} %s\n" "${label}:" "${value}"
}