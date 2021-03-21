
function settingDefine {
    param (
        [Parameter(Mandatory)][string] $valueName,
        [Parameter(Mandatory)][System.Reflection.TypeInfo] $type,
        [Parameter(Mandatory)][object] $defaultValue
    )
    return [PSCustomObject]@{
        valueName    = $valueName
        type         = $type
        defaultValue = $defaultValue
    }
}

function SetCustomeValidation {
    param (
        [Parameter(Mandatory)]
        [string] $valueName,
        [Parameter(Mandatory)]
        [ScriptBlock] $validateFunc
    )
    return [PSCustomObject]@{
        valueName    = $valueName
        validateFunc = $validateFunc
    }

}

function CheckSettingDefine {
    param (
        [Parameter(Mandatory)]
        [object] $chkValue,
        [Parameter(Mandatory)]
        [PSCustomObject] $SettingDefine
    )
    function CheckNullorType {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [object] $value,
            [Parameter(Mandatory)]
            [System.Reflection.TypeInfo] $type
        )
        if ($null -ne $value ) {
            return $value.getType() -eq $type
        }
        return $true
    }

    $errMsg = $null
    $val = $null

    if (CheckNullorType -value $chkValue -type $settingDefine.type) {
        $val = if ($null -eq $chkValue) {
            $settingDefine.defaultValue
        }
        else {
            $chkValue
        }
    }
    else {
        $errMsg = "{0}�ɂ�{1}�^�̒l��ݒ肵�Ă��������B�ݒ�l:{2}`n" -f $settingDefine.valueName, $settingDefine.type.Name, $chkValue
    }
    return [PSCustomObject]@{
        errMsg = $errMsg
        value  = $val
    }

}

function GetSetting {
    param (
        [Parameter(Mandatory)]
        [PSCustomObject[]] $settingDefines,
        [PSCustomObject[]] $customeValidations = @()
    )
    # ���[�U�[�ݒ�擾
    $userSettingRaw = Get-Content $SETTING_JSON -Raw | ConvertFrom-Json

    # �o���f�[�V����
    $err = ""
    $err += foreach ($settingDefine in $settingDefines) {
        $valName = $settingDefine.valueName
        $chkReslt = CheckSettingDefine -chkValue $userSettingRaw.($valName) -SettingDefine $settingDefine
        if ($null -ne $chkReslt.errMsg) {
            $chkReslt.errMsg
        }
        else {
            Set-Variable -Name $valName -Value $chkReslt.value
        }
    }
    $err += foreach ($customeValidation in $customeValidations) {
        $settingName = $settingDefines | ? { $_.valueName -eq $customeValidation.valueName }
        $target = $userSettingRaw.($settingName.valueName)
        & $customeValidation.validateFunc $target
    }

    if (-not [string]::IsNullOrEmpty($err)) {
        throw $err
    }

    $val = @()
    $val += $settingDefines | % { '{0} = ${1}' -f $_.valueName, $_.valueName }

    $objectStr = '[PSCustomObject]@{{{0}}}' -f ([string]::Join(';', $val))

    return (Invoke-Expression $objectStr)
}
