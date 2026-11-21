# ============================================================
# APLICAR ALTERACOES NO REGISTRO - TODAS AS PASTAS DE C:\Users
# EXECUTAR COMO ADMINISTRADOR
# ============================================================

# 1. VERIFICAR PRIVILEGIOS ADMINISTRATIVOS

$Admin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $Admin) {
    Write-Host "Execute este script como administrador!" -ForegroundColor Red
    pause
    exit
}

# ============================================================
# 2. COMANDOS PARA TODOS OS PERFIS
# HKCU - REDIRECIONADO PARA CADA HIVE
# ============================================================

$UserCommands = @(

    # Comando 1 - Abertura mais rapida dos menus
    'reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 50 /f'

    # Comando 2 - Menu de contexto classico
    'reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve'

    # Comando 3 - Controlar fixacao das aplicacoes
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v ShowAllPinsList /t REG_DWORD /d 1 /f'

    # Comando 4 - Ocultar secao de recomendacoes
    'reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v HideRecommendedSection /t REG_DWORD /d 1 /f'

    # Comando 5 - Layout do Menu Iniciar
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_Layout /t REG_DWORD /d 1 /f'

    # Comando 6 - Desabilitar aplicativos recentemente adicionados
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v ShowRecentList /t REG_DWORD /d 0 /f'

    # Comando 7 - Desabilitar historico de documentos
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackDocs /t REG_DWORD /d 0 /f'

    # Comando 8 - Desabilitar recomendacoes
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_IrisRecommendations /t REG_DWORD /d 0 /f'

    # Comando 9 - Ocultar aplicativos recentemente adicionados
    'reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v HideRecentlyAddedApps /t REG_DWORD /d 1 /f'

    # Comando 10 - Ocultar aplicativos mais utilizados
    'reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v ShowOrHideMostUsedApps /t REG_DWORD /d 2 /f'

    # Comando 11 - Desativar historico de pesquisa
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v IsDeviceSearchHistoryEnabled /t REG_DWORD /d 0 /f'

    # Comando 12 - Impedir pesquisa de Internet no Menu Iniciar
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSearchInternetInStartMenu /t REG_DWORD /d 1 /f'

    # Comando 13 - Desativar destaques dinamicos da pesquisa
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v IsDynamicSearchBoxEnabled /t REG_DWORD /d 0 /f'

     # 14 - Impedir pesquisa de Internet pelo Menu Iniciar
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSearchInternetInStartMenu /t REG_DWORD /d 1 /f'

    # 15 - Desativar destaques da pesquisa
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v IsDynamicSearchBoxEnabled /t REG_DWORD /d 0 /f'

)

# ============================================================
# 3. CONFIGURACOES GLOBAIS
# HKLM - EXECUTAR UMA UNICA VEZ
# ============================================================

$MachineCommands = {

    $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"

    New-Item -Path $Path -Force -ErrorAction Stop | Out-Null

    # Desabilitar pesquisa na Web
    New-ItemProperty -Path $Path `
        -Name "DisableWebSearch" `
        -PropertyType DWord `
        -Value 1 `
        -Force -ErrorAction Stop | Out-Null

    # Desabilitar resultados da Web na pesquisa
    New-ItemProperty -Path $Path `
        -Name "ConnectedSearchUseWeb" `
        -PropertyType DWord `
        -Value 0 `
        -Force -ErrorAction Stop | Out-Null
}

# ============================================================
# 4. IDENTIFICAR TODOS OS DIRETORIOS DE C:\Users
# ============================================================

$Root = "C:\Users"

# Obter perfis cadastrados no Windows para identificar
# quais hives ja estao carregados e seus respectivos SIDs.

$RegisteredProfiles = Get-CimInstance Win32_UserProfile

$Profiles = Get-ChildItem -Path $Root -Directory -Force |
Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName "NTUSER.DAT")
}

Write-Host "`nPerfis encontrados: $($Profiles.Count)" -ForegroundColor Cyan

# ============================================================
# 5. PROCESSAR CADA DIRETORIO
# ============================================================

foreach ($Profile in $Profiles) {

    $ProfilePath = $Profile.FullName.TrimEnd('\')

    $NTUser = Join-Path $ProfilePath "NTUSER.DAT"

    $Registered = $RegisteredProfiles |
        Where-Object {
            $_.LocalPath.TrimEnd('\') -ieq $ProfilePath
        } |
        Select-Object -First 1

    $LoadedByScript = $false

    Write-Host "`n========================================" -ForegroundColor DarkGray
    Write-Host "Perfil: $ProfilePath" -ForegroundColor Cyan

    if ($Registered -and $Registered.Loaded) {

        # Perfil ja carregado no Windows
        $HiveName = $Registered.SID

        Write-Host "Hive ja carregado: $HiveName" -ForegroundColor Yellow

    }
    else {

        # Carregar hive temporariamente
        $HiveName = "AllUsersTemp_" + [guid]::NewGuid().ToString("N")

        Write-Host "Carregando perfil temporariamente..." -ForegroundColor Yellow

        & reg.exe load "HKU\$HiveName" "$NTUser" | Out-Null

        if ($LASTEXITCODE -ne 0) {

            Write-Host "Falha ao carregar: $ProfilePath" -ForegroundColor Red
            continue

        }

        $LoadedByScript = $true
    }

    try {

        foreach ($Command in $UserCommands) {

            if ([string]::IsNullOrWhiteSpace($Command)) {
                continue
            }

            # Redirecionar HKCU para o hive do usuario
            $AdjustedCommand = $Command -replace `
                '(?i)HKCU(?=\\)', "HKU\$HiveName"

            Write-Host "Executando: $Command" -ForegroundColor Gray

            & cmd.exe /c $AdjustedCommand

            if ($LASTEXITCODE -ne 0) {

                Write-Host "Falha no comando para $ProfilePath" -ForegroundColor Yellow

            }
        }

        Write-Host "Perfil processado!" -ForegroundColor Green

    }
    finally {

        if ($LoadedByScript) {

            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()

            & reg.exe unload "HKU\$HiveName" | Out-Null

            if ($LASTEXITCODE -ne 0) {

                Write-Host "Falha ao descarregar hive: $HiveName" -ForegroundColor Red

            }
            else {

                Write-Host "Hive descarregado corretamente." -ForegroundColor DarkGray

            }
        }
    }
}

# ============================================================
# 6. APLICAR CONFIGURACOES GLOBAIS
# ============================================================

Write-Host "`nAplicando configuracoes globais..." -ForegroundColor Cyan

try {

    & $MachineCommands

    Write-Host "Configuracoes globais aplicadas!" -ForegroundColor Green

}
catch {

    Write-Host "Erro nas configuracoes globais: $_" -ForegroundColor Red

}

# ============================================================
# 7. FINALIZACAO
# ============================================================

Write-Host "`nPROCESSAMENTO FINALIZADO!" -ForegroundColor Green

pause