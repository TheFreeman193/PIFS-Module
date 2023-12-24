using namespace System.IO

[CmdletBinding()]
param (
    [DirectoryInfo]$SourceDir = (Join-Path $PSScriptRoot 'pifs/JSON'),
    [DirectoryInfo]$DestDir = (Join-Path $PSScriptRoot '../.output/module/sources/pifs'),
    [switch]$Force
)
begin {
    $SourceRootPattern = [regex]::Escape($SourceDir.FullName.Trim('/\'))
    $DestRootPattern = [regex]::Escape($DestDir.FullName.Trim('/\'))
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
    filter TranslateToSource {
        param ([FileSystemInfo]$Dest)
        if ($Dest -is [DirectoryInfo]) {
            $OutputType = [DirectoryInfo]
        } else {
            $OutputType = [FileInfo]
        }
        $LeafPath = $Dest.FullName -replace "^$DestRootPattern"
        (Join-Path $SourceDir.FullName $LeafPath) -as $OutputType
    }
    $SourceVersion = Get-Content (Join-Path $SourceDir 'VERSION') -TotalCount 1 -ErrorAction Ignore
    $DestVersion = Get-Content (Join-Path $DestDir 'VERSION') -TotalCount 1 -ErrorAction Ignore
    if ($Force -or [string]::IsNullOrWhiteSpace($SourceVersion) -or [string]::IsNullOrWhiteSpace($DestVersion) -or
    ($SourceVersion -as [uint]) -gt ($DestVersion -as [uint])) {
        $ShouldContinue = $true
    } else {
        $ShouldContinue = $false
        $PSCmdlet.WriteVerbose('PIFS collection VERSION file matches destination. Use -Force to update anyway.')
    }
}
process {
    if (-not $ShouldContinue) { return }
    if (-not (Test-Path $SourceDir -PathType Container)) {
        throw "Couldn't find profiles source '$SourceDir'. Stopping."
    }
    if (-not (Test-Path $DestDir -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $DestDir
    }
    $PSCmdlet.WriteVerbose("Checking for orphaned profiles...")
    $DestProfiles = Get-ChildItem -Path $DestDir -File -Force -Recurse
    $DestProfiles.ForEach{
        if (-not (Test-Path (TranslateToSource $_) -PathType Leaf)) {
            $PSCmdlet.WriteVerbose("Purging profile no longer in PIFS source: '$_'")
            Remove-Item $_
        }
    }
    $PSCmdlet.WriteVerbose("Copying profiles...")
    $Profiles = Get-ChildItem -Path $SourceDir -File -Force -Recurse
    $Profiles.ForEach{
        $Dest = TranslateToDest $_
        $ShouldCopy = $false
        if (Test-Path $Dest -PathType Leaf) {
            if ($_.LastWriteTime -gt $Dest.LastWriteTime -or $_.Length -ne $Dest.Length) {
                $PSCmdlet.WriteDebug("Copying updated profile: '$_'")
                $ShouldCopy = $true
            }
        } else {
            $PSCmdlet.WriteDebug("Copying new profile: '$_'")
            $Container = Split-Path $Dest -Parent
            if (-not (Test-Path $Container -PathType Container)) {
                $null = New-Item -ItemType Directory -Path $Container
            }
            $ShouldCopy = $true
        }
        if ($ShouldCopy) {
            Copy-Item $_ $Dest -Force
        }
    }
}
