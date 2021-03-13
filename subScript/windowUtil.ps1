$Global:windowHandle = 0
$Global:windowState = [nCmdShow]::SW_SHOW

enum nCmdShow {
    SW_HIDE = 0
    SW_SHOW = 5
}

# ShowWindowAsyncメソッドの取得
function ShowWindowAsync {
    $windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
    $asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
    return $asyncwindow
}

# ウィンドウハンドルの取得
# 初回呼び出し時にはウィンドウが表示されている想定
function GetWindowHandle {
    if ($Global:windowHandle -eq 0) {
        $Global:windowHandle = (Get-Process -PID $pid).MainWindowHandle
    }
    return $Global:windowHandle
}

# ウィンドウの状態取得
function GetWindowState {
    return $Global:windowState
}

# ウィンドウの状態のセット
function SetWindowState {
    param(
        [Parameter(Mandatory)]
        [nCmdShow] $stateNo
    )
    $Global:windowState = $stateNo

    $ShowWindowAsync = ShowWindowAsync
    $WindowHandle = GetWindowHandle

    $null = $ShowWindowAsync::ShowWindowAsync($WindowHandle, $stateNo)
}

# ウィンドウを隠す
function HideWindow {
    SetWindowState -stateNo "SW_HIDE"
}

# 隠れたウィンドウを表示させる
function ShowWindow {
    SetWindowState -stateNo "SW_SHOW"
}

