#!/usr/bin/env zsh

# Converte uma solução .sln clássica para o novo formato .slnx
# Execute diretamente ou carregue via: source "$(dirname "$0")/dotnet-convert-sln.zsh"

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
  err "Arquivo de biblioteca '$common_lib' não encontrado."
  exit 1
fi
source "$common_lib"

# Verifica se o dotnet está disponível
check_dotnet

section_title "Conversão de solução .sln -> .slnx"

info "Procurando arquivo .sln na pasta atual..."

# require_single_glob vai falhar e encerrar se não encontrar exatamente um arquivo
sln_file=$(require_single_glob "*.sln" "Nenhuma solução .sln encontrada." "Mais de uma solução .sln encontrada.")

info "Solução encontrada: ${sln_file}"

# Variáveis explícitas para arquivo antigo (.sln) e novo (.slnx)
slnx_file="${sln_file%.sln}.slnx"

info "Executando conversão com 'dotnet sln migrate ${sln_file}'"

if dotnet sln migrate "$sln_file"; then
  if [[ -f "$slnx_file" ]]; then
    success "Conversão concluída com sucesso. Arquivo gerado: ${slnx_file}"
    info "Removendo solução antiga: ${sln_file}"
    if rm -f -- "$sln_file"; then
      success "Arquivo antigo removido: ${sln_file}"
    else
      warn "Falha ao remover ${sln_file}. Remova manualmente para evitar conflito."
    fi
  else
    success "Comando concluído. Verifique a saída do dotnet para confirmar o novo arquivo .slnx. A solução antiga não foi removida."
  fi
else
  err "Falha ao executar a conversão para ${sln_file}"
  exit 1
fi

exit 0
