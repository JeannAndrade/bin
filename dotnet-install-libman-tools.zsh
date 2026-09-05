#!/usr/bin/env zsh
#
# dotnet-install-libman-tools.zsh
# Instala ou atualiza a Microsoft.Web.LibraryManager.Cli (libman) como
# global tool do .NET, de forma idempotente.
#
# Comportamento padrão: SEM argumento, sempre resolve a versão mais
# recente disponível no feed do NuGet (equivalente a omitir --version
# em 'dotnet tool install/update').
#
# Uso:
#   ./dotnet-install-libman-tools.zsh              # instala/atualiza para a última versão do feed
#   ./dotnet-install-libman-tools.zsh 2.1.175      # fixa uma versão específica (opt-in explícito)

set -euo pipefail

readonly TOOL_ID="Microsoft.Web.LibraryManager.Cli"
readonly TOOL_CMD="libman"
readonly REQUESTED_VERSION="${1:-latest}"

log() { print -P "%F{cyan}[libman-setup]%f $1"; }
err() { print -P "%F{red}[libman-setup] ERRO:%f $1" >&2; }

if ! command -v dotnet >/dev/null 2>&1; then
  err "SDK do .NET não encontrado no PATH. Instale o SDK antes de continuar."
  exit 1
fi

# dotnet tool list --global emite uma tabela texto (sem --format json
# antes do SDK 8, e mesmo com json o parsing muda entre versões), então
# grep -i no nome do pacote é o jeito mais estável de checar presença.
is_installed() {
  dotnet tool list --global 2>/dev/null | grep -qi "$TOOL_ID"
}

installed_version() {
  dotnet tool list --global 2>/dev/null \
    | awk -v pkg="${TOOL_ID:l}" '{ if (tolower($1) == pkg) print $2 }'
}

version_args=()
if [[ "$REQUESTED_VERSION" != "latest" ]]; then
  version_args=(--version "$REQUESTED_VERSION")
fi

if is_installed; then
  current="$(installed_version)"
  log "Encontrada versão atual: ${current:-desconhecida}"

  if [[ "$REQUESTED_VERSION" != "latest" && "$current" == "$REQUESTED_VERSION" ]]; then
    log "Já está na versão solicitada ($REQUESTED_VERSION). Nada a fazer."
  else
    log "Atualizando ${TOOL_ID} ${version_args:+para $REQUESTED_VERSION}..."
    dotnet tool update --global "$TOOL_ID" "${version_args[@]}"
  fi
else
  log "Tool não encontrada. Instalando ${TOOL_ID} ${version_args:+versão $REQUESTED_VERSION}..."
  dotnet tool install --global "$TOOL_ID" "${version_args[@]}"
fi

log "Verificando shim e binário resultante..."
if command -v "$TOOL_CMD" >/dev/null 2>&1; then
  "$TOOL_CMD" --version
else
  err "'$TOOL_CMD' não está no PATH. Verifique se \$HOME/.dotnet/tools está no seu PATH."
  err "Adicione ao ~/.zshrc: export PATH=\"\$PATH:\$HOME/.dotnet/tools\""
  exit 1
fi

log "Concluído."