#!/usr/bin/env zsh

# =============================================================================
# Script:   shell-history-run.zsh
# Versão:   1.2.0
# Autor:    Jeann Andrade
# Criado:   2026-09-09
#
# Descrição:
#   Exibe os últimos 15 comandos ÚNICOS do histórico do shell (via
#   "history", excluindo as próprias chamadas ao script e comandos
#   duplicados, mantendo a ocorrência mais recente de cada um), permite
#   filtrar o resultado por um termo opcional (grep) e executa o comando
#   correspondente ao número escolhido, sem resumo adicional depois —
#   apenas a saída do comando executado.
#
# Uso:
#   shell-history-run.zsh [termo-de-busca]
#
# Exemplos:
#   shell-history-run.zsh
#   shell-history-run.zsh git
#
# Dependências:
#   - shared-style.zsh   (formatação visual: success, info, err, etc.)
#   - dotnet-common.zsh  (validações: require_command, etc.)
#
# Observação:
#   Script interativo (usa "read"). Por isso NÃO usa "set -e": um comando
#   escolhido com código de saída != 0, ou uma leitura vazia, não deve
#   encerrar o script prematuramente. "set -u" e "set -o pipefail"
#   permanecem ativos.
# =============================================================================

set -uo pipefail
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

require_command grep "Comando 'grep' não encontrado."

filter_term="${1:-}"

# ---------------------------------------------------------------------------
# Carregando o histórico do disco
# ---------------------------------------------------------------------------
# Um script roda em um processo zsh novo e não-interativo, que começa com a
# lista de eventos de histórico vazia — "history"/"fc" só enxergam o que foi
# carregado NESTA sessão, não o histórico do shell interativo que chamou o
# script. Por isso é preciso carregar o HISTFILE explicitamente com "fc -R"
# antes de consultar os últimos comandos.
HISTSIZE=1000
histfile="${HISTFILE:-$HOME/.zsh_history}"

if [[ ! -f "$histfile" ]]; then
  err "Arquivo de histórico '$histfile' não encontrado."
  echo "Se você usa um HISTFILE customizado, exporte a variável antes de executar:" >&2
  echo "  export HISTFILE=\"/caminho/do/seu/histfile\"" >&2
  exit 1
fi

fc -R "$histfile"

# Nomes usados para invocar este próprio script (alias + nome do arquivo),
# para que essas chamadas não poluam a lista exibida — afinal a função do
# script é executar comandos passados, não aparecer nele mesmo.
self_names="hst|shell-history-run\.zsh"

# ---------------------------------------------------------------------------
# 1. Coletando o histórico recente
# ---------------------------------------------------------------------------
section_title "1. Últimos comandos do histórico"

history_output="$(history | awk -v pat="$self_names" '{
  line=$0
  sub(/^[[:space:]]*[0-9]+[[:space:]]+/, "", line)
  if (line !~ ("^(" pat ")([[:space:]]|$)")) print $0
}' | tac | awk '{
  cmd=$0
  sub(/^[[:space:]]*[0-9]+[[:space:]]+/, "", cmd)
  if (!(cmd in seen)) {
    seen[cmd]=1
    print $0
  }
}' | head -15 | tac)"

if [[ -n "$filter_term" ]]; then
  info "Filtrando por: \"$filter_term\""
  history_output="$(echo "$history_output" | grep -i -- "$filter_term" || true)"
fi

if [[ -z "$history_output" ]]; then
  warn "Nenhum comando encontrado."
  exit 0
fi

echo "$history_output"
echo ""

# ---------------------------------------------------------------------------
# 2. Selecionando o comando
# ---------------------------------------------------------------------------
section_title "2. Selecionar comando"

echo -n "Informe o número do comando que deseja executar (Enter para cancelar): "
read -r selected_number

if [[ -z "$selected_number" ]]; then
  info "Operação cancelada."
  exit 0
fi

if ! [[ "$selected_number" =~ ^[0-9]+$ ]]; then
  err "Número inválido: $selected_number"
  exit 1
fi

selected_line="$(echo "$history_output" | awk -v n="$selected_number" '$1 == n')"

if [[ -z "$selected_line" ]]; then
  err "Nenhum comando com o número $selected_number foi encontrado na lista exibida."
  exit 1
fi

selected_command="$(echo "$selected_line" | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]*//')"

# ---------------------------------------------------------------------------
# 3. Executando o comando
# ---------------------------------------------------------------------------
section_title "3. Executando comando"

print_field "Comando" "$selected_command"
echo ""

eval "$selected_command"
exit $?