<#
.SYNOPSIS
    Faz o backup do banco "biblioteca" usando o mysqldump.

.DESCRIPTION
    - Pede a senha na hora de rodar (ela nao fica escrita no script).
    - Gera um arquivo .sql com data e hora no nome.
    - Registra o que aconteceu em backups\backup.log.
    - Apaga backups mais antigos que -DiasParaManter dias.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\backup.ps1

.EXAMPLE
    # Se o mysqldump nao for encontrado automaticamente:
    powershell -ExecutionPolicy Bypass -File .\scripts\backup.ps1 -CaminhoMysqldump "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe"
#>

param(
    [string]$Usuario = "biblioteca_admin",
    [string]$Banco = "biblioteca",
    [string]$PastaBackup = (Join-Path $PSScriptRoot "..\backups"),
    [int]$DiasParaManter = 7,
    [string]$CaminhoMysqldump = ""
)

$ErrorActionPreference = "Stop"

# Prepara a pasta dos backups e o arquivo de log
$PastaBackup = [System.IO.Path]::GetFullPath($PastaBackup)
New-Item -ItemType Directory -Path $PastaBackup -Force | Out-Null
$ArquivoLog = Join-Path $PastaBackup "backup.log"

function Escrever-Log {
    param([string]$Mensagem)
    $linha = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Mensagem
    Write-Host $linha
    Add-Content -Path $ArquivoLog -Value $linha
}

function Encontrar-Mysqldump {
    param([string]$Caminho)
    if ($Caminho -and (Test-Path $Caminho)) { return $Caminho }

    $comando = Get-Command mysqldump -ErrorAction SilentlyContinue
    if ($comando) { return $comando.Source }

    $achado = Get-ChildItem "C:\Program Files\MySQL" -Recurse -Filter "mysqldump.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($achado) { return $achado.FullName }

    return $null
}

$arquivoSaida = $null
$ponteiro = [IntPtr]::Zero

try {
    $mysqldump = Encontrar-Mysqldump -Caminho $CaminhoMysqldump
    if (-not $mysqldump) {
        throw "mysqldump nao encontrado. Informe o caminho com -CaminhoMysqldump."
    }

    # Pede a senha sem mostrar na tela
    $senhaSegura = Read-Host "Senha do usuario $Usuario" -AsSecureString
    $ponteiro = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($senhaSegura)
    $env:MYSQL_PWD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ponteiro)

    $carimbo = Get-Date -Format "yyyyMMdd_HHmmss"
    $arquivoSaida = Join-Path $PastaBackup "${Banco}_$carimbo.sql"

    Escrever-Log "Iniciando backup do banco '$Banco' com o usuario '$Usuario'."

    $argumentos = @(
        "--user=$Usuario",
        "--single-transaction",
        "--no-tablespaces",
        "--routines",
        "--default-character-set=utf8mb4",
        "--result-file=$arquivoSaida",
        "--databases", $Banco
    )
    & $mysqldump @argumentos

    if ($LASTEXITCODE -ne 0) {
        throw "O mysqldump terminou com erro (codigo $LASTEXITCODE)."
    }

    $tamanhoKB = [math]::Round((Get-Item $arquivoSaida).Length / 1KB, 1)
    Escrever-Log "Backup concluido: $arquivoSaida ($tamanhoKB KB)."

    # Remove backups mais antigos que o limite
    $limite = (Get-Date).AddDays(-$DiasParaManter)
    $antigos = Get-ChildItem -Path $PastaBackup -Filter "${Banco}_*.sql" |
        Where-Object { $_.LastWriteTime -lt $limite }
    foreach ($arquivo in $antigos) {
        Remove-Item $arquivo.FullName
        Escrever-Log "Backup antigo removido: $($arquivo.Name)"
    }
}
catch {
    Escrever-Log "ERRO: $($_.Exception.Message)"
    # Nao deixa um arquivo de backup incompleto para tras
    if ($arquivoSaida -and (Test-Path $arquivoSaida)) {
        Remove-Item $arquivoSaida -Force
    }
    exit 1
}
finally {
    # Limpa a senha da memoria e do ambiente
    $env:MYSQL_PWD = $null
    if ($ponteiro -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ponteiro)
    }
}
