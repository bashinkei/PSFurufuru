param (
    [ValidateSet("debug")] $startupStatus
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Set-StrictMode -Version Latest

# テスト以外のサブスクリプトの読み込み
Get-ChildItem  -Path ".\subScript" -File | ? { $_.Extension -eq ".ps1" -and $_.BaseName -notlike "*Tests*" } | % { . $_.FullName }

Add-Type -AssemblyName System.Windows.Forms

# 定数定義
$MUTEX_NAME = "20E874C1-2753-44F9-9EAF-EA54E1B7447E" # 多重起動チェック用

$settingDefines = @(
    (settingDefine -valueName "intervalSecond"    -type ([int])     -defaultValue 60),
    (settingDefine -valueName "furufuruAtStart"   -type ([Boolean]) -defaultValue $false),
    (settingDefine -valueName "furufuruAtreverse" -type ([Boolean]) -defaultValue $false),
    (settingDefine -valueName "furufurudX"        -type ([int])     -defaultValue 1),
    (settingDefine -valueName "furufurudY"        -type ([int])     -defaultValue 1)
)

function OutHostMessage {
    param (
        [Parameter(Mandatory)]
        [string] $message
    )
    Write-Host (Get-date).ToString("yyyy/MM/dd HH:mm:ss.fff") $message
}

$Global:duringFurufuru = $false

function InverseFurufuruStatus {
    param ()
    if ($Global:duringFurufuru) {
        SetFurufuruStatus -status Off
    }
    else {
        SetFurufuruStatus -status On
    }
}

function SetFurufuruStatus {
    param (
        [Parameter(Mandatory)]
        [ValidateSet("On", "Off")]
        [string] $status
    )
    $isFurufuru = $true
    if ($status -eq "On") {
        $timer.Start()
        $isFurufuru = $true
        $notify_icon.Text = "ふるふる中..."
        $notify_icon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Global:RUNNING_ICON_FILE)
        $Global:duringFurufuru = $true
    }
    else {
        $timer.Stop()
        $isFurufuru = $false
        $notify_icon.Text = "ふるふる停止"
        $notify_icon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Global:STOPPING_ICON_FILE)
        $Global:duringFurufuru = $false
    }

    $monitoringOn.Checked = $isFurufuru
    $monitoringOff.Checked = -not $isFurufuru
}

$Global:furufuruCount = 0
function Furufuru {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject] $userSetting
    )
    OutHostMessage "((ふるふる))"
    $Global:furufuruCount += 1

    if ($userSetting.furufuruAtreverse) {
        MoveMousePointer -dx $userSetting.furufurudX -dy $userSetting.furufurudY
        MoveMousePointer -dx ($userSetting.furufurudX * -1) -dy ($userSetting.furufurudY * -1)
    }
    else {
        if ($Global:furufuruCount % 2 -eq 0) {
            MoveMousePointer -dx $userSetting.furufurudX -dy $userSetting.furufurudY
        }
        else {
            MoveMousePointer -dx ($userSetting.furufurudX * -1) -dy ($userSetting.furufurudY * -1)
        }
    }
}

$userSetting = GetSetting -settingDefines $settingDefines

$mutex = New-Object System.Threading.Mutex($false, $MUTEX_NAME)
# 多重起動チェック
if ($mutex.WaitOne(0) -eq $false) {
    OutHostMessage "すでに実行中かな・・・？"
    $null = $mutex.Close()
    return
}
try {
    # windowの非表示
    HideWindow

    # 通知領域アイコンの取得
    $notify_icon = New-Object System.Windows.Forms.NotifyIcon
    $timer = New-Object Windows.Forms.Timer
    try {
        # 通知領域アイコンのアイコンを設定
        $notify_icon.Visible = $true

        # アイコンクリック時にwindowの表示・非表示を反転
        $script = if ($startupStatus -eq "debug") {
            {
                OutHostMessage "アイコンクリック！"
                if ($_.Button -ne [Windows.Forms.MouseButtons]::Left) { return }
                if ((GetWindowState) -eq [nCmdShow]::SW_HIDE) { ShowWindow } else { HideWindow }
            }
        }
        else {
            {
                OutHostMessage "アイコンクリック！"
                if ($_.Button -ne [Windows.Forms.MouseButtons]::Left) { return }
                InverseFurufuruStatus
            }
        }

        $notify_icon.add_Click( $script)


        # アイコンにメニューを追加
        $notify_icon.ContextMenuStrip = New-Object System.Windows.Forms.ContextMenuStrip

        # メニューに監視ON・OFF追加
        $script = {
            OutHostMessage "Monitoring Onクリック！"
            SetFurufuruStatus -status On
        }
        $monitoringOn = NewToolStripMenuItem -name "ふるふる オン" -action $script
        $null = $notify_icon.ContextMenuStrip.Items.Add($monitoringOn)

        $script = {
            OutHostMessage "Monitoring Offクリック！"
            SetFurufuruStatus -status Off
        }
        $monitoringOff = NewToolStripMenuItem -name "ふるふる オフ" -action $script
        $null = $notify_icon.ContextMenuStrip.Items.Add($monitoringOff)

        # メニューにセパレータ追加
        $ToolStripSeparator = New-Object System.Windows.Forms.ToolStripSeparator
        $null = $notify_icon.ContextMenuStrip.Items.Add($ToolStripSeparator)


        # メニューにExitメニューを追加
        $exitScript = {
            OutHostMessage "Exitクリック！"
            [void][System.Windows.Forms.Application]::Exit()
        }
        $menuItemExit = NewToolStripMenuItem -name "終了する" -action $exitScript
        $null = $notify_icon.ContextMenuStrip.Items.Add($menuItemExit)

        # タイマーイベント
        $timer.Enabled = $true
        $timer.Add_Tick( { Furufuru -userSetting $userSetting })
        $timer.Interval = $userSetting.intervalSecond * 1000

        if ($userSetting.furufuruAtStart) {
            SetFurufuruStatus -status On
        }
        else {
            SetFurufuruStatus -status Off
        }

        # exitされるまで待機
        [void][System.Windows.Forms.Application]::Run()

    }
    finally {
        $null = $notify_icon.Dispose()
        $null = $timer.Dispose()
    }
}
finally {
    $null = $mutex.ReleaseMutex()
    $null = $mutex.Close()
}
