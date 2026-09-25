#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Instala ou atualiza a Microsoft.Web.LibraryManager.Cli (libman) como
    global tool do .NET, de forma idempotente.

.DESCRIPTION
    Equivalente PowerShell de dotnet-libman-tools-install.zsh (antigo
    dotnet-install-libman-tools.zsh).

    Comportamento padrão: SEM argumento, sempre resolve a versão mais
    recente disponível no feed do NuGet (equivalente a omitir --version
    em 'dotnet tool install/update').

.PARAMETER RequestedVersion
    Versão específica a instalar/fixar. Se omitida, usa sempre a mais
    recente disponível no feed ("latest").

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.1 (convertido de dotnet-libman-tools-install.zsh)

    Diferente da primeira versão desta conversão, este script agora usa
    SharedStyle.psm1 e DotnetCommon.psm1 em vez de funções de log
    próprias — mesmo padrão dos demais scripts da coleção.

    Depende de Test-DotnetToolInstalled e Get-InstalledDotnetToolVersion
    em DotnetCommon.psm1.

.EXAMPLE
    ./dotnet-libman-tools-install.ps1

.EXAMPLE
    ./dotnet-libman-tools-install.ps1 2.1.175
#>

param(
  [Parameter(Position = 0)]
  [string]$RequestedVersion = 'latest'
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Carrega módulos compartilhados
# ---------------------------------------------------------------------------
$scriptDir = $PSScriptRoot

$styleModule = Join-Path $scriptDir 'SharedStyle.psm1'
if (-not (Test-Path $styleModule)) {
  Write-Host "Erro: arquivo de biblioteca '$styleModule' não encontrado." -ForegroundColor Red
  exit 1
}
Import-Module $styleModule -Force

$commonModule = Join-Path $scriptDir 'DotnetCommon.psm1'
if (-not (Test-Path $commonModule)) {
  Write-ErrMessage "Arquivo de biblioteca '$commonModule' não encontrado."
  exit 1
}
Import-Module $commonModule -Force

# ---------------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------------
$ToolId = 'Microsoft.Web.LibraryManager.Cli'
$ToolCmd = 'libman'

# ---------------------------------------------------------------------------
# Validação: dotnet disponível
# ---------------------------------------------------------------------------
Assert-DotnetCli

$versionArgs = @()
if ($RequestedVersion -ne 'latest') {
  $versionArgs = @('--version', $RequestedVersion)
}

if (Test-DotnetToolInstalled -ToolId $ToolId) {
  $current = Get-InstalledDotnetToolVersion -ToolId $ToolId
  $currentLabel = if ($current) { $current } else { 'desconhecida' }
  Write-InfoMessage "Encontrada versão atual: $currentLabel"

  if ($RequestedVersion -ne 'latest' -and $current -eq $RequestedVersion) {
    Write-InfoMessage "Já está na versão solicitada ($RequestedVersion). Nada a fazer."
  }
  else {
    $suffix = if ($versionArgs.Count -gt 0) { " para $RequestedVersion" } else { '' }
    Write-InfoMessage "Atualizando ${ToolId}${suffix}..."
    dotnet tool update --global $ToolId @versionArgs
  }
}
else {
  $suffix = if ($versionArgs.Count -gt 0) { " versão $RequestedVersion" } else { '' }
  Write-InfoMessage "Tool não encontrada. Instalando ${ToolId}${suffix}..."
  dotnet tool install --global $ToolId @versionArgs
}

# ---------------------------------------------------------------------------
# Verificação final: shim e binário resultante
# ---------------------------------------------------------------------------
Write-InfoMessage "Verificando shim e binário resultante..."
Assert-CommandAvailable -Command $ToolCmd -Message "'$ToolCmd' não está no PATH. Verifique se `$HOME/.dotnet/tools está no seu PATH e no `$PROFILE do PowerShell."

& $ToolCmd --version

Write-SuccessMessage "Concluído."