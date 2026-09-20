#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Verifica e atualiza pacotes NuGet desatualizados em um projeto .NET.

.DESCRIPTION
    Equivalente PowerShell de dotnet-update-packages.zsh.

    Verifica pacotes NuGet desatualizados no projeto (via "dotnet list
    package --outdated"), monta os comandos "dotnet add package" com a
    versão mais recente de cada um e, mediante confirmação, executa todas
    as atualizações, seguidas de "dotnet restore" e "dotnet build".

    Diferente da versão zsh (que usa um loop manual com "read -r" + awk/sed
    para parsear a saída linha a linha), aqui o parsing é feito com
    expressões regulares do PowerShell (-match), o que dispensa chamadas
    externas a awk/sed.

.NOTES
    Autor:  Jeann Andrade
    Criado: 2026-07-11
    Versão: 1.0 (convertido de dotnet-update-packages.zsh)

.EXAMPLE
    ./dotnet-update-packages.ps1
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
# Validação: dotnet disponível
# ---------------------------------------------------------------------------
Assert-DotnetCli

Write-InfoMessage "Buscando pacotes desatualizados..."
Write-Host ''

# ---------------------------------------------------------------------------
# Captura e parseia a saída de "dotnet list package --outdated"
# ---------------------------------------------------------------------------
# Captura stdout + stderr, assim como "2>&1" no zsh.
$outdatedOutput = dotnet list package --outdated 2>&1

$projeto = ''
$comandos = @()

foreach ($linhaRaw in $outdatedOutput) {
  $linha = ($linhaRaw | Out-String).TrimEnd("`r", "`n")
  $linha = $linha.TrimStart()

  # Detecta projeto: "Project `MyApp` has the following updates..."
  if ($linha -match '^Project `(.+?)`') {
    $projeto = $Matches[1]
    continue
  }

  # Detecta package desatualizado: linhas que começam com ">"
  if ($linha -like '>*') {
    $linhaLimpa = $linha.Substring(1).TrimStart()
    $campos = $linhaLimpa -split '\s+' | Where-Object { $_ -ne '' }

    if ($campos.Count -ge 2) {
      $pacote = $campos[0]
      $versaoLatest = $campos[-1]
      $comandos += "dotnet add `"$projeto`" package `"$pacote`" --version $versaoLatest"
    }
  }
}

# Se não houver comandos, sair
if ($comandos.Count -eq 0) {
  Write-InfoMessage "Nenhum pacote desatualizado encontrado."
  exit 0
}

Write-InfoMessage "Os seguintes comandos serão executados:"
Write-Host ''

foreach ($cmd in $comandos) {
  Write-InfoMessage "  $cmd"
}

Write-Host ''
$resposta = Read-Host "Deseja executar esses comandos agora? (s/N)"

if ($resposta -notmatch '^[sS]$') {
  Write-WarnMessage "Operação cancelada pelo usuário."
  exit 0
}

Write-InfoMessage "Executando atualizações..."
Write-Host ''

$falhas = @()

foreach ($cmd in $comandos) {
  Write-InfoMessage "  $cmd"
  Invoke-Expression $cmd
  if ($LASTEXITCODE -ne 0) {
    Write-WarnMessage "Falha ao executar: $cmd"
    $falhas += $cmd
  }
}

Write-Host ''
if ($falhas.Count -gt 0) {
  Write-WarnMessage "Atualização concluída com $($falhas.Count) falha(s):"
  foreach ($cmd in $falhas) {
    Write-WarnMessage "  $cmd"
  }
}
else {
  Write-SuccessMessage "Atualização de pacotes concluída com sucesso."
}

dotnet restore
dotnet build