#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Aplica as migrations pendentes ao banco de dados usando o Entity
    Framework Core Tools (dotnet-ef).

.DESCRIPTION
    Equivalente PowerShell de dotnet-migration-apply.zsh.

    Diferente da versão zsh, aqui não existe um loop manual de parsing de
    argumentos: o bloco param() do PowerShell cobre nomes, valores
    obrigatórios e opções desconhecidas nativamente.

.PARAMETER TargetMigration
    Opcional. Nome da migration alvo. Se omitido, aplica todas as
    migrations pendentes. Use "0" para reverter todas (voltar ao banco
    vazio).

.PARAMETER Project
    Projeto onde ficam as migrations (onde fica o DbContext).

.PARAMETER StartupProject
    Projeto de inicialização, usado para resolver a connection string.

.PARAMETER Connection
    Connection string customizada, sobrepõe a do appsettings.

.PARAMETER Context
    Nome do DbContext a ser usado, quando houver mais de um no projeto.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.1 (convertido de dotnet-migration-apply.zsh)

.EXAMPLE
    ./dotnet-migration-apply.ps1

.EXAMPLE
    ./dotnet-migration-apply.ps1 AddCustomerTable -Project src/Infra -StartupProject src/Api

.EXAMPLE
    ./dotnet-migration-apply.ps1 0
#>

param(
  [Parameter(Position = 0)]
  [string]$TargetMigration,

  [string]$Project,
  [string]$StartupProject,
  [string]$Connection,
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

# ==============================
# ETAPA 1 — APLICAR MIGRATION(S)
# ==============================

$efArgs = @('database', 'update')

if ($TargetMigration) { $efArgs += $TargetMigration }
if ($Project) { $efArgs += @('--project', $Project) }
if ($StartupProject) { $efArgs += @('--startup-project', $StartupProject) }
if ($Connection) { $efArgs += @('--connection', $Connection) }
if ($Context) { $efArgs += @('--context', $Context) }

if ($TargetMigration) {
  Write-SectionTitle "Etapa 1 — Atualizando o banco de dados até '$TargetMigration'"
}
else {
  Write-SectionTitle "Etapa 1 — Aplicando migrations pendentes ao banco de dados"
}

Write-InfoMessage "Executando: dotnet ef $($efArgs -join ' ')"

dotnet ef @efArgs
if ($LASTEXITCODE -ne 0) {
  Write-ErrMessage "Falha ao atualizar o banco de dados."
  exit 1
}

Write-SuccessMessage "Banco de dados atualizado com sucesso."

# ==============================
# RESUMO FINAL
# ==============================

Write-SectionTitle "Resumo"

Write-Field "Migration alvo"     $(if ($TargetMigration) { $TargetMigration } else { "(todas as pendentes)" })
Write-Field "Projeto"            $(if ($Project) { $Project } else { "(diretório atual)" })
Write-Field "Projeto de startup" $(if ($StartupProject) { $StartupProject } else { "(diretório atual)" })
Write-Field "Connection string"  $(if ($Connection) { $Connection } else { "(padrão do appsettings)" })
Write-Field "DbContext"          $(if ($Context) { $Context } else { "(não especificado)" })

Write-Host ''
Write-SuccessMessage "Operação concluída."