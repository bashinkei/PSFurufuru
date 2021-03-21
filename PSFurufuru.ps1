param (
    $startupStatus
)
trap {
    ShowWindow
    Write-Host $Error
    Read-Host "�G���[���������܂����B���e���m�F���Ă��������B"
}

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Set-StrictMode -Version Latest

# �e�X�g�ȊO�̃T�u�X�N���v�g�̓ǂݍ���
Get-ChildItem  -Path ".\subScript" -File | ? { $_.Extension -eq ".ps1" -and $_.BaseName -notlike "*Tests*" } | % { . $_.FullName }

Add-Type -AssemblyName System.Windows.Forms

# �萔��`
$MUTEX_NAME = "20E874C1-2753-44F9-9EAF-EA54E1B7447E" # ���d�N���`�F�b�N�p

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
        $notify_icon.Text = "�ӂ�ӂ钆..."
        $Global:furufurustatus.duringFurufuru = $true
    }
    else {
        $notify_icon.Text = "�ӂ�ӂ��~"
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
            "stoppingTime �o���f�[�V�����G���[�F`n"
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
                # �ʂ̃o���f�[�V����
                if($valName -in @("start","end")){
                    $dateRegExp = '([01][0-9]|2[0-3]):[0-5][0-9]'
                    if($chkReslt.value -notmatch $dateRegExp){
                        $msg =  "{0}�ɂ͎��Ԍ`��(HH:mm)�̒l��ݒ肵�Ă��������B�ݒ�l�F{1}`n" -f @($valName, $chkReslt.value)
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
# ���d�N���`�F�b�N
if ($mutex.WaitOne(0) -eq $false) {
    OutHostMessage "���łɎ��s�����ȁE�E�E�H"
    $null = $mutex.Close()
    return
}
try {
    # window�̔�\��
    HideWindow

    # �ʒm�̈�A�C�R���̎擾
    $notify_icon = New-Object System.Windows.Forms.NotifyIcon
    $timer = New-Object Windows.Forms.Timer
    try {
        # �ʒm�̈�A�C�R���̃A�C�R����ݒ�
        $notify_icon.Visible = $true

        # �A�C�R���N���b�N����window�̕\���E��\���𔽓]
        $script = if ($startupStatus -eq "debug") {
            {
                OutHostMessage "�A�C�R���N���b�N�I"
                if ($_.Button -ne [Windows.Forms.MouseButtons]::Left) { return }
                if ((GetWindowState) -eq [nCmdShow]::SW_HIDE) { ShowWindow } else { HideWindow }
            }
        }
        else {
            {
                OutHostMessage "�A�C�R���N���b�N�I"
                if ($_.Button -ne [Windows.Forms.MouseButtons]::Left) { return }
                InverseFurufuruStatus
            }
        }

        $notify_icon.add_Click( $script)


        # �A�C�R���Ƀ��j���[��ǉ�
        $notify_icon.ContextMenuStrip = New-Object System.Windows.Forms.ContextMenuStrip

        # ���j���[�ɊĎ�ON�EOFF�ǉ�
        $script = {
            OutHostMessage "Monitoring On�N���b�N�I"
            SetFurufuruStatus -status On
        }
        $monitoringOn = NewToolStripMenuItem -name "�ӂ�ӂ� �I��" -action $script
        $null = $notify_icon.ContextMenuStrip.Items.Add($monitoringOn)

        $script = {
            OutHostMessage "Monitoring Off�N���b�N�I"
            SetFurufuruStatus -status Off
        }
        $monitoringOff = NewToolStripMenuItem -name "�ӂ�ӂ� �I�t" -action $script
        $null = $notify_icon.ContextMenuStrip.Items.Add($monitoringOff)

        # ���j���[�ɃZ�p���[�^�ǉ�
        $ToolStripSeparator = New-Object System.Windows.Forms.ToolStripSeparator
        $null = $notify_icon.ContextMenuStrip.Items.Add($ToolStripSeparator)

        # ��~���Ԃ̐؂�ւ����j���[�쐬
        ## �ݒ�t�@�C���̒�~���Ԃ�ǉ�
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
        $stoppings = NewToolStripMenuItem -name "��~���Ԑݒ�" -action {}
        $stoppings.DropDown = $dropdown
        $null = $notify_icon.ContextMenuStrip.Items.Add($stoppings)

        # ���j���[�ɃZ�p���[�^�ǉ�
        $ToolStripSeparator = New-Object System.Windows.Forms.ToolStripSeparator
        $null = $notify_icon.ContextMenuStrip.Items.Add($ToolStripSeparator)

        # ���j���[��Exit���j���[��ǉ�
        $exitScript = {
            OutHostMessage "Exit�N���b�N�I"
            [void][System.Windows.Forms.Application]::Exit()
        }
        $menuItemExit = NewToolStripMenuItem -name "�I������" -action $exitScript
        $null = $notify_icon.ContextMenuStrip.Items.Add($menuItemExit)

        # �^�C�}�[�C�x���g
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
        # exit�����܂őҋ@
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
