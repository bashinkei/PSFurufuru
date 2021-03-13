param (
    [ValidateSet("debug")] $startupStatus
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Set-StrictMode -Version Latest

# �e�X�g�ȊO�̃T�u�X�N���v�g�̓ǂݍ���
Get-ChildItem  -Path ".\subScript" -File | ? { $_.Extension -eq ".ps1" -and $_.BaseName -notlike "*Tests*" } | % { . $_.FullName }

Add-Type -AssemblyName System.Windows.Forms

# �萔��`
$MUTEX_NAME = "20E874C1-2753-44F9-9EAF-EA54E1B7447E" # ���d�N���`�F�b�N�p

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
        $notify_icon.Text = "�ӂ�ӂ钆..."
        $notify_icon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Global:RUNNING_ICON_FILE)
        $Global:duringFurufuru = $true
    }
    else {
        $timer.Stop()
        $isFurufuru = $false
        $notify_icon.Text = "�ӂ�ӂ��~"
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
    OutHostMessage "((�ӂ�ӂ�))"
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


        # ���j���[��Exit���j���[��ǉ�
        $exitScript = {
            OutHostMessage "Exit�N���b�N�I"
            [void][System.Windows.Forms.Application]::Exit()
        }
        $menuItemExit = NewToolStripMenuItem -name "�I������" -action $exitScript
        $null = $notify_icon.ContextMenuStrip.Items.Add($menuItemExit)

        # �^�C�}�[�C�x���g
        $timer.Enabled = $true
        $timer.Add_Tick( { Furufuru -userSetting $userSetting })
        $timer.Interval = $userSetting.intervalSecond * 1000

        if ($userSetting.furufuruAtStart) {
            SetFurufuruStatus -status On
        }
        else {
            SetFurufuruStatus -status Off
        }

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
