
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


function GetSetting {
    param (
        [Parameter(Mandatory)]
        [PSCustomObject[]]
        $settingDefines
    )
    # ���[�U�[�ݒ�擾
    $userSettingRaw = Get-Content $SETTING_JSON -Raw | ConvertFrom-Json

    # �o���f�[�V����
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

    $err = ""
    $err += foreach ($settingDefine in $settingDefines) {
        $valName = $settingDefine.valueName
        if (CheckNullorType -value $userSettingRaw.($valName) -type $settingDefine.type) {
            $val = if ($null -eq $userSettingRaw.($valName)) {
                $settingDefine.defaultValue
            }
            else {
                $userSettingRaw.($valName)
            }
            Set-Variable -Name $valName -Value $val
        }
        else {
            "{0}�ɂ�{1}�^�̒l��ݒ肵�Ă��������B" -f $settingDefine.valueName, $settingDefine.type.Name
        }
    }
    if (-not [string]::IsNullOrEmpty($err)) {
        throw $err
    }

    $val = @()
    $val += $settingDefines | % { '{0} = ${1}' -f $_.valueName, $_.valueName }

    $objectStr = '[PSCustomObject]@{{{0}}}' -f ([string]::Join(';', $val))

    return (Invoke-Expression $objectStr)
}
