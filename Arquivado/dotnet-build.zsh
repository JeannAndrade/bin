#!/usr/bin/env zsh
#
# Nome: dotnet-build.zsh
# Versão: 1.1.0
# Autor: Jeann Andrade
# Descrição: Compila a solução .NET do diretório atual com dotnet build e,
#            em seguida, executa os testes unitários de todos os projetos
#            da solução com dotnet test, usando o código de retorno dos
#            testes como ponto de verificação final da execução.
# Uso: ./dotnet-build.zsh
#
# Criado em: 2026-07-11

set -euo pipefail
clear

# ---------------------------------------------------------
# Carrega bibliotecas compartilhadas (style antes de common)
# ---------------------------------------------------------
SCRIPT_DIR="${0:A:h}"

if [[ -f "${SCRIPT_DIR}/shared-style.zsh" ]]; then
    source "${SCRIPT_DIR}/shared-style.zsh"
else
    echo "Erro: shared-style.zsh não encontrado em ${SCRIPT_DIR}" >&2
    exit 1
fi

if [[ -f "${SCRIPT_DIR}/dotnet-common.zsh" ]]; then
    source "${SCRIPT_DIR}/dotnet-common.zsh"
else
    echo "Erro: dotnet-common.zsh não encontrado em ${SCRIPT_DIR}" >&2
    exit 1
fi

# ---------------------------------------------------------
# 1. Validações iniciais
# ---------------------------------------------------------
section_title "1. Validações iniciais"

check_dotnet
require_command "dotnet"

print_field "Diretório" "$(pwd)"
print_field "Versão do SDK" "$(get_sdk_version)"

# ---------------------------------------------------------
# 2. Compilação (dotnet build)
# ---------------------------------------------------------
section_title "2. Compilação do projeto"

info "Executando dotnet build na solução do diretório atual"

BUILD_EXIT_CODE=0
dotnet build || BUILD_EXIT_CODE=$?

if [[ $BUILD_EXIT_CODE -ne 0 ]]; then
    err "A compilação falhou (código de saída: $BUILD_EXIT_CODE)."
    exit $BUILD_EXIT_CODE
fi

success "Compilação concluída com sucesso."

# ---------------------------------------------------------
# 3. Execução dos testes unitários (dotnet test)
# ---------------------------------------------------------
section_title "3. Execução dos testes unitários"

info "Executando dotnet test em todos os projetos da solução"

TEST_EXIT_CODE=0
dotnet test --no-build || TEST_EXIT_CODE=$?

if [[ $TEST_EXIT_CODE -ne 0 ]]; then
    err "Os testes falharam (código de saída: $TEST_EXIT_CODE)."
else
    success "Todos os testes passaram."
fi

# ---------------------------------------------------------
# 4. Resumo
# ---------------------------------------------------------
section_title "4. Resumo"

print_field "Diretório" "$(pwd)"
print_field "Build" "$([[ $BUILD_EXIT_CODE -eq 0 ]] && echo 'OK' || echo 'FALHOU')"
print_field "Testes" "$([[ $TEST_EXIT_CODE -eq 0 ]] && echo 'OK' || echo 'FALHOU')"
print_field "Código de saída final" "$TEST_EXIT_CODE"

exit $TEST_EXIT_CODE