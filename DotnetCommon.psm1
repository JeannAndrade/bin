<#
.SYNOPSIS
    Equivalente PowerShell de dotnet-common.zsh.

.DESCRIPTION
    Helpers compartilhados de validação para os scripts .NET e Git.

.NOTES
    Carregue via: Import-Module "$PSScriptRoot/DotnetCommon.psm1"
#>

function Assert-CommandAvailable {
    <#
    .SYNOPSIS
        Equivalente a require_command() do zsh: garante que um comando
        está disponível no PATH, com mensagem de erro customizável.
    #>
    param(
        [Parameter(Mandatory)][string]$Command,
        [string]$Message = "o comando '$Command' não está disponível no PATH."
    )
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        Write-ErrMessage $Message
        exit 1
    }
}

function Assert-DotnetCli {
    <#
    .SYNOPSIS
        Equivalente a check_dotnet() do zsh: garante que 'dotnet' está no
        PATH e imprime a versão encontrada.
    #>
    Assert-CommandAvailable -Command 'dotnet' -Message "O comando 'dotnet' não foi encontrado."
    Write-InfoMessage "dotnet SDK encontrado: $(dotnet --version)"
}

Export-ModuleMember -Function Assert-CommandAvailable, Assert-DotnetCli