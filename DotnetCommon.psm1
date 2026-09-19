<#
.SYNOPSIS
    Equivalente PowerShell de dotnet-common.zsh.

.DESCRIPTION
    Helpers compartilhados de validação para os scripts .NET.
    Por enquanto só traz o que dotnet-start.ps1 precisa (equivalente a
    check_dotnet); as demais funções de dotnet-common.zsh entram aqui
    conforme formos convertendo os outros scripts.

.NOTES
    Carregue via: Import-Module "$PSScriptRoot/DotnetCommon.psm1"
#>

function Assert-DotnetCli {
  <#
    .SYNOPSIS
        Equivalente a check_dotnet() do zsh: garante que 'dotnet' está no
        PATH e imprime a versão encontrada.
    #>
  if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-ErrMessage "O comando 'dotnet' não foi encontrado."
    exit 1
  }
  Write-InfoMessage "dotnet SDK encontrado: $(dotnet --version)"
}

Export-ModuleMember -Function Assert-DotnetCli