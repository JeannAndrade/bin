#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Adiciona uma nova migration usando o Entity Framework Core Tools (dotnet-ef).

.DESCRIPTION
    Equivalente PowerShell de dotnet-add-migration.zsh.

    Diferente da versão zsh, aqui não existe um loop manual de parsing de
    argumentos (--project, --startup-project, --context): o bloco param()
    do PowerShell já cobre isso nativamente, incluindo a validação de que
    cada opção nomeada recebeu um valor.

.PARAMETER MigrationName
    Nome da migration a ser criada.

.PARAMETER Project
    Projeto onde a migration será criada (onde fica o DbContext).

.PARAMETER StartupProject
    Projeto de inicialização, usado para resolver a connection string.

.PARAMETER Context
    Nome do DbContext a ser usado, quando houver mais de um no projeto.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.1 (convertido de dotnet-add-migration.zsh)

.EXAMPLE
    ./dotnet-add-migration.ps1 AddCustomerTable

.EXAMPLE
    ./dotnet-add-migration.ps1 AddCustomerTable -Project src/Infra -StartupProject src/Api
#>

param(
    [Parameter(Position = 0)]
    [string]$MigrationName,

    [string]$Project,
    [string]$StartupProject,
    [string]$Context
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

function Show-Usage {
    Write-ErrMessage "Uso: $($MyInvocation.MyCommand.Name) <nome-da-migration> [-Project <path>] [-StartupProject <path>] [-Context <nome>]"
}

if ([string]::IsNullOrWhiteSpace($MigrationName)) {
    Write-ErrMessage "Nome da migration não informado."
    Show-Usage
    exit 1
}

# ==============================
# ETAPA 1 — ADICIONAR MIGRATION
# ==============================

$efArgs = @('migrations', 'add', $MigrationName)

if ($Project)         { $efArgs += @('--project', $Project) }
if ($StartupProject)  { $efArgs += @('--startup-project', $StartupProject) }
if ($Context)         { $efArgs += @('--context', $Context) }

Write-SectionTitle "Etapa 1 — Adicionando migration '$MigrationName'"
Write-InfoMessage "Executando: dotnet ef $($efArgs -join ' ')"

dotnet ef @efArgs
if ($LASTEXITCODE -ne 0) {
    Write-ErrMessage "Falha ao adicionar a migration '$MigrationName'."
    exit 1
}

Write-SuccessMessage "Migration '$MigrationName' adicionada com sucesso."

# ==============================
# RESUMO FINAL
# ==============================

Write-SectionTitle "Resumo"

Write-Field "Migration"          $MigrationName
Write-Field "Projeto"            $(if ($Project) { $Project } else { "(diretório atual)" })
Write-Field "Projeto de startup" $(if ($StartupProject) { $StartupProject } else { "(diretório atual)" })
Write-Field "DbContext"          $(if ($Context) { $Context } else { "(não especificado)" })

Write-Host ''
Write-SuccessMessage "Operação concluída."