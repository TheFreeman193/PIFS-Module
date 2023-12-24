using namespace System.IO

[CmdletBinding()]
param (
    [DirectoryInfo]$SourceDir = (Join-Path $PSScriptRoot '../src'),
    [DirectoryInfo]$DestDir = (Join-Path $PSScriptRoot '../.output/module')
)
begin {
    $SourceRootPattern = [regex]::Escape($SourceDir.FullName.Trim('/\'))
    filter TranslateToDest {
        param ([FileSystemInfo]$Source)
        if ($Source -is [DirectoryInfo]) {
            $OutputType = [DirectoryInfo]
        } else {
            $OutputType = [FileInfo]
        }
        $LeafPath = $Source.FullName -replace "^$SourceRootPattern"
        (Join-Path $DestDir.FullName $LeafPath) -as $OutputType
    }
}
process {

    $Files = Get-ChildItem $SourceDir -File
    $Dirs = Get-ChildItem $SourceDir -Directory

    $PSCmdlet.WriteVerbose("Copying root files...")
    $Files | Copy-Item -Destination $DestDir -Force

    $PSCmdlet.WriteVerbose("Copying subdirectories...")
    $Dirs.ForEach{
        $Dest = TranslateToDest $_
        if (Test-Path $Dest -PathType Container) {
            Remove-Item $Dest -Force -Recurse
        }
        Copy-Item $_ $Dest -Force -Recurse
    }
}
