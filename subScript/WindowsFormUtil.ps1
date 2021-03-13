
function NewToolStripMenuItem {
    param (
        [Parameter(Mandatory)]
        [string] $name,
        [Parameter(Mandatory)]
        [scriptblock] $action
    )
    $menuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuItem.Text = $name
    # メニュークリック時のイベント
    $menuItem.Add_Click($action)
    return $menuItem
}
