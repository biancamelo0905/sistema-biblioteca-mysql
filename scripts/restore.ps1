<#
.SYNOPSIS
    Restaura o banco "biblioteca" a partir de um arquivo de backup (.sql).

.DESCRIPTION
    - Se nenhum arquivo for informado, usa o backup mais recente da pasta backups.
    - Pede confirmacao antes de substituir os dados atuais.
    - Pede a senha na hora de rodar (ela nao fica escrita no script).
    - Usa o usuario root por padrao, porque a view do banco foi criada com o
      root como "definer" e so ele consegue recria-la sem erro de permissao.

.EXAMPLE
    # Restaura o backup mais recente
    powershell -ExecutionPolicy Bypass -File .\scripts\restore.ps1

.EXAMPLE
    # Restaura um arquivo especifico
    powershell -ExecutionPolicy Bypass -File .\scripts\restore.ps1 -Arquivo ".\backups\biblioteca_20261119_100000.sql"
#>

param(
    [string]$Arquivo = "",
    [string]$Usuario = "root",
    [string]$PastaBackup = (Join-Path $PSScriptRoot "..\backups"),
    [string]$CaminhoMysql = ""
)

$ErrorActionPreference = "Stop"

$PastaBackup = [System.IO.Path]::GetFullPath($PastaBackup)
New-Item -ItemType Directory -Path $PastaBackup -Force | Out-Null
$ArquivoLog = Join-Path $PastaBackup "backup.log"

function Escrever-Log {
    param([string]$Mensagem)
    $linha = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Mensagem
    Write-Host $linha
    Add-Content -Path $ArquivoLog -Value $linha
}

function Encontrar-Mysql {
    param([string]$Caminho)
    if ($Caminho -and (Test-Path $Caminho)) { return $Caminho }

    $comando = Get-Command mysql -ErrorAction SilentlyContinue
    if ($comando) { return $comando.Source }

    $achado = Get-ChildItem "C:\Program Files\MySQL" -Recurse -Filter "mysql.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($achado) { return $achado.FullName }

    return $null
}

$ponteiro = [IntPtr]::Zero
$arquivoErro = [System.IO.Path]::GetTempFileName()

try {
    $mysql = Encontrar-Mysql -Caminho $CaminhoMysql
    if (-not $mysql) {
        throw "mysql nao encontrado. Informe o caminho com -CaminhoMysql."
    }

    # Escolhe o arquivo de backup
    if (-not $Arquivo) {
        $maisRecente = Get-ChildItem -Path $PastaBackup -Filter "*.sql" |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if (-not $maisRecente) {
            throw "Nenhum backup .sql encontrado em $PastaBackup."
        }
        $Arquivo = $maisRecente.FullName
    }
    if (-not (Test-Path $Arquivo)) {
        throw "Arquivo nao encontrado: $Arquivo"
    }
    $Arquivo = (Resolve-Path $Arquivo).Path

    Write-Host ""
    Write-Host "Arquivo de backup: $Arquivo"
    Write-Host "ATENCAO: isso vai SUBSTITUIR os dados atuais do banco."
    $resposta = Read-Host "Digite SIM para continuar"
    if ($resposta -ne "SIM") {
        Write-Host "Restauracao cancelada."
        exit 0
    }

    # Pede a senha sem mostrar na tela
    $senhaSegura = Read-Host "Senha do usuario $Usuario" -AsSecureString
    $ponteiro = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($senhaSegura)
    $env:MYSQL_PWD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ponteiro)

    Escrever-Log "Iniciando restauracao a partir de '$Arquivo' com o usuario '$Usuario'."

    $processo = Start-Process -FilePath $mysql `
        -ArgumentList @("--user=$Usuario", "--default-character-set=utf8mb4") `
        -RedirectStandardInput $Arquivo `
        -RedirectStandardError $arquivoErro `
        -NoNewWindow -Wait -PassThru

    if ($processo.ExitCode -ne 0) {
        $detalhe = Get-Content $arquivoErro -Raw
        throw "O mysql terminou com erro (codigo $($processo.ExitCode)). $detalhe"
    }

    Escrever-Log "Restauracao concluida com sucesso."
}
catch {
    Escrever-Log "ERRO: $($_.Exception.Message)"
    exit 1
}
finally {
    $env:MYSQL_PWD = $null
    if ($ponteiro -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ponteiro)
    }
    if (Test-Path $arquivoErro) { Remove-Item $arquivoErro -Force }
}
