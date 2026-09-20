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

function Find-CsprojByName {
    <#
    .SYNOPSIS
        Equivalente a find_csproj_by_name() do zsh: procura um .csproj com
        o nome exato informado (recursivamente, a partir do diretório
        atual) e retorna o caminho encontrado, ou encerra com erro.

    .PARAMETER Name
        Nome do projeto, com ou sem a extensão ".csproj".
    #>
    param([Parameter(Mandatory)][string]$Name)

    # Get-ChildItem -Filter já resolve por nome de arquivo sem precisar de
    # find + head -n 1 como no zsh; -ErrorAction SilentlyContinue evita que
    # caminhos sem permissão de leitura interrompam a busca.
    $fileName = if ($Name -like '*.csproj') { $Name } else { "$Name.csproj" }

    $result = Get-ChildItem -Path . -Recurse -File -Filter $fileName -ErrorAction SilentlyContinue |
    Select-Object -First 1

    if (-not $result) {
        Write-ErrMessage "Arquivo '$fileName' não encontrado."
        exit 1
    }

    return $result.FullName
}

Export-ModuleMember -Function Assert-CommandAvailable, Assert-DotnetCli, Find-CsprojByName