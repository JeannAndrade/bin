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
section_title "Adicionando Referência entre Projetos .NET"
check_dotnet

# ---------------------------------------------------------------------------
# Validação dos parâmetros
# ---------------------------------------------------------------------------
if [[ $# -ne 2 ]]; then
  err "Uso: $0 <projeto_referenciado> <projeto_destino>"
  echo
  echo "  <projeto_referenciado>  - Projeto que SERÁ REFERENCIADO (projA)"
  echo "  <projeto_destino>       - Projeto que RECEBERÁ a referência (projB)"
  echo
  echo "Exemplos:"
  echo "  $0 MyLibrary MyApp"
  echo "  $0 src/MyLibrary/MyLibrary.csproj src/MyApp/MyApp.csproj"
  echo "  $0 MyLibrary MyApp"
  exit 1
fi

projeto_referenciado="$1"
projeto_destino="$2"

info "Projeto que será referenciado (projA): ${BOLD}$projeto_referenciado${NC}"
info "Projeto que receberá a referência (projB): ${BOLD}$projeto_destino${NC}"

# ---------------------------------------------------------------------------
# Localização dos projetos usando find_csproj_by_name
# ---------------------------------------------------------------------------
echo ""
info "Localizando projetos..."

# Remove extensão .csproj se existir para usar como nome
nome_referenciado="${projeto_referenciado%.csproj}"
nome_destino="${projeto_destino%.csproj}"

# Encontra o projeto a ser referenciado
path_referenciado=$(find_csproj_by_name "$nome_referenciado")
if [[ $? -ne 0 ]]; then
  exit 1
fi

# Encontra o projeto destino
path_destino=$(find_csproj_by_name "$nome_destino")
if [[ $? -ne 0 ]]; then
  exit 1
fi

echo ""
print_field "Projeto referenciado (projA)" "$path_referenciado"
print_field "Projeto destino (projB)" "$path_destino"

# ---------------------------------------------------------------------------
# Validações
# ---------------------------------------------------------------------------
# Verifica se são o mesmo projeto
if [[ "$path_referenciado" == "$path_destino" ]]; then
  err "Não é possível adicionar referência de um projeto para ele mesmo."
  exit 1
fi

# Verifica se os arquivos existem (find_csproj_by_name já garante isso, mas vamos manter)
require_file "$path_referenciado" "Arquivo '$path_referenciado' não encontrado."
require_file "$path_destino" "Arquivo '$path_destino' não encontrado."

# Verifica se a referência já existe
echo ""
info "Verificando se a referência já existe no projeto destino..."

if grep -q "<ProjectReference Include=\"[^\"]*$(basename "$path_referenciado")\"" "$path_destino" 2>/dev/null; then
  warn "A referência para '$(basename "$path_referenciado")' já existe em '$(basename "$path_destino")'."
  echo ""
  read "confirm?Deseja adicionar mesmo assim? (s/N) "
  if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    info "Operação cancelada."
    exit 0
  fi
else
  success "Nenhuma referência existente encontrada."
fi

# ---------------------------------------------------------------------------
# Exibição do comando e execução
# ---------------------------------------------------------------------------
echo ""
cmd="dotnet reference add \"$path_referenciado\" --project \"$path_destino\""
info "Comando a ser executado:"
echo "  $cmd"
echo ""

# Confirmação antes de executar (opcional)
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
  success "✅ Referência adicionada com sucesso!"
  echo ""
  print_field "Projeto destino (projB)" "$(basename "$path_destino")"
  print_field "Referência adicionada" "$(basename "$path_referenciado")"
  print_field "Caminho" "$path_referenciado"
else
  err "Falha ao adicionar a referência."
  exit 1
fi