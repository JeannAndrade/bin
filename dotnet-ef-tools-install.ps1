#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Instala ou atualiza globalmente a ferramenta dotnet-ef.

.DESCRIPTION
    Equivalente PowerShell de dotnet-ef-tools-install.zsh.

    Instala globalmente a ferramenta dotnet-ef (Entity Framework Core
    Tools). Se já estiver instalada, atualiza para a versão mais recente.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.0 (convertido de dotnet-ef-tools-install.zsh, antigo
             dotnet-install-ef-tools.zsh)

    Depende de Test-DotnetToolInstalled e Get-InstalledDotnetToolVersion
    em DotnetCommon.psm1 (compartilhadas com dotnet-libman-tools-install.ps1).

.EXAMPLE
    ./dotnet-ef-tools-install.ps1
#>

$ErrorActionPreference = 'Stop'
Clear-Host

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
$toolName = 'dotnet-ef'

# ---------------------------------------------------------------------------
# Validações iniciais
# ---------------------------------------------------------------------------
Assert-DotnetCli

# ==============================
# ETAPA 1 — VERIFICAR SE JÁ ESTÁ INSTALADA
# ==============================

Write-SectionTitle "Etapa 1 — Verificando instalação existente"

if (Test-DotnetToolInstalled -ToolId $toolName) {
  $installedVersion = Get-InstalledDotnetToolVersion -ToolId $toolName
  Write-InfoMessage "'${toolName}' já está instalada globalmente (versão ${installedVersion})."
  Write-InfoMessage "Atualizando para a versão mais recente..."

  dotnet tool update --global $toolName
  if ($LASTEXITCODE -ne 0) {
    Write-ErrMessage "Falha ao atualizar '${toolName}'."
    exit 1
  }

  Write-SuccessMessage "'${toolName}' atualizada com sucesso."
}
else {
  # ==============================
  # ETAPA 2 — INSTALAR
  # ==============================

  Write-SectionTitle "Etapa 2 — Instalando ${toolName}"
  Write-InfoMessage "Executando: dotnet tool install --global ${toolName}"

  dotnet tool install --global $toolName
  if ($LASTEXITCODE -ne 0) {
    Write-ErrMessage "Falha ao instalar '${toolName}'."
    exit 1
  }

  Write-SuccessMessage "'${toolName}' instalada com sucesso."
}

# ==============================
# RESUMO FINAL
# ==============================

Write-SectionTitle "Resumo"

$efVersion = (dotnet ef --version 2>$null | Select-Object -Last 1)
if ([string]::IsNullOrWhiteSpace($efVersion)) {
  $efVersion = 'desconhecida'
}

Write-Field "Ferramenta" $toolName
Write-Field "Versão" $efVersion

Write-Host ''
Write-SuccessMessage "dotnet-ef pronta para uso."