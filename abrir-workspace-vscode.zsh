#!/usr/bin/env zsh

# Sai no primeiro erro e trata variáveis não definidas
set -e
set -u

# Verifica se o comando 'code' existe
if ! command -v code >/dev/null 2>&1; then
  echo "❌ Erro: o comando 'code' (VS Code) não está disponível no PATH."
  echo "👉 No VS Code: 'Shell Command: Install code command in PATH'"
  exit 1
fi

# ==============================
# LISTA DE WORKSPACES
# ==============================

typeset -A WORKSPACES=(
  notes  "$HOME/repo/github/jeannandrade.github.io/jeannandrade.github.io.code-workspace"
  scripts  "$HOME/bin/myscripts.code-workspace"
  blazor  "$HOME/repo/github/Learning-Blazor/Learning-Blazor.code-workspace"
  zshrc  "$HOME/.zshrc"
)

# ==============================
# GERAR MENU NUMERADO
# ==============================

# Array auxiliar para manter a ordem do menu
IDS=(${(k)WORKSPACES})

echo "📂 Workspaces disponíveis:"
echo "--------------------------"

i=1
for id in $IDS; do
  echo " $i) $id"
  ((i++))
done

echo
read "?👉 Digite o número do workspace que deseja abrir: " OPCAO

# ==============================
# VALIDAÇÃO DA OPÇÃO
# ==============================

if [[ ! "$OPCAO" =~ '^[0-9]+$' ]]; then
  echo "❌ Erro: digite apenas números."
  exit 1
fi

if (( OPCAO < 1 || OPCAO > ${#IDS[@]} )); then
  echo "❌ Erro: opção inválida."
  exit 1
fi

# Ajuste de índice (menu começa em 1)
SELECIONADO_ID="${IDS[$((OPCAO - 1))]}"
WORKSPACE_PATH="${WORKSPACES[$SELECIONADO_ID]}"

if [[ ! -d "$WORKSPACE_PATH" ]]; then
  echo "❌ Erro: o caminho '$WORKSPACE_PATH' não existe."
  exit 1
fi

# ==============================
# ABRIR VS CODE
# ==============================

echo "🚀 Abrindo workspace '$SELECIONADO_ID'..."
code "$WORKSPACE_PATH"
