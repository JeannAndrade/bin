clear

# Verifica se o dotnet está disponível
if ! command -v dotnet &>/dev/null; then
  echo "${RED}Erro:${NC} O comando 'dotnet' não foi encontrado."
  echo "Instale o .NET SDK em: https://dotnet.microsoft.com/download"
  exit 1
fi

echo "${CYAN}dotnet SDK encontrado:${NC} $(dotnet --version)"

dotnet run