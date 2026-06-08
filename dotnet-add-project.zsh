#!/usr/bin/env zsh

# Sai imediatamente se algum comando falhar e trata variáveis não definidas como erro
set -euo pipefail
clear

lib="$(dirname "$0")/shared-style.zsh"
if [[ ! -f "$lib" ]]; then
  echo "Erro: arquivo de biblioteca '$lib' não encontrado." >&2
  exit 1
fi
source "$lib"

# ---------------------------------------------------------------------------
# Validação: dotnet disponível
# ---------------------------------------------------------------------------
if ! command -v dotnet &>/dev/null; then
  err "O comando 'dotnet' não foi encontrado."
  info "Instale o .NET SDK em: https://dotnet.microsoft.com/download"
  exit 1
fi

info "dotnet SDK encontrado: $(dotnet --version)"

# ---------------------------------------------------------------------------
# Validação: arquivo .slnx na pasta atual
# ---------------------------------------------------------------------------
slnx_files=(*.slnx(N))

if [ ${#slnx_files[@]} -eq 0 ]; then
  err "Nenhum arquivo .slnx encontrado na pasta atual."
  info "Execute este script na raiz de uma solution .NET."
  exit 1
fi

if [ ${#slnx_files[@]} -gt 1 ]; then
  err "Mais de um arquivo .slnx encontrado na pasta atual:"
  for f in "${slnx_files[@]}"; do
    echo "  - $f"
  done
  info "Certifique-se de que existe apenas uma solution neste diretório."
  exit 1
fi

nome_solucao="${slnx_files[1]}"
info "Solution encontrada: $nome_solucao"

# ---------------------------------------------------------------------------
# Validação: global.json e detecção do framework
# ---------------------------------------------------------------------------
if [ ! -f global.json ]; then
  err "Arquivo global.json não encontrado na pasta atual."
  info "O global.json é necessário para identificar a versão do framework."
  exit 1
fi

sdk_version=$(grep -oE '"version"\s*:\s*"[^"]+"' global.json | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

if [ -z "$sdk_version" ]; then
  err "Não foi possível extrair a versão do SDK do global.json."
  info "Verifique se o arquivo possui o campo: { \"sdk\": { \"version\": \"x.y.z\" } }"
  exit 1
fi

major_version=$(echo "$sdk_version" | cut -d. -f1)
framework="net${major_version}.0"

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