#!/usr/bin/env zsh

# ---------------------------------
# Nome: abrir-workspace-vscode.zsh
# Versão: 2.2
# Autor: Jeann Andrade
# Descrição: Abre workspaces do VS Code via menu numerado
# ---------------------------------

set -e
set -u

# Verifica se o comando 'code' existe
if ! command -v code >/dev/null 2>&1; then
  echo "❌ Erro: o comando 'code' não está disponível no PATH."
  exit 1
fi

# ==============================
# ORDEM DO MENU (ARRAY ZSH → 1-based)
# ==============================

IDS=(
  JeannandradeGithub
  myscripts
  Vault
  LearningBlazor
  LearningCSharp
  LumiaFoundation
  zshrc
)

# ==============================
# MAPA ID -> WORKSPACE
# ==============================

typeset -A WORKSPACES=(
  JeannandradeGithub "$HOME/repo/github/jeannandrade.github.io/jeannandrade.github.io.code-workspace"
  myscripts "$HOME/bin/myscripts.code-workspace"
  Vault "$HOME/repo/github/Vault/Vault.code-workspace"
  LearningBlazor "$HOME/repo/github/Learning-Blazor/Learning-Blazor.code-workspace"
  LearningCSharp "$HOME/repo/github/Learning-CSharp/Learning-CSharp.code-workspace"
  LumiaFoundation "$HOME/repo/github/Lumia.Foundation/Lumia.Foundation.code-workspace"
  zshrc "$HOME/.zshrc"
)

# ==============================
# MENU NUMERADO
# ==============================

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
# VALIDAÇÃO
# ==============================

if [[ ! "$OPCAO" =~ '^[0-9]+$' ]]; then
  echo "❌ Erro: digite apenas números."
  exit 1
fi

if (( OPCAO < 1 || OPCAO > ${#IDS[@]} )); then
  echo "❌ Erro: opção inválida."
  exit 1
fi

# ✅ CORREÇÃO AQUI (SEM -1)
SELECIONADO_ID="${IDS[$OPCAO]}"
WORKSPACE_PATH="${WORKSPACES[$SELECIONADO_ID]}"

if [[ ! -e "$WORKSPACE_PATH" ]]; then
  echo "❌ Erro: o path '$WORKSPACE_PATH' não existe."
  exit 1
fi

# ==============================
# ABRIR VS CODE
# ==============================

echo "🚀 Abrindo workspace '$SELECIONADO_ID'..."
code "$WORKSPACE_PATH"
