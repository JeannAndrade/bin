#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Adiciona um novo projeto .NET à solução da pasta atual.

.DESCRIPTION
    Equivalente PowerShell de dotnet-project-add.zsh (antigo
    dotnet-add-project.zsh).

    Adiciona um novo projeto .NET (web, webapi, classlib, console ou
    xunit) na pasta atual, detectando o framework alvo a partir do SDK
    definido em "global.json", e o adiciona automaticamente à solution
    (.slnx) encontrada na pasta. Projetos "web" e "webapi" são criados
    com a flag --no-https.

    Totalmente interativo: solicita o tipo de projeto (via menu numerado)
    e o nome do projeto.

.NOTES
    Autor:  Jeann Andrade
    Criado: 2026-07-11
    Versão: 1.0 (convertido de dotnet-project-add.zsh)

    Pré-requisitos: um único arquivo .slnx na pasta atual e um
    global.json com o SDK definido.

    Depende de Find-SingleGlob, Assert-FileExists,
    Get-SdkFromGlobalJson e Get-FrameworkFromSdk em DotnetCommon.psm1.

.EXAMPLE
    ./dotnet-project-add.ps1
#>

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

$solutionName = Find-SingleGlob -Pattern '*.slnx' `
  -MessageZero "Nenhum arquivo .slnx encontrado na pasta atual." `
  -MessageMany "Mais de um arquivo .slnx encontrado na pasta atual:"

Write-InfoMessage "Solution encontrada: $solutionName"

Assert-FileExists -Path 'global.json' -Message "Arquivo global.json não encontrado na pasta atual."
$sdkVersion = Get-SdkFromGlobalJson -Path 'global.json'
$framework = Get-FrameworkFromSdk -SdkVersion $sdkVersion -Mode major_zero

Write-InfoMessage "Framework detectado: $framework (SDK $sdkVersion)"

# ---------------------------------------------------------------------------
# Seleção do tipo de projeto (menu interativo)
# ---------------------------------------------------------------------------
$projectTypes = @('web', 'webapi', 'classlib', 'console', 'xunit')

Write-Host ''
Write-Host "Tipos de projeto disponíveis:"
for ($i = 0; $i -lt $projectTypes.Count; $i++) {
  Write-Host ("{0,3}) {1}" -f ($i + 1), $projectTypes[$i])
}

while ($true) {
  $choice = Read-Host "Escolha o número do tipo de projeto"
  if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $projectTypes.Count) {
    break
  }
  Write-WarnMessage "Entrada inválida. Tente novamente."
}

$projectType = $projectTypes[[int]$choice - 1]
Write-InfoMessage "Tipo selecionado: $projectType"

# ---------------------------------------------------------------------------
# Nome do projeto (com validação)
# ---------------------------------------------------------------------------
Write-Host ''
while ($true) {
  $projectName = Read-Host "Nome do projeto"

  if ([string]::IsNullOrEmpty($projectName)) {
    Write-WarnMessage "O nome não pode ser vazio."
    continue
  }

  if ($projectName -notmatch '^[a-zA-Z][a-zA-Z0-9._-]*$') {
    Write-WarnMessage "Use apenas letras, números, '.', '_' ou '-', iniciando com uma letra."
    continue
  }

  break
}

Write-InfoMessage "Nome do projeto: $projectName"

# ---------------------------------------------------------------------------
# Montagem e execução dos comandos
# ---------------------------------------------------------------------------
Write-Host ''

# Flag --no-https apenas para web e webapi
$newArgs = @('new', $projectType)
if ($projectType -eq 'web' -or $projectType -eq 'webapi') {
  $newArgs += '--no-https'
}
$newArgs += @('--output', $projectName, '--framework', $framework)

$slnArgs = @('sln', $solutionName, 'add', $projectName)

$cmdNewDisplay = "dotnet $($newArgs -join ' ')"
$cmdSlnDisplay = "dotnet $($slnArgs -join ' ')"

Write-InfoMessage "Os seguintes comandos serão executados:"
Write-Host "  1) $cmdNewDisplay"
Write-Host "  2) $cmdSlnDisplay"
Write-Host ''

# Criação do projeto
Write-InfoMessage "Criando projeto..."
dotnet @newArgs
if ($LASTEXITCODE -ne 0) {
  Write-ErrMessage "Falha ao criar o projeto '$projectName'."
  exit 1
}

# Adição à solution
Write-Host ''
Write-InfoMessage "Adicionando projeto à solution..."
dotnet @slnArgs
if ($LASTEXITCODE -ne 0) {
  Write-ErrMessage "Falha ao adicionar o projeto '$projectName' à solution '$solutionName'."
  exit 1
}

Write-Host ''
Write-SuccessMessage "Projeto '$projectName' criado e adicionado à solution '$solutionName'."