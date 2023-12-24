using namespace System.IO

[CmdletBinding()]
param (
    [string]$UpdateUrl = 'https://sourceforge.net/projects/xiaomi-eu-multilang-miui-roms/rss?path=/xiaomi.eu/Xiaomi.eu-app',
    [FileInfo]$ApkPath = (Join-Path $PSScriptRoot '../.output/xiaomieu/latest.apk'),
    [FileInfo]$ToolPath = (Join-Path $PSScriptRoot 'apkpatch/tools/apktool_2.0.3-dexed.jar'),
    [FileInfo]$OutputPath = (Join-Path $PSScriptRoot '../.output/module/sources/xiaomi/pif.json')
)

begin {
    $ApkDir = $ApkPath.Directory
    $ExtractDir = Join-Path $ApkDir 'extract'
    $JPathBin = Get-Command 'java' -CommandType Application -ErrorAction Ignore -TotalCount 1
    if ($null -ne $JPathBin) {
        $JavaBin = $JPathBin.Path
    } else {
        if (-not [string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
            $JHomeBin = Get-Command (Join-Path $env:JAVA_HOME 'bin/java') -CommandType Application -ErrorAction Ignore -TotalCount 1
            if (Test-Path $JHomeBin.Path) {
                $JavaBin = $JHomeBin.Path
            }
        }
    }
    if ([string]::IsNullOrWhiteSpace($JavaBin)) {
        throw "Couldn't find a Java runtime. Stopping."
    }
    $PSCmdlet.WriteVerbose("Java binary: $JavaBin")
    if (-not (Test-Path $ToolPath -PathType Leaf)) {
        throw "Couldn't find apktool. Stopping."
    }
    $PSCmdlet.WriteVerbose("apktool binary: $ToolPath")
    if (-not (Test-Path $ExtractDir -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $ExtractDir
    }
    $UpdateFile = Join-Path $ApkDir 'update'
}

process {
    $Feed = Invoke-RestMethod -Method Get -Uri $UpdateUrl
    $LatestDate = [datetime]::MinValue
    $RawLatest = ($Feed | Measure-Object -Maximum -Property pubDate).Maximum
    if (-not [datetime]::TryParseExact($RawLatest, 'ddd, dd MMM yyyy HH:mm:ss" UT"', $Host.CurrentCulture.DateTimeFormat, 'AssumeUniversal', [ref]$LatestDate)) {
        $LatestDate = [datetime]::UnixEpoch
    }
    [double]$Timestamp = 0
    if (Test-Path $UpdateFile -PathType Leaf) {
        $Timestamp = Get-Content $UpdateFile -TotalCount 1
    }
    $LatestLocal = [datetime]::UnixEpoch.AddSeconds($Timestamp)
    if ($LatestDate -gt $LatestLocal) {
        $PSCmdlet.WriteVerbose("Newer APK available from Xiaomi.EU. Downloading...")
        $LatestLink = $Feed.Where{ $_.pubDate -eq $RawLatest }[0].link
        if (Test-Path $ApkPath) {
            Remove-Item $ApkPath
        }
        curl -Lo $ApkPath.FullName $LatestLink
        if ($?) {
            $Timestamp = ($LatestDate - [datetime]::UnixEpoch).TotalSeconds -as [string]
            Set-Content $UpdateFile $Timestamp -NoNewLine
        } else {
            $PSCmdlet.WriteWarning("Couldn't get latest apk from '$LatestLink'")
        }
    } else {
        $PSCmdlet.WriteVerbose("Already have latest APK from Xiaomi.EU")
    }
    if (-not (Test-Path $ApkPath -PathType Leaf)) {
        throw 'No APK file to extract values from. Stopping.'
    }
    $PSCmdlet.WriteVerbose('Extracting APK...')
    &$JavaBin -jar $ToolPath.FullName -q decode -fsp $ExtractDir -o $ExtractDir $ApkPath.FullName
    if ($?) {
        $PSCmdlet.WriteVerbose("APK contents extracted sucessfully")
    } else {
        throw "Extraction of Xiaomi.EU app APK failed. Stopping."
    }
    $PSCmdlet.WriteVerbose('Parsing profile XML...')
    $ProfilePath = Join-Path $ExtractDir 'res/xml/inject_fields.xml'
    if (-not (Test-Path $ProfilePath -PathType Leaf)) {
        throw "Xiaomi.EU profile XML not found. Stopping."
    }
    [xml]$Profile = Get-Content $ProfilePath
    if ($null -eq $Profile) {
        throw "Failed to parse Xiaomi.EU profile XML. Stopping."
    }
    $Output = [ordered]@{}
    $Profile.'inject-fields'.trigger.filter.class.field.Where{
        $_.type -eq 'string'
    }.ForEach{
        $Output[$_.name] = $_.value
    }
    $Output['FIRST_API_LEVEL'] = '21'
    if ($Output['FINGERPRINT'] -match '(?<brand>[^/]+)/(?<name>[^/]+)/(?<device>[^:/]+):(?<release>[^/]+)/(?<id>[^/]+)/(?<inc>[^:/]+):(?<type>[^/]+)/(?<tags>[^:/]+)') {
        $Output['TYPE'] = $Matches['type']
        $Output['TAGS'] = $Matches['tags']
        $Output['INCREMENTAL'] = $Matches['inc']
        $Output['BUILD_ID'] = $Matches['id']
        if ([string]::IsNullOrWhiteSpace($Output['BRAND'])) { $Output['BRAND'] = $Matches['brand'] }
        if ([string]::IsNullOrWhiteSpace($Output['PRODUCT'])) { $Output['PRODUCT'] = $Matches['name'] }
        if ([string]::IsNullOrWhiteSpace($Output['DEVICE'])) { $Output['DEVICE'] = $Matches['device'] }
    }
    $PSCmdlet.WriteVerbose('Writing profile JSON...')
    $OutDir = Split-Path $OutputPath
    if (-not (Test-Path $OutDir -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $OutDir
    }
    [pscustomobject]$Output | ConvertTo-Json -Depth 1 | Out-File $OutputPath.FullName -NoNewline -Encoding ascii
}
