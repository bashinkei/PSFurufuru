param (
    $startupStatus
)
trap {
    ShowWindow
    Write-Host $Error
    Read-Host "エラーが発生しました。内容を確認してください。"
}

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Set-StrictMode -Version Latest

# テスト以外のサブスクリプトの読み込み
Get-ChildItem  -Path ".\subScript" -File | ? { $_.Extension -eq ".ps1" -and $_.BaseName -notlike "*Tests*" } | % { . $_.FullName }

Add-Type -AssemblyName System.Windows.Forms

# 定数定義
$MUTEX_NAME = "20E874C1-2753-44F9-9EAF-EA54E1B7447E" # 多重起動チェック用

$settingDefines = @(
    (settingDefine -valueName "intervalSecond"    -type ([int])       -defaultValue 60),
    (settingDefine -valueName "furufuruAtStart"   -type ([Boolean])   -defaultValue $false),
    (settingDefine -valueName "furufuruAtreverse" -type ([Boolean])   -defaultValue $false),
    (settingDefine -valueName "furufurudX"        -type ([int])       -defaultValue 1),
    (settingDefine -valueName "furufurudY"        -type ([int])       -defaultValue 1),
    (settingDefine -valueName "stoppingTime"      -type ([Object[]])  -defaultValue @())
)

$stoppingTimeDefines = @(
    (settingDefine -valueName "start" -type ([string])   -defaultValue "00:00"),
    (settingDefine -valueName "end"   -type ([string])   -defaultValue "00:00"),
    (settingDefine -valueName "valid" -type ([Boolean])  -defaultValue $true)
)


$Global:furufurustatus = [PSCustomObject]@{
    duringFurufuru = $false
    furufuruCount  = 0
    stoppings      = @()
}

function OutHostMessage {
    param (
        [Parameter(Mandatory)]
        [string] $message
    )
    Write-Host (Get-date).ToString("yyyy/MM/dd HH:mm:ss.fff") $message
}



function SetIcon {
    param (
        [Parameter(Mandatory)]
        [ValidateSet("On", "Off", "Invalid")]
        [string] $status
    )
    if (IsFurufuruStopping $Global:furufurustatus.stoppings) {
        $notify_icon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Global:INVALID_ICON_FILE)
        return
    }
    switch ($status) {
        "On" {
            $notify_icon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Global:RUNNING_ICON_FILE)
        }
        "Off" {
            $notify_icon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Global:STOPPING_ICON_FILE)
        }
        "Invalid" {
            $notify_icon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Global:INVALID_ICON_FILE)
        }
        Default { }
    }

}
function InverseFurufuruStatus {
    param ()
    if ($Global:furufurustatus.duringFurufuru) {
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
    if ($status -eq "On") {
        $notify_icon.Text = "ふるふる中..."
        $Global:furufurustatus.duringFurufuru = $true
    }
    else {
        $notify_icon.Text = "ふるふる停止"
        $Global:furufurustatus.duringFurufuru = $false
    }

    $monitoringOn.Checked = $Global:furufurustatus.duringFurufuru
    $monitoringOff.Checked = -not $Global:furufurustatus.duringFurufuru
    SetIcon -status $status
}

function IsFurufuruStopping {
    param (
        [Parameter(Mandatory)]
        [array] $stoppings
    )
    $nowTime = (Get-date).ToString("HH:mm")
    $ret = @()
    $ret += $stoppings | ? { $_.isValid } | ? { $t = (($_.start -le $nowTime) -and ($nowTime -le $_.end)); if ($_.start -le $_.end) { $t }else { -not $t } }
    if ($ret.Length -ne 0) {
        return $true
    }
    return $false
}

function Furufuru {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject] $userSetting
    )

    $Global:furufurustatus.furufuruCount += 1

    if ($userSetting.furufuruAtreverse) {
        MoveMousePointer -dx $userSetting.furufurudX -dy $userSetting.furufurudY
        MoveMousePointer -dx ($userSetting.furufurudX * -1) -dy ($userSetting.furufurudY * -1)
    }
    else {
        if ($Global:furufurustatus.furufuruCount % 2 -eq 0) {
            MoveMousePointer -dx $userSetting.furufurudX -dy $userSetting.furufurudY
        }
        else {
            MoveMousePointer -dx ($userSetting.furufurudX * -1) -dy ($userSetting.furufurudY * -1)
        }
    }
}

$validateStoppingTime =  {
    param (
        [Parameter()]
        [object[]] $values
    )

    function MakeErrMsg{
        param (
            [string] $msg,
            [string] $errMsgs
        )
        if([string]::IsNullOrEmpty($errMsgs)){
            "stoppingTime バリデーションエラー：`n"
        }
        $msg
    }
    $errMsgs = ""
    foreach ($value in $values) {
        foreach ($setting in $stoppingTimeDefines) {
            $valName = $setting.valueName
            $chkValue = $value.($valName)

            $chkReslt = CheckSettingDefine -chkValue $chkValue -SettingDefine $setting
            if ($null -ne $chkReslt.errMsg) {
                $errMsgs += MakeErrMsg $chkReslt.errMsg $errMsgs
            }else{
                # 個別のバリデーション
                if($valName -in @("start","end")){
                    $dateRegExp = '([01][0-9]|2[0-3]):[0-5][0-9]'
                    if($chkReslt.value -notmatch $dateRegExp){
                        $msg =  "{0}には時間形式(HH:mm)の値を設定してください。設定値：{1}`n" -f @($valName, $chkReslt.value)
                        $errMsgs += MakeErrMsg $msg $errMsgs
                    }
                }
            }
        }
    }
    return $errMsgs
}
$settingCustomeValidation = SetCustomeValidation -valueName "stoppingTime" -validateFunc $validateStoppingTime

$userSetting = GetSetting -settingDefines $settingDefines -customeValidations @($settingCustomeValidation)

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

        # 停止時間の切り替えメニュー作成
        ## 設定ファイルの停止時間を追加
        $dropdown = New-Object System.Windows.Forms.ToolStripDropDownMenu
        foreach ($stoppingTime in $userSetting.stoppingTime) {
            $name = $stoppingTime.start + "-" + $stoppingTime.end
            $status = $stoppingTime.valid
            $stopItem = [PSCustomObject] @{
                name    = $name
                start   = $stoppingTime.start
                end     = $stoppingTime.end
                isValid = $status
            }
            $Global:furufurustatus.stoppings += $stopItem

            $script = {
                $status = $Global:furufurustatus.stoppings | ? { $_.name -eq $name } | % { $_.isValid = (-not $_.isValid); $_.isValid }
                $args[0].Checked = $status
                $status = if ($Global:furufurustatus.duringFurufuru) { "On" }else { "Off" }
                SetIcon -status $status
            }.GetNewClosure()

            $stoppingItem = NewToolStripMenuItem -name $name -action $script
            $stoppingItem.Checked = $status
            $dropdown.Items.Add($stoppingItem)
        }
        $stoppings = NewToolStripMenuItem -name "停止時間設定" -action {}
        $stoppings.DropDown = $dropdown
        $null = $notify_icon.ContextMenuStrip.Items.Add($stoppings)

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
        $timer.Add_Tick( {
                $status = if ($Global:furufurustatus.duringFurufuru) { "On" }else { "Off" }
                SetIcon -status $status
                if ((IsFurufuruStopping $Global:furufurustatus.stoppings)) {
                    return
                }elseif ($Global:furufurustatus.duringFurufuru) {
                    Furufuru -userSetting $userSetting
                }
            })
        $timer.Interval = $userSetting.intervalSecond * 1000

        if ($userSetting.furufuruAtStart) {
            SetFurufuruStatus -status On
        }
        else {
            SetFurufuruStatus -status Off
        }

        $timer.Start()
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
