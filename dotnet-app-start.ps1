#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Localiza, compila e executa o projeto .NET executável do diretório atual.

.DESCRIPTION
    Equivalente PowerShell de dotnet-start.zsh.

    Localiza projetos .NET executáveis (Service ou Presentation, seguindo
    a arquitetura em camadas da solution) na pasta atual e subpastas, limpa
    as pastas bin/obj, executa "dotnet build" e depois "dotnet run" no
    projeto encontrado. Se houver apenas um projeto, executa diretamente;
    se houver mais de um, exibe um menu numerado para escolha.

    Projetos de biblioteca (Application, Persistence, Domain, etc.) e de
    teste não são considerados, pois não são executáveis.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.1 (convertido de dotnet-start.zsh)

.EXAMPLE
    ./dotnet-start.ps1
#>

# Equivalente a "set -euo pipefail": qualquer erro de cmdlet interrompe o
# script. Chamadas a processos externos (dotnet build/run) não geram erros
# terminantes por si só — por isso checamos $LASTEXITCODE manualmente após
# cada uma, como faria "set -e" com comandos externos no zsh.
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

# ---------------------------------------------------------------------------
# Compila e executa o projeto selecionado
# ---------------------------------------------------------------------------
function Invoke-Project {
  param([Parameter(Mandatory)][string]$Project)

  Write-InfoMessage "Limpando as pastas bin e obj dos projetos..."
  Get-ChildItem -Path . -Recurse -Directory -Include 'bin', 'obj' -ErrorAction SilentlyContinue |
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

  Write-InfoMessage "Compilando projeto: $Project"
  dotnet build $Project
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  Write-InfoMessage "Executando projeto: $Project"
  dotnet run --project $Project
  exit $LASTEXITCODE
}

# ---------------------------------------------------------------------------
# Busca projetos executáveis
# ---------------------------------------------------------------------------
# Busca apenas projetos executáveis: Service.csproj / *.Service.csproj (API)
# e Presentation.csproj / *.Presentation.csproj (Web). Projetos de biblioteca
# (Application, Persistence, Domain, etc.) e de teste ficam automaticamente
# de fora, pois não seguem esses nomes/sufixos.
#
# Diferente do "find ... -print0" + loop do zsh, Get-ChildItem já devolve
# objetos FileInfo com caminho relativo/absoluto prontos — sem parsing.
$patterns = @('Service.csproj', '*.Service.csproj', 'Presentation.csproj', '*.Presentation.csproj')
$projects = Get-ChildItem -Path . -Recurse -File -Include $patterns

$count = $projects.Count

if ($count -eq 0) {
  Write-ErrMessage "Nenhum projeto executável (Service ou Presentation) encontrado neste diretório."
  exit 1
}
elseif ($count -eq 1) {
  $proj = $projects[0].FullName
  Write-InfoMessage "Encontrado 1 projeto: $proj"
  Invoke-Project -Project $proj
}
else {
  Write-InfoMessage "Foram encontrados $count projetos executáveis:"
  for ($i = 0; $i -lt $count; $i++) {
    # Índice exibido em base 1 (mais natural para quem escolhe no menu),
    # mesmo o array em si sendo 0-based como é padrão em .NET.
    Write-Host ("{0,3}) {1}" -f ($i + 1), $projects[$i].FullName)
  }

  while ($true) {
    $choice = Read-Host "Escolha o número do projeto"
    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $count) {
      break
    }
    Write-WarnMessage "Entrada inválida. Tente novamente."
  }

  $selected = $projects[[int]$choice - 1].FullName
  Invoke-Project -Project $selected
}