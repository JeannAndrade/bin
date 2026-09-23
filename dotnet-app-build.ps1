#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Compila a solução .NET do diretório atual e executa os testes.

.DESCRIPTION
    Equivalente PowerShell de dotnet-build.zsh.

    Compila a solução .NET do diretório atual com "dotnet build" e, em
    seguida, executa os testes unitários de todos os projetos da solução
    com "dotnet test", usando o código de retorno dos testes como ponto
    de verificação final da execução.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.1.0 (convertido de dotnet-build.zsh)
    Criado: 2026-07-11

    $PSScriptRoot é o equivalente direto de "${0:A:h}" do zsh — ambos
    resolvem o caminho absoluto da pasta onde o script está, sem
    depender de como ele foi chamado (caminho relativo, symlink, etc.).

.EXAMPLE
    ./dotnet-build.ps1
#>

$ErrorActionPreference = 'Stop'
Clear-Host

# ---------------------------------------------------------
# Carrega bibliotecas compartilhadas (style antes de common)
# ---------------------------------------------------------
$scriptDir = $PSScriptRoot

$styleModule = Join-Path $scriptDir 'SharedStyle.psm1'
if (Test-Path $styleModule) {
  Import-Module $styleModule -Force
}
else {
  Write-Host "Erro: SharedStyle.psm1 não encontrado em ${scriptDir}" -ForegroundColor Red
  exit 1
}

$commonModule = Join-Path $scriptDir 'DotnetCommon.psm1'
if (Test-Path $commonModule) {
  Import-Module $commonModule -Force
}
else {
  Write-ErrMessage "DotnetCommon.psm1 não encontrado em ${scriptDir}"
  exit 1
}

# ---------------------------------------------------------
# 1. Validações iniciais
# ---------------------------------------------------------
Write-SectionTitle "1. Validações iniciais"

Assert-DotnetCli
Assert-CommandAvailable -Command 'dotnet'

Write-Field "Diretório" (Get-Location).Path
Write-Field "Versão do SDK" (dotnet --version)

# ---------------------------------------------------------
# 2. Compilação (dotnet build)
# ---------------------------------------------------------
Write-SectionTitle "2. Compilação do projeto"

Write-InfoMessage "Executando dotnet build na solução do diretório atual"

dotnet build
$buildExitCode = $LASTEXITCODE

if ($buildExitCode -ne 0) {
  Write-ErrMessage "A compilação falhou (código de saída: $buildExitCode)."
  exit $buildExitCode
}

Write-SuccessMessage "Compilação concluída com sucesso."

# ---------------------------------------------------------
# 3. Execução dos testes unitários (dotnet test)
# ---------------------------------------------------------
Write-SectionTitle "3. Execução dos testes unitários"

Write-InfoMessage "Executando dotnet test em todos os projetos da solução"

dotnet test --no-build
$testExitCode = $LASTEXITCODE

if ($testExitCode -ne 0) {
  Write-ErrMessage "Os testes falharam (código de saída: $testExitCode)."
}
else {
  Write-SuccessMessage "Todos os testes passaram."
}

# ---------------------------------------------------------
# 4. Resumo
# ---------------------------------------------------------
Write-SectionTitle "4. Resumo"

Write-Field "Diretório" (Get-Location).Path
Write-Field "Build" $(if ($buildExitCode -eq 0) { 'OK' } else { 'FALHOU' })
Write-Field "Testes" $(if ($testExitCode -eq 0) { 'OK' } else { 'FALHOU' })
Write-Field "Código de saída final" $testExitCode

exit $testExitCode