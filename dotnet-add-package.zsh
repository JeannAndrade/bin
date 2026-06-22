#!/usr/bin/env zsh

clear

# Carrega as bibliotecas
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
section_title "Adicionando Pacote NuGet ao Projeto .NET"
check_dotnet

# ---------------------------------------------------------------------------
# Validação dos parâmetros
# ---------------------------------------------------------------------------
if [[ $# -lt 2 ]]; then
  err "Uso: $0 <nome_projeto> <nome_package> [versao]"
  echo
  echo "  <nome_projeto>   - Nome do projeto que receberá o pacote"
  echo "  <nome_package>   - Nome do pacote NuGet a ser adicionado"
  echo "  [versao]         - (Opcional) Versão específica do pacote"
  echo
  echo "Exemplos:"
  echo "  $0 MyApp Newtonsoft.Json"
  echo "  $0 MyApp Serilog 3.1.1"
  echo "  $0 src/MyApp/MyApp.csproj Serilog.AspNetCore 8.0.0"
  exit 1
fi

nome_projeto="$1"
nome_package="$2"
versao="${3:-}"

info "Projeto destino: ${BOLD}$nome_projeto${NC}"
info "Pacote: ${BOLD}$nome_package${NC}"
if [[ -n "$versao" ]]; then
  info "Versão: ${BOLD}$versao${NC}"
else
  info "Versão: ${BOLD}(última estável)${NC}"
fi

# ---------------------------------------------------------------------------
# Localização do projeto usando find_csproj_by_name
# ---------------------------------------------------------------------------
echo ""
info "Localizando projeto..."

# Remove extensão .csproj se existir para usar como nome
nome_projeto_sem_extensao="${nome_projeto%.csproj}"

# Encontra o projeto
path_projeto=$(find_csproj_by_name "$nome_projeto_sem_extensao")
if [[ $? -ne 0 ]]; then
  exit 1
fi

echo ""
print_field "Projeto encontrado" "$path_projeto"

# ---------------------------------------------------------------------------
# Verifica se o pacote já está instalado
# ---------------------------------------------------------------------------
echo ""
info "Verificando se o pacote '$nome_package' já está instalado..."

# Busca por PackageReference no .csproj
if grep -q "<PackageReference Include=\"$nome_package\"" "$path_projeto" 2>/dev/null; then
  # Tenta extrair a versão atual se existir
  versao_atual=$(grep -o "<PackageReference Include=\"$nome_package\" Version=\"[^\"]*\"" "$path_projeto" 2>/dev/null | grep -o 'Version="[^"]*"' | cut -d'"' -f2 || true)

  if [[ -n "$versao_atual" ]]; then
    warn "O pacote '$nome_package' já está instalado no projeto com a versão $versao_atual."
  else
    warn "O pacote '$nome_package' já está instalado no projeto."
  fi

  echo ""
  read "confirm?Deseja adicionar/atualizar mesmo assim? (s/N) "
  if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    info "Operação cancelada."
    exit 0
  fi
else
  success "Pacote não encontrado no projeto."
fi

# ---------------------------------------------------------------------------
# Montagem do comando
# ---------------------------------------------------------------------------
echo ""

# Monta o comando base
cmd="dotnet add \"$path_projeto\" package \"$nome_package\""

# Adiciona a versão se fornecida
if [[ -n "$versao" ]]; then
  cmd="$cmd --version $versao"
fi

info "Comando a ser executado:"
echo "  $cmd"
echo ""

# Confirmação antes de executar
read "confirm?Confirmar execução? (S/n) "
if [[ "$confirm" =~ ^[Nn]$ ]]; then
  info "Operação cancelada."
  exit 0
fi

# ---------------------------------------------------------------------------
# Execução do comando
# ---------------------------------------------------------------------------
echo ""
info "Executando comando..."

if eval "$cmd"; then
  echo ""
  success "✅ Pacote adicionado com sucesso!"
  echo ""
  print_field "Projeto" "$(basename "$path_projeto")"
  print_field "Pacote" "$nome_package"
  if [[ -n "$versao" ]]; then
    print_field "Versão" "$versao"
  else
    print_field "Versão" "Última estável"
  fi
else
  err "Falha ao adicionar o pacote '$nome_package'."
  exit 1
fi