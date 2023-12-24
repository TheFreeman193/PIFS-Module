using namespace System.IO

[CmdletBinding()]
param (
    [DirectoryInfo]$SourceDir = (Join-Path $PSScriptRoot '../src'),
    [DirectoryInfo]$DestDir = (Join-Path $PSScriptRoot '../.output/module')
)
process {

    if (Test-Path $DestDir -PathType Container) {
        $PSCmdlet.WriteVerbose('Clearing existing output directory...')
        Remove-Item $DestDir -Recurse -Force
    }
    $PSCmdlet.WriteVerbose('Copying module source files...')
    Copy-Item $SourceDir $DestDir -Recurse -Force
}
