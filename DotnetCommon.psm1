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

function Assert-DirectoryExists {
    <#
    .SYNOPSIS
        Equivalente a require_dir() do zsh: garante que um diretório
        existe, com mensagem de erro customizável.
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Message = "Diretório '$Path' não encontrado."
    )
    if (-not (Test-Path -Path $Path -PathType Container)) {
        Write-ErrMessage $Message
        exit 1
    }
}

function Find-LatestNupkg {
    <#
    .SYNOPSIS
        Equivalente a find_latest_nupkg() do zsh: retorna o .nupkg mais
        recente (por data de modificação) dentro da pasta "nupkgs",
        excluindo pacotes de símbolos (*.symbols.nupkg).
    #>
    param([string]$Directory = 'nupkgs')

    $result = Get-ChildItem -Path $Directory -File -Filter '*.nupkg' -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike '*.symbols.nupkg' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

    if (-not $result) {
        Write-ErrMessage "Nenhum arquivo .nupkg encontrado em ./$Directory"
        exit 1
    }

    return $result.FullName
}

function Find-AndSelectCsproj {
    <#
    .SYNOPSIS
        Equivalente a find_and_select_csproj() do zsh: busca .csproj
        recursivamente a partir de $SearchRoot, excluindo os que casam com
        $ExcludePattern. Se houver só um, retorna direto; se houver mais
        de um, exibe um menu numerado para escolha.

    .NOTES
        No zsh, o valor selecionado saía por uma variável global
        (SELECTED_PROJECT), truque necessário porque o script era
        "sourced" e não podia usar um valor de retorno de função de
        forma direta. Em PowerShell isso não é necessário: a função
        simplesmente retorna o caminho (ou $null, se nada for
        encontrado), e quem chama decide o que fazer.
    #>
    param(
        [string]$SearchRoot = '.',
        [string]$ExcludePattern = '*.Test.csproj'
    )

    $projects = @(
        Get-ChildItem -Path $SearchRoot -Recurse -File -Filter '*.csproj' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike $ExcludePattern }
    )

    $n = $projects.Count

    if ($n -eq 0) {
        Write-ErrMessage "Nenhum arquivo .csproj encontrado em '$SearchRoot' (excluindo '$ExcludePattern')."
        return $null
    }
    elseif ($n -eq 1) {
        Write-InfoMessage "Encontrado 1 projeto: $($projects[0].FullName)"
        return $projects[0].FullName
    }

    Write-InfoMessage "Foram encontrados $n projetos:"
    for ($i = 0; $i -lt $n; $i++) {
        Write-Host ("{0,3}) {1}" -f ($i + 1), $projects[$i].FullName)
    }

    while ($true) {
        $choice = Read-Host "Escolha o número do projeto"
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $n) {
            break
        }
        Write-WarnMessage "Entrada inválida. Tente novamente."
    }

    return $projects[[int]$choice - 1].FullName
}

function Get-FrameworkFromSdk {
    <#
    .SYNOPSIS
        Equivalente a framework_from_sdk() do zsh: deriva o TFM (target
        framework moniker, ex.: "net10.0") a partir de uma versão de SDK.

    .PARAMETER SdkVersion
        Versão do SDK, no formato "major.minor.patch" (ex.: "10.0.100").

    .PARAMETER Mode
        "major_minor" usa major e minor da versão do SDK (ex.: 8.0.4xx ->
        net8.0). "major_zero" força o minor como zero (ex.: 10.0.1xx ->
        net10.0), usado quando se quer sempre a primeira versão da major.
    #>
    param(
        [Parameter(Mandatory)][string]$SdkVersion,
        [ValidateSet('major_minor', 'major_zero')]
        [string]$Mode = 'major_minor'
    )

    $parts = $SdkVersion -split '\.'
    $major = $parts[0]
    $minor = if ($parts.Count -gt 1) { $parts[1] } else { '0' }

    if ($Mode -eq 'major_zero') {
        return "net$major.0"
    }

    return "net$major.$minor"
}

function Test-DotnetToolInstalled {
    <#
    .SYNOPSIS
        Verifica se uma dotnet tool está instalada globalmente, comparando
        o nome de forma case-insensitive.

    .DESCRIPTION
        Generaliza a checagem que existia duplicada em scripts zsh
        distintos (grep -qi "$TOOL_ID" / awk -v pkg="${TOOL_ID:l}"): tanto
        dotnet-ef-tools-install.zsh quanto dotnet-libman-tools-install.zsh
        faziam essa mesma verificação, cada um a seu jeito.
    #>
    param([Parameter(Mandatory)][string]$ToolId)
    $output = dotnet tool list --global 2>$null
    return [bool]($output | Where-Object { ($_ -split '\s+')[0] -ieq $ToolId })
}

function Get-InstalledDotnetToolVersion {
    <#
    .SYNOPSIS
        Retorna a versão instalada de uma dotnet tool global, ou $null se
        ela não estiver instalada.
    #>
    param([Parameter(Mandatory)][string]$ToolId)
    $output = dotnet tool list --global 2>$null
    $row = $output | Where-Object { ($_ -split '\s+')[0] -ieq $ToolId }
    if ($row) {
        return ($row -split '\s+')[1]
    }
    return $null
}

Export-ModuleMember -Function Assert-CommandAvailable, Assert-DotnetCli, Find-CsprojByName, `
    Assert-DirectoryExists, Find-LatestNupkg, Find-AndSelectCsproj, Get-FrameworkFromSdk, `
    Test-DotnetToolInstalled, Get-InstalledDotnetToolVersion