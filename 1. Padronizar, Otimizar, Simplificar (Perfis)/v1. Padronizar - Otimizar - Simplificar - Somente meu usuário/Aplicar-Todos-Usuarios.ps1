# ============================================================
# APLICAR ALTERACOES NO REGISTRO - USUARIO ATUAL
# EXECUTAR COMO ADMINISTRADOR
# ============================================================

$Admin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $Admin) {
    Write-Host "Execute este script como Administrador!" -ForegroundColor Red
    pause
    exit
}

# ============================================================
# CONFIGURACOES DO USUARIO ATUAL (HKCU)
# ============================================================

$UserCommands = @(

    # 1 - Abertura mais rapida dos menus
    'reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 50 /f'

    # 2 - Restaurar menu de contexto classico
    'reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve'

    # 3 - Controlar fixacao das aplicacoes no Menu Iniciar
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v ShowAllPinsList /t REG_DWORD /d 1 /f'

    # 4 - Configuracao Start Iris
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_IrisRecommendations /t REG_DWORD /d 1 /f'

    # 5 - Ocultar secao de recomendacoes
    'reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v HideRecommendedSection /t REG_DWORD /d 1 /f'

    # 7 - Layout do Menu Iniciar
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_Layout /t REG_DWORD /d 1 /f'

    # 8 - Desabilitar aplicativos recentemente adicionados
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v ShowRecentList /t REG_DWORD /d 0 /f'

    # 9 - Desabilitar historico de documentos
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackDocs /t REG_DWORD /d 0 /f'

    # 10 - Desabilitar recomendacoes
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_IrisRecommendations /t REG_DWORD /d 0 /f'

    # 11 - Ocultar aplicativos recentemente adicionados
    'reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v HideRecentlyAddedApps /t REG_DWORD /d 1 /f'

    # 12 - Ocultar aplicativos mais utilizados
    'reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v ShowOrHideMostUsedApps /t REG_DWORD /d 2 /f'

    # 13 - Desativar historico de pesquisa
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v IsDeviceSearchHistoryEnabled /t REG_DWORD /d 0 /f'

    # 14 - Impedir pesquisa de Internet pelo Menu Iniciar
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSearchInternetInStartMenu /t REG_DWORD /d 1 /f'

    # 15 - Desativar destaques da pesquisa
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v IsDynamicSearchBoxEnabled /t REG_DWORD /d 0 /f'
)

# ============================================================
# EXECUTAR CONFIGURACOES DO USUARIO ATUAL
# ============================================================

Write-Host "`nAplicando configuracoes do usuario atual..." -ForegroundColor Cyan

foreach ($Command in $UserCommands) {

    Write-Host "`nExecutando: $Command" -ForegroundColor Gray

    & cmd.exe /c $Command

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Falha na execucao!" -ForegroundColor Yellow
    }
}

# ============================================================
# CONFIGURACOES GLOBAIS (HKLM)
# ============================================================

Write-Host "`nAplicando politicas globais..." -ForegroundColor Cyan

try {

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"

    New-Item -Path $path -Force -ErrorAction Stop | Out-Null

    New-ItemProperty -Path $path `
        -Name "DisableWebSearch" `
        -PropertyType DWord `
        -Value 1 `
        -Force -ErrorAction Stop | Out-Null

    New-ItemProperty -Path $path `
        -Name "ConnectedSearchUseWeb" `
        -PropertyType DWord `
        -Value 0 `
        -Force -ErrorAction Stop | Out-Null

    Write-Host "Politicas globais aplicadas." -ForegroundColor Green

}
catch {

    Write-Host "Erro nas politicas globais: $_" -ForegroundColor Red

}

# ============================================================
# FINALIZACAO
# ============================================================

Write-Host "`nPROCESSO FINALIZADO!" -ForegroundColor Green

pause