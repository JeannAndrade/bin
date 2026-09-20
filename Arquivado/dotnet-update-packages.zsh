#!/usr/bin/env zsh

# =============================================================================
# Script:   dotnet-update-packages.zsh
# Autor:    Jeann Andrade
# Criado:   2026-07-11
#
# Descrição:
#   Verifica pacotes NuGet desatualizados no projeto (via "dotnet list
#   package --outdated"), monta os comandos "dotnet add package" com a
#   versão mais recente de cada um e, mediante confirmação, executa todas
#   as atualizações, seguidas de "dotnet restore" e "dotnet build".
#
# Uso:
#   ./dotnet-update-packages.zsh
#
# Dependências:
#   - shared-style.zsh   (formatação visual: info, warn, success, etc.)
#   - dotnet-common.zsh  (validações: check_dotnet, etc.)
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
# Validação: dotnet disponível
# ---------------------------------------------------------------------------
check_dotnet

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

falhas=()

for cmd in "${comandos[@]}"; do
  info "  $cmd"
  if ! eval "$cmd"; then
    warn "Falha ao executar: $cmd"
    falhas+=("$cmd")
  fi
done

echo ""
if [[ ${#falhas[@]} -gt 0 ]]; then
  warn "Atualização concluída com ${#falhas[@]} falha(s):"
  for cmd in "${falhas[@]}"; do
    warn "  $cmd"
  done
else
  success "Atualização de pacotes concluída com sucesso."
fi

dotnet restore
dotnet build