#!/usr/bin/env zsh

# Sai imediatamente se algum comando falhar e Trata variáveis não definidas como erro
set -euo pipefail

# --- Cores para output ---
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
if ! command -v dotnet >/dev/null 2>&1; then
  err "dotnet CLI não encontrado."
  exit 1
fi

info "Buscando pacotes desatualizados..."
echo ""

projeto=""
comandos=()

# Captura stdout + stderr
while IFS= read -r linha; do
  # Remove espaços à esquerda (trim leading whitespace)
  linha="${linha#"${linha%%[![:space:]]*}"}"

  # Detecta projeto
  if [[ "$linha" == Project* ]]; then
    projeto=$(echo "$linha" | sed -E "s/Project \`(.+)\`.*/\1/")
  fi

  # Detecta package desatualizado
  if [[ "$linha" == ">"* ]]; then
    linha_limpa="${linha#> }"

    pacote=$(echo "$linha_limpa" | awk '{print $1}')
    versao_latest=$(echo "$linha_limpa" | awk '{print $NF}')

    comandos+=("dotnet add \"$projeto\" package \"$pacote\" --version $versao_latest")
  fi
done < <(dotnet list package --outdated 2>&1)

# Se não houver comandos, sair
if [[ ${#comandos[@]} -eq 0 ]]; then
  info "Nenhum pacote desatualizado encontrado."
  exit 0
fi

info "Os seguintes comandos serão executados:"
echo ""

for cmd in "${comandos[@]}"; do
  info "  $cmd"
done

echo ""
printf "Deseja executar esses comandos agora? (s/N): "
read -r resposta

if [[ "$resposta" != "s" && "$resposta" != "S" ]]; then
  warn "Operação cancelada pelo usuário."
  exit 0
fi

info "Executando atualizações..."
echo ""

for cmd in "${comandos[@]}"; do
  info "  $cmd"
  eval "$cmd"
done

echo ""
success "Atualização de pacotes concluída com sucesso."

dotnet restore
dotnet build

