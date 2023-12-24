using namespace System.IO

[CmdletBinding()]
param (
    [DirectoryInfo]$DestDir = (Join-Path $PSScriptRoot '../.output')
)
process {
    if (Test-Path $DestDir -PathType Container) {
        $PSCmdlet.WriteVerbose('Clearing output directory...')
        Remove-Item $DestDir -Recurse -Force
    }
    $null = New-Item -ItemType Directory -Path $DestDir -Force
}
