function SetGlobalConst {
    param (
        [Parameter(Mandatory)]
        [string] $Name,
        [Parameter(Mandatory)]
        [Object] $value
    )
    # �萔�̐ݒ�i�ς������Ƃ���powersehll���̂��ċN���E�萔�͕ς����Ȃ����ۂ��E�ǂݍ��ݍς݂ł��G���[�ɂȂ�Ȃ��悤��"Ignore"�����Ă�j
    Set-Variable $Name -Value $value -Scope "Global" -Option "Constant" -ErrorAction "Ignore"

}

SetGlobalConst "SCRIPT_ROOT" (Split-Path $PSScriptRoot -Parent)
SetGlobalConst "RESOURCES_PATH" (Join-Path $SCRIPT_ROOT "resources")

# �e��ݒ�t�@�C����
SetGlobalConst "SETTING_JSON" (Join-Path $SCRIPT_ROOT "settings.json")

SetGlobalConst "RUNNING_ICON_FILE" (Join-Path $RESOURCES_PATH "cursolRunnning.ico")
SetGlobalConst "STOPPING_ICON_FILE" (Join-Path $RESOURCES_PATH "cursolStopping.ico")
SetGlobalConst "INVALID_ICON_FILE" (Join-Path $RESOURCES_PATH "cursolInvalid.ico")

