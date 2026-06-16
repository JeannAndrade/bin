#!/usr/bin/env zsh

# ---------------------------------
# Nome: ubuntu-version.zsh
# Versão: 1.0
# Autor: Jeann Andrade
# Descrição: Exibe informações completas do sistema Ubuntu
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
# COLETA DE INFORMAÇÕES
# ==============================

os_name=$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
os_version=$(lsb_release -rs 2>/dev/null || grep VERSION_ID /etc/os-release | cut -d= -f2 | tr -d '"')
os_codename=$(lsb_release -cs 2>/dev/null || echo "desconhecido")
kernel=$(uname -r)
architecture=$(uname -m)
hostname=$(hostname)
uptime_info=$(uptime -p 2>/dev/null || uptime)

# ==============================
# EXIBIÇÃO
# ==============================

section_title "Informações do Sistema"
print_field "Sistema"       "$os_name"
print_field "Versão"        "$os_version"
print_field "Codinome"      "$os_codename"
print_field "Kernel"        "$kernel"
print_field "Arquitetura"   "$architecture"
print_field "Hostname"      "$hostname"
print_field "Uptime"        "$uptime_info"
echo