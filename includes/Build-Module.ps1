using namespace System.IO

[CmdletBinding()]
param (
    [DirectoryInfo]$SourceDir = (Join-Path $PSScriptRoot '../.output/module'),
    [DirectoryInfo]$DestFile = (Join-Path $PSScriptRoot '../.output/pifpicker.zip'),
    [DirectoryInfo]$ToolsDir = $PSScriptRoot
)
begin {
    $Timestamp = Get-Date -Format 'yyyy-MM-ddTHH-mm-ss'
    Start-Transcript -Path (Join-Path (Split-Path $SourceDir) "Build_$Timestamp.log")
    $ChecksumFiles = @(
        'META-INF/com/google/android/update-binary'
        'META-INF/com/google/android/updater-script'
        'system/bin/pifs'
        'utils/utils.sh'
        'customize.sh'
        'service.sh'
        'module.prop'
    )
}
process {
    $PSCmdlet.WriteVerbose("Updating submodules...")
    git submodule update --init
    if (-not $?) { return }

    & (Join-Path $ToolsDir 'New-ModuleSource.ps1')
    if (-not $?) { return }

    & (Join-Path $ToolsDir 'Copy-PifsProfiles.ps1')
    if (-not $?) { return }

    & (Join-Path $ToolsDir 'Get-XiaomiEuProfile.ps1')
    if (-not $?) { return }

    $PSCmdlet.WriteVerbose("Generating checksums for $($ChecksumFiles.Count) files...")
    $Checksums = ''
    $ChecksumFiles.ForEach{
        $Target = Join-Path $SourceDir $_
        $Sum = (Get-FileHash -Path $Target -Algorithm SHA256).Hash
        $Checksums += "`n$Sum  $_"
    }
    Set-Content (Join-Path $SourceDir 'SHA256SUMS') $Checksums.Trim(" `n`t") -NoNewline

    if (-not $?) { return }

    Compress-Archive -Path "$SourceDir/*" -DestinationPath $DestFile -CompressionLevel Optimal -Force

    if (-not $?) { return }

    $PSCmdlet.WriteVerbose("Build succeeded.")
}
end {
    Stop-Transcript
}
