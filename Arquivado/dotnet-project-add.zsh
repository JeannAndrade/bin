#!/usr/bin/env zsh

# =============================================================================
# Script:   dotnet-add-project.zsh
# Autor:    Jeann Andrade
# Criado:   2026-07-11
#
# Descrição:
#   Adiciona um novo projeto .NET (web, webapi, classlib, console ou xunit) na
#   pasta atual, detectando o framework alvo a partir do SDK definido em
#   "global.json", e o adiciona automaticamente à solution (.slnx)
#   encontrada na pasta. Projetos "web" e "webapi" são criados com a flag
#   --no-https.
#
# Uso:
#   ./dotnet-add-project.zsh
#
#   O script é interativo: solicita o tipo de projeto (via menu numerado)
#   e o nome do projeto.
#
# Pré-requisitos:
#   - Um único arquivo .slnx na pasta atual.
#   - Um arquivo global.json na pasta atual, com o SDK definido.
#
# =============================================================================

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

nome_solucao=$(require_single_glob "*.slnx" \
  "Nenhum arquivo .slnx encontrado na pasta atual." \
  "Mais de um arquivo .slnx encontrado na pasta atual:")
info "Solution encontrada: $nome_solucao"

require_file global.json "Arquivo global.json não encontrado na pasta atual."
sdk_version=$(extract_sdk_from_global_json global.json)
framework=$(framework_from_sdk "$sdk_version" "major_zero")

info "Framework detectado: $framework (SDK $sdk_version)"

# ---------------------------------------------------------------------------
# Seleção do tipo de projeto (menu interativo)
# ---------------------------------------------------------------------------
tipos_projeto=(web webapi classlib console xunit)

echo ""
echo "Tipos de projeto disponíveis:"
i=1
for tipo in "${tipos_projeto[@]}"; do
  printf "%3d) %s\n" "$i" "$tipo"
  i=$((i+1))
done

while true; do
  printf "Escolha o número do tipo de projeto: "
  read -r escolha_tipo
  if [[ "$escolha_tipo" =~ ^[0-9]+$ ]]; then
    if [ "$escolha_tipo" -ge 1 ] && [ "$escolha_tipo" -le "${#tipos_projeto[@]}" ]; then
      break
    fi
  fi
  warn "Entrada inválida. Tente novamente."
done

tipo_projeto="${tipos_projeto[$escolha_tipo]}"
info "Tipo selecionado: $tipo_projeto"

# ---------------------------------------------------------------------------
# Nome do projeto (com validação)
# ---------------------------------------------------------------------------
echo ""
while true; do
  printf "Nome do projeto: "
  read -r nome_projeto

  if [ -z "$nome_projeto" ]; then
    warn "O nome não pode ser vazio."
    continue
  fi

  if [[ ! "$nome_projeto" =~ ^[a-zA-Z][a-zA-Z0-9._-]*$ ]]; then
    warn "Use apenas letras, números, '.', '_' ou '-', iniciando com uma letra."
    continue
  fi

  break
done

info "Nome do projeto: $nome_projeto"

# ---------------------------------------------------------------------------
# Montagem e execução dos comandos
# ---------------------------------------------------------------------------
echo ""

# Flag --no-https apenas para web e webapi
if [[ "$tipo_projeto" == "web" || "$tipo_projeto" == "webapi" ]]; then
  cmd_new="dotnet new $tipo_projeto --no-https --output $nome_projeto --framework $framework"
else
  cmd_new="dotnet new $tipo_projeto --output $nome_projeto --framework $framework"
fi

cmd_sln="dotnet sln $nome_solucao add $nome_projeto"

info "Os seguintes comandos serão executados:"
echo "  1) $cmd_new"
echo "  2) $cmd_sln"
echo ""

# Criação do projeto
info "Criando projeto..."
if ! eval "$cmd_new"; then
  err "Falha ao criar o projeto '$nome_projeto'."
  exit 1
fi

# Adição à solution
echo ""
info "Adicionando projeto à solution..."
if ! eval "$cmd_sln"; then
  err "Falha ao adicionar o projeto '$nome_projeto' à solution '$nome_solucao'."
  exit 1
fi

echo ""
success "Projeto '$nome_projeto' criado e adicionado à solution '$nome_solucao'."