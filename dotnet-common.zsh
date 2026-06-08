# Este arquivo não é executável diretamente.
# Carregue-o via: source "$(dirname "$0")/dotnet-common.zsh"

# Verifica se um comando está disponível no PATH
require_command() {
  local cmd="$1"
  local msg="${2:-o comando '$cmd' não está disponível no PATH.}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "$msg"
    exit 1
  fi
}

# Verifica especificamente o dotnet e exibe versão
check_dotnet() {
  require_command dotnet "O comando 'dotnet' não foi encontrado."
  info "dotnet SDK encontrado: $(dotnet --version)"
}

# Obtém a versão do SDK (ou falha)
get_sdk_version() {
  local v
  v=$(dotnet --version 2>/dev/null || true)
  if [[ -z "$v" ]]; then
    err "Não foi possível identificar a versão do SDK."
    exit 1
  fi
  printf "%s" "$v"
}

# Retorna o framework a partir da versão do SDK
# modo: "major_minor" (ex: net10.0) ou "major_zero" (ex: net10.0)
framework_from_sdk() {
  local sdk="$1"
  local mode="${2:-major_minor}"
  local major minor
  major=${sdk%%.*}
  minor=$(echo "$sdk" | cut -d'.' -f2 2>/dev/null || true)
  if [[ -z "$minor" ]]; then
    minor=0
  fi
  if [[ "$mode" == "major_zero" ]]; then
    printf "net%s.0" "$major"
  else
    printf "net%s.%s" "$major" "$minor"
  fi
}

# Valida que um valor não esteja vazio; imprime mensagem e sai se estiver
require_non_empty() {
  local val="$1"
  local msg="$2"
  if [[ -z "${val:-}" ]]; then
    err "$msg"
    exit 1
  fi
}

# Verifica existência de arquivo
require_file() {
  local f="$1"
  local msg="${2:-Arquivo '$f' não encontrado.}"
  if [[ ! -f "$f" ]]; then
    err "$msg"
    exit 1
  fi
}

# Verifica existência de diretório
require_dir() {
  local d="$1"
  local msg="${2:-Diretório '$d' não encontrado.}"
  if [[ ! -d "$d" ]]; then
    err "$msg"
    exit 1
  fi
}

# Garante que exista exatamente um arquivo para um glob (ex: *.slnx)
# Imprime o caminho do arquivo encontrado
require_single_glob() {
  local pattern="$1"
  local msg_zero="$2"
  local msg_many="$3"
  local files
  files=( $pattern(N) )
  if [[ ${#files[@]} -eq 0 ]]; then
    err "${msg_zero:-Nenhum arquivo encontrado para padrão: $pattern}"
    exit 1
  fi
  if [[ ${#files[@]} -gt 1 ]]; then
    err "${msg_many:-Mais de um arquivo encontrado para padrão: $pattern}"
    for f in "${files[@]}"; do
      echo "  - $f"
    done
    exit 1
  fi
  printf "%s" "${files[1]}"
}

# Procura por um .csproj com nome exato e retorna o caminho (ou falha)
find_csproj_by_name() {
  local name="$1"
  local res
  res=$(find . -type f -name "${name}.csproj" 2>/dev/null | head -n 1 || true)
  if [[ -z "$res" ]]; then
    err "Arquivo '${name}.csproj' não encontrado."
    exit 1
  fi
  printf "%s" "$res"
}

# Retorna o .nupkg mais recente (exclui .symbols.nupkg)
find_latest_nupkg() {
  local res
  res=$(find nupkgs -maxdepth 1 -type f -name "*.nupkg" ! -name "*.symbols.nupkg" -print0 | xargs -0 ls -t 2>/dev/null | head -n 1 || true)
  if [[ -z "$res" ]]; then
    err "Nenhum arquivo .nupkg encontrado em ./nupkgs"
    exit 1
  fi
  printf "%s" "$res"
}

# Extrai versão do SDK de um global.json
extract_sdk_from_global_json() {
  local file="${1:-global.json}"
  if [[ ! -f "$file" ]]; then
    err "Arquivo $file não encontrado."
    exit 1
  fi
  local sdk
  sdk=$(grep -oE '"version"\s*:\s*"[^"]+"' "$file" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
  if [[ -z "$sdk" ]]; then
    err "Não foi possível extrair a versão do SDK do $file."
    exit 1
  fi
  printf "%s" "$sdk"
}

# Valida se uma entrada numérica está dentro do intervalo
is_valid_numeric_choice() {
  local val="$1"; local min="$2"; local max="$3"
  if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge "$min" ] && [ "$val" -le "$max" ]; then
    return 0
  fi
  return 1
}