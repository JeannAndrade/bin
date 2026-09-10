#!/usr/bin/env zsh

# =============================================================================
# Script:   shell-history-run.zsh
# Versão:   1.0.0
# Autor:    Jeann Andrade
# Criado:   2026-09-09
#
# Descrição:
#   Exibe os últimos 15 comandos do histórico do shell ("history -15"),
#   permite filtrar o resultado por um termo opcional (grep) e executa
#   o comando correspondente ao número escolhido.
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
# 1. Coletando o histórico recente
# ---------------------------------------------------------------------------
section_title "1. Últimos comandos do histórico"

history_output="$(history -15)"

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
exit_code=$?

# ---------------------------------------------------------------------------
# Resumo final
# ---------------------------------------------------------------------------
section_title "Resumo"

print_field "Comando executado" "$selected_command"
print_field "Código de saída" "$exit_code"

if [[ $exit_code -eq 0 ]]; then
  success "Comando executado com sucesso."
else
  err "Comando finalizado com código de saída $exit_code."
fi

exit $exit_code