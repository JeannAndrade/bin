#!/usr/bin/env zsh

# Sai imediatamente se algum comando falhar e trata variáveis não definidas como erro
set -euo pipefail
clear

lib="$(dirname "$0")/shared-style.zsh"
if [[ ! -f "$lib" ]]; then
  echo "Erro: arquivo de biblioteca '$lib' não encontrado." >&2
  exit 1
fi
source "$lib"

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

