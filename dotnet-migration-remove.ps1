#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Remove a última migration usando o Entity Framework Core Tools (dotnet-ef).

.DESCRIPTION
    Equivalente PowerShell de dotnet-migration-remove.zsh.

.PARAMETER Project
    Projeto onde a migration será removida (onde fica o DbContext).

.PARAMETER StartupProject
    Projeto de inicialização, usado para resolver a connection string.

.PARAMETER Context
    Nome do DbContext a ser usado, quando houver mais de um no projeto.

.PARAMETER Force
    Reverte a migration no banco de dados, se já tiver sido aplicada.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.1 (convertido de dotnet-migration-remove.zsh)

.EXAMPLE
    ./dotnet-migration-remove.ps1

.EXAMPLE
    ./dotnet-migration-remove.ps1 -Project src/Infra -StartupProject src/Api -Force
#>

param(
  [string]$Project,
  [string]$StartupProject,
  [string]$Context,
  [switch]$Force
)

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
# Validações iniciais
# ---------------------------------------------------------------------------
Assert-DotnetCli
Assert-CommandAvailable -Command 'dotnet-ef' -Message "o comando 'dotnet-ef' não está disponível. Instale com: dotnet tool install --global dotnet-ef"

# ==============================
# ETAPA 1 — REMOVER ÚLTIMA MIGRATION
# ==============================

$efArgs = @('migrations', 'remove')

if ($Project) { $efArgs += @('--project', $Project) }
if ($StartupProject) { $efArgs += @('--startup-project', $StartupProject) }
if ($Context) { $efArgs += @('--context', $Context) }
if ($Force) { $efArgs += '--force' }

Write-SectionTitle "Etapa 1 — Removendo a última migration"
Write-InfoMessage "Executando: dotnet ef $($efArgs -join ' ')"

dotnet ef @efArgs
if ($LASTEXITCODE -ne 0) {
  Write-ErrMessage "Falha ao remover a migration."
  Write-ErrMessage "Se ela já foi aplicada ao banco de dados, use a opção -Force."
  exit 1
}

Write-SuccessMessage "Migration removida com sucesso."

# ==============================
# RESUMO FINAL
# ==============================

Write-SectionTitle "Resumo"

Write-Field "Projeto"            $(if ($Project) { $Project } else { "(diretório atual)" })
Write-Field "Projeto de startup" $(if ($StartupProject) { $StartupProject } else { "(diretório atual)" })
Write-Field "DbContext"          $(if ($Context) { $Context } else { "(não especificado)" })
Write-Field "Force"              $(if ($Force) { "Sim" } else { "Não" })

Write-Host ''
Write-SuccessMessage "Operação concluída."