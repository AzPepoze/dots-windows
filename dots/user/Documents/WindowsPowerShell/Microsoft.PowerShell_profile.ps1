$ompConfig = Join-Path $PSScriptRoot "1_shell.omp.json"
if (Test-Path $ompConfig) {
    oh-my-posh init pwsh --config $ompConfig | Invoke-Expression
}