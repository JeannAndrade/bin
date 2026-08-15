#!/usr/bin/env zsh

# ---------------------------------
# Nome: ubuntu-update-system.zsh
# Versão: 1.0
# Autor: Jeann Andrade
# Descrição: Atualiza os pacotes do sistema Ubuntu/Debian
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

# ==============================
# ATUALIZAÇÃO DO SISTEMA
# ==============================

section_title "Atualização do Sistema"

info "Atualizando lista de pacotes (apt update)..."
if sudo apt update; then
  success "Lista de pacotes atualizada com sucesso!"
else
  err "Falha ao atualizar a lista de pacotes."
  exit 1
fi

echo

info "Atualizando pacotes instalados (apt upgrade)..."
if sudo apt upgrade -y; then
  success "Pacotes atualizados com sucesso!"
else
  err "Falha ao atualizar os pacotes."
  exit 1
fi

echo

info "Removendo pacotes desnecessários (apt autoremove)..."
if sudo apt autoremove -y; then
  success "Limpeza concluída com sucesso!"
else
  warn "Não foi possível remover todos os pacotes desnecessários."
fi

echo
success "Processo de atualização finalizado!"
echo