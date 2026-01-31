#!/usr/bin/env zsh
set -e
set -u

# Verifica se o dotnet está disponível
if ! command -v dotnet >/dev/null 2>&1; then
  echo "❌ Erro: dotnet CLI não encontrado."
  exit 1
fi

echo "▶ Buscando pacotes desatualizados..."
echo ""

projeto=""
comandos=()

# Captura stdout + stderr
dotnet list package --outdated 2>&1 | while IFS= read -r linha; do
  # Remove espaços à esquerda
  linha=$(echo "$linha" | sed 's/^[[:space:]]*//')

  # Detecta projeto
  if [[ "$linha" == Project* ]]; then
    projeto=$(echo "$linha" | sed -E "s/Project \`(.+)\`.*/\1/")
  fi

  # Detecta package desatualizado
  if [[ "$linha" == ">"* ]]; then
    linha_limpa="${linha#> }"

    pacote=$(echo "$linha_limpa" | awk '{print $1}')
    versao_latest=$(echo "$linha_limpa" | awk '{print $NF}')

    comandos+=("dotnet add \"$projeto\" package \"$pacote\" --version $versao_latest")
  fi
done

# Se não houver comandos, sair
if [[ ${#comandos[@]} -eq 0 ]]; then
  echo "✅ Nenhum pacote desatualizado encontrado."
  exit 0
fi

echo "📦 Os seguintes comandos serão executados:"
echo ""

for cmd in "${comandos[@]}"; do
  echo "  $cmd"
done

echo ""
read "resposta?Deseja executar esses comandos agora? (s/N): "

if [[ "$resposta" != "s" && "$resposta" != "S" ]]; then
  echo "❌ Operação cancelada pelo usuário."
  exit 0
fi

echo ""
echo "🚀 Executando atualizações..."
echo ""

for cmd in "${comandos[@]}"; do
  echo "▶ $cmd"
  eval "$cmd"
done

echo ""
echo "✅ Atualização de pacotes concluída com sucesso."

dotnet restore
dotnet build

