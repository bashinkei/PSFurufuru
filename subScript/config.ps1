function SetGlobalConst {
    param (
        [Parameter(Mandatory)]
        [string] $Name,
        [Parameter(Mandatory)]
        [Object] $value
    )
    # 定数の設定（変えたいときはpowersehll自体を再起動・定数は変えられないっぽい・読み込み済みでもエラーにならないように"Ignore"をつけてる）
    Set-Variable $Name -Value $value -Scope "Global" -Option "Constant" -ErrorAction "Ignore"

}

SetGlobalConst "SCRIPT_ROOT" (Split-Path $PSScriptRoot -Parent)
SetGlobalConst "RESOURCES_PATH" (Join-Path $SCRIPT_ROOT "resources")

# 各種設定ファイル等
SetGlobalConst "SETTING_JSON" (Join-Path $SCRIPT_ROOT "settings.json")

SetGlobalConst "RUNNING_ICON_FILE" (Join-Path $RESOURCES_PATH "cursolRunnning.ico")
SetGlobalConst "STOPPING_ICON_FILE" (Join-Path $RESOURCES_PATH "cursolStopping.ico")
SetGlobalConst "INVALID_ICON_FILE" (Join-Path $RESOURCES_PATH "cursolInvalid.ico")

