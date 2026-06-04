#!/usr/bin/env zsh

clear

# Verifica se o dotnet está disponível
if ! command -v dotnet &>/dev/null; then
  echo "${RED}Erro:${NC} O comando 'dotnet' não foi encontrado."
  echo "Instale o .NET SDK em: https://dotnet.microsoft.com/download"
  exit 1
fi

echo "${CYAN}dotnet SDK encontrado:${NC} $(dotnet --version)"

# Busca por arquivos .csproj na pasta atual e subpastas
projects=()
while IFS= read -r -d $'\0' file; do
  projects+=("$file")
done < <(find . -type f -name '*.csproj' -print0)

n=${#projects[@]}

if [ "$n" -eq 0 ]; then
  echo "Nenhum arquivo .csproj encontrado neste diretório."
  exit $?
elif [ "$n" -eq 1 ]; then
  proj="${projects[1]}"
  echo "Encontrado 1 projeto: $proj"
  dotnet run --project "$proj"
  exit $?
else
  echo "Foram encontrados $n projetos:"
  i=1
  for proj in "${projects[@]}"; do
    printf "%3d) %s\n" "$i" "$proj"
    i=$((i+1))
  done

  while true; do
    printf "Escolha o número do projeto: "
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      if [ "$choice" -ge 1 ] && [ "$choice" -le "$n" ]; then
        break
      fi
    fi
    echo "Entrada inválida. Tente novamente."
  done

  selected="${projects[$choice]}"
  echo "Executando projeto: $selected"
  dotnet run --project "$selected"
  exit $?
fi