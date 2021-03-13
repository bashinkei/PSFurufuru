$MOUSEEVENTF_MOVE = 0x01
$signature = '[DllImport("user32.dll",CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)] public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);'
$null = Add-Type -memberDefinition $signature -name "Win32MouseEventNew" -namespace Win32Functions

function MoveMousePointer {
    param (
        [Parameter(Mandatory)]
        [int] $dx,
        [Parameter(Mandatory)]
        [int] $dy
    )
    $null = [Win32Functions.Win32MouseEventNew]::mouse_event($MOUSEEVENTF_MOVE, $dx, $dy, 0, 0)
}
