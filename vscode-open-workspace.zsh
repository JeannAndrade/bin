#!/usr/bin/env zsh

# ---------------------------------
# Nome: abrir-workspace-vscode.zsh
# Versão: 2.2
# Autor: Jeann Andrade
# Descrição: Abre workspaces do VS Code via menu numerado
# ---------------------------------

# Sai imediatamente se algum comando falhar e trata variáveis não definidas como erro
set -euo pipefail
clear

lib="$(dirname "$0")/shared-style.zsh"
if [[ ! -f "$lib" ]]; then
  echo "Erro: arquivo de biblioteca '$lib' não encontrado." >&2
  exit 1
fi
source "$lib"

common_lib="$(dirname "$0")/dotnet-common.zsh"
if [[ ! -f "$common_lib" ]]; then
  echo "Erro: arquivo de biblioteca '$common_lib' não encontrado." >&2
  exit 1
fi
source "$common_lib"

# Verifica se o comando 'code' existe
require_command code "o comando 'code' não está disponível no PATH."

# ==============================
# ORDEM DO MENU (ARRAY ZSH → 1-based)
# ==============================

IDS=(
  JeannandradeGithub
  LearningBlazor
  LearningCSharp
  LumiaFoundation
  myscripts
  MelhorPrecoCerveja
  Vault
  zshrc
)

# ==============================
# MAPA ID -> WORKSPACE
# ==============================

typeset -A WORKSPACES=(
  [JeannandradeGithub]="$HOME/repo/github/jeannandrade.github.io/jeannandrade.github.io.code-workspace"
  [myscripts]="$HOME/bin/myscripts.code-workspace"
  [Vault]="$HOME/repo/github/Vault/Vault.code-workspace"
  [LearningBlazor]="$HOME/repo/github/Learning-Blazor/Learning-Blazor.code-workspace"
  [LearningCSharp]="$HOME/repo/github/Learning-CSharp/Learning-CSharp.code-workspace"
  [LumiaFoundation]="$HOME/repo/github/Lumia.Foundation/Lumia.Foundation.code-workspace"
  [MelhorPrecoCerveja]="$HOME/repo/github/MelhorPrecoCerveja/MelhorPrecoCerveja.code-workspace"
  [zshrc]="$HOME/.zshrc"
)

# ==============================
# MENU NUMERADO
# ==============================

info "Workspaces disponíveis:"
info "--------------------------"

i=1
for id in "${IDS[@]}"; do
  echo " $i) $id"
  ((i++))
done

echo
printf "Digite o número do workspace que deseja abrir: "
read -r OPCAO

# ==============================
# VALIDAÇÃO
# ==============================

if [[ ! "$OPCAO" =~ ^[0-9]+$ ]]; then
  err "Digite apenas números."
  exit 1
fi

if (( OPCAO < 1 || OPCAO > ${#IDS[@]} )); then
  err "Opção inválida."
  exit 1
fi

# CORREÇÃO AQUI (SEM -1)
SELECIONADO_ID="${IDS[$OPCAO]}"
WORKSPACE_PATH="${WORKSPACES[$SELECIONADO_ID]}"

if [[ ! -e "$WORKSPACE_PATH" ]]; then
  err "O path '$WORKSPACE_PATH' não existe."
  exit 1
fi

# ==============================
# ABRIR VS CODE
# ==============================

info "Abrindo workspace '$SELECIONADO_ID'..."
code "$WORKSPACE_PATH"
