#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Publica o pacote NuGet (.nupkg) mais recente da pasta "nupkgs".

.DESCRIPTION
    Equivalente PowerShell de dotnet-publish-package.zsh.

    Publica o pacote NuGet (.nupkg) mais recente da pasta "nupkgs":
      1. No NuGet.org, usando "dotnet nuget push".
      2. Na pasta local (usada como feed local), definida por
         $HOME/NuGetPackages.

    Requer a variável de ambiente NUGET_API_KEY definida antes da execução.

.NOTES
    Autor:  Jeann Andrade
    Versão: 1.2.0 (convertido de dotnet-publish-package.zsh)
    Criado: 2026-07-11

    O caminho fixo "/home/jeann/NuGetPackages" da versão zsh foi trocado
    por Join-Path $HOME 'NuGetPackages', para que o script funcione tanto
    em Linux/WSL quanto em outros sistemas onde o PowerShell rode
    (mesma abordagem usada em vscode-open-workspace.ps1).

    Depende de Assert-DirectoryExists e Find-LatestNupkg em
    DotnetCommon.psm1 (equivalentes a require_dir() e
    find_latest_nupkg() do dotnet-common.zsh).

.EXAMPLE
    $env:NUGET_API_KEY = "sua-chave-aqui"
    ./dotnet-publish-package.ps1
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

# Pasta local usada como feed de pacotes NuGet
$localFeedDir = Join-Path $HOME 'NuGetPackages'

# ---------------------------------------------------------------------------
# Validação: dotnet disponível
# ---------------------------------------------------------------------------
Assert-DotnetCli

Assert-DirectoryExists -Path 'nupkgs' -Message "Pasta 'nupkgs' não encontrada."
$nupkgFile = Find-LatestNupkg -Directory 'nupkgs'

Write-SuccessMessage "Pacote encontrado: $nupkgFile"

# ---------------------------------------------------------------------------
# Validação: API key do NuGet definida via variável de ambiente
# ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($env:NUGET_API_KEY)) {
  Write-ErrMessage "Variável de ambiente NUGET_API_KEY não definida."
  Write-Host 'Defina-a antes de executar este script, por exemplo:' -ForegroundColor Red
  Write-Host '  $env:NUGET_API_KEY = "sua-chave-aqui"' -ForegroundColor Red
  exit 1
}

# ---------------------------------------------------------------------------
# 1. Publicação no NuGet.org
# ---------------------------------------------------------------------------
Write-SectionTitle "1. Publicando no NuGet.org"

Write-InfoMessage "Executando: dotnet nuget push `"$nupkgFile`" --api-key `$env:NUGET_API_KEY --source https://api.nuget.org/v3/index.json"
Write-Host ''

dotnet nuget push $nupkgFile `
  --api-key $env:NUGET_API_KEY `
  --source https://api.nuget.org/v3/index.json
$nugetOrgExitCode = $LASTEXITCODE

Write-Host ''
if ($nugetOrgExitCode -eq 0) {
  Write-SuccessMessage "Pacote publicado com sucesso no NuGet.org."
}
else {
  Write-ErrMessage "Falha ao publicar o pacote no NuGet.org. Código de saída: $nugetOrgExitCode"
}

# ---------------------------------------------------------------------------
# 2. Publicação na pasta local
# ---------------------------------------------------------------------------
Write-SectionTitle "2. Publicando na pasta local"

if (-not (Test-Path -Path $localFeedDir -PathType Container)) {
  Write-InfoMessage "Pasta local '$localFeedDir' não existe. Criando..."
  New-Item -Path $localFeedDir -ItemType Directory -Force | Out-Null
}

Write-InfoMessage "Executando: dotnet nuget push `"$nupkgFile`" --source `"$localFeedDir`""
Write-Host ''

dotnet nuget push $nupkgFile --source $localFeedDir
$localExitCode = $LASTEXITCODE

Write-Host ''
if ($localExitCode -eq 0) {
  Write-SuccessMessage "Pacote publicado com sucesso na pasta local."
}
else {
  Write-ErrMessage "Falha ao publicar o pacote na pasta local. Código de saída: $localExitCode"
}

# ---------------------------------------------------------------------------
# Resumo final
# ---------------------------------------------------------------------------
Write-SectionTitle "Resumo"

Write-Field "Pacote" $nupkgFile
Write-Field "NuGet.org" $(if ($nugetOrgExitCode -eq 0) { 'Sucesso' } else { "Falha ($nugetOrgExitCode)" })
Write-Field "Pasta local" $(if ($localExitCode -eq 0) { 'Sucesso' } else { "Falha ($localExitCode)" })

if ($nugetOrgExitCode -ne 0 -or $localExitCode -ne 0) {
  exit 1
}

exit 0