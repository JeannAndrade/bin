<#
.SYNOPSIS
    Equivalente PowerShell de shared-style.zsh.

.DESCRIPTION
    Helpers de saída padronizada (cores, títulos de seção, campos, itens
    de lista) reutilizados pelos scripts .NET.

.NOTES
    Carregue via: Import-Module "$PSScriptRoot/SharedStyle.psm1"

    Em zsh, as cores eram strings ANSI manuais com fallback para string
    vazia quando a saída não era um TTY (if [[ -t 1 ]]). Aqui usamos
    Write-Host -ForegroundColor, que o próprio PowerShell já trata de
    forma correta quando a saída é redirecionada — não precisamos
    reimplementar a detecção de TTY.
#>

function Write-ErrMessage {
  param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Message)
  Write-Host "Erro: $($Message -join ' ')" -ForegroundColor Red
}

function Write-WarnMessage {
  param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Message)
  Write-Host "Aviso: $($Message -join ' ')" -ForegroundColor Yellow
}

function Write-InfoMessage {
  param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Message)
  Write-Host "Info: $($Message -join ' ')" -ForegroundColor Cyan
}

function Write-SuccessMessage {
  param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Message)
  Write-Host "$($Message -join ' ')" -ForegroundColor Green
}

# Exibe um título de seção com separador.
# Uso: Write-SectionTitle "Título da Seção"
function Write-SectionTitle {
  param([Parameter(Mandatory)][string]$Title)
  $sep = '────────────────────────────'
  Write-Host ''
  Write-Host $Title -ForegroundColor Cyan
  Write-Host $sep -ForegroundColor Cyan
}

# Exibe um par label: valor formatado.
# Uso: Write-Field "Label" "valor"
function Write-Field {
  param(
    [Parameter(Mandatory)][string]$Label,
    [Parameter(Mandatory)][string]$Value
  )
  Write-Host ("  {0,-20} {1}" -f "${Label}:", $Value)
}

# Exibe um item de lista com marcador.
# Uso: Write-ListItem "Descrição do item"
function Write-ListItem {
  param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Text)
  Write-Host "  • $($Text -join ' ')"
}

Export-ModuleMember -Function Write-ErrMessage, Write-WarnMessage, Write-InfoMessage, `
  Write-SuccessMessage, Write-SectionTitle, Write-Field, Write-ListItem