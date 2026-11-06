param(
    [Parameter(Mandatory=$true)][string]$EngineZip,
    [string]$DataFolder = (Join-Path $env:USERPROFILE 'Downloads\AzerothSurvivorsWindowsNew\AzerothSurvivors\Data'),
    [string]$OutputIpa = (Join-Path $PSScriptRoot 'AzerothSurvivors-unsigned.ipa')
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$inputPath = (Resolve-Path -LiteralPath $EngineZip).Path
$dataPath = (Resolve-Path -LiteralPath $DataFolder).Path
$outputPath = [System.IO.Path]::GetFullPath($OutputIpa)
if (Test-Path -LiteralPath $outputPath) { throw "Output already exists: $outputPath" }
$archives = @(Get-ChildItem -LiteralPath $dataPath -File | Where-Object { $_.Extension -ieq '.MPQ' })
if ($archives.Count -eq 0) { throw 'No MPQ game data found.' }
$prefix = 'Payload/AzerothSurvivors.app/'
$sourceZip = [System.IO.Compression.ZipFile]::OpenRead($inputPath)
try {
    $executable = $sourceZip.GetEntry($prefix + 'AzerothSurvivors')
    $plist = $sourceZip.GetEntry($prefix + 'Info.plist')
    if (!$executable -or !$plist) { throw 'Use iphone-engine.zip inside the downloaded GitHub artifact ZIP.' }
    $reader = [System.IO.BinaryReader]::new($executable.Open())
    try {
        $machMagic = [uint32]::Parse('FEEDFACF', [System.Globalization.NumberStyles]::HexNumber)
        if ($reader.ReadUInt32() -ne $machMagic -or $reader.ReadUInt32() -ne 0x0100000C) {
            throw 'Engine is not a native ARM64 Mach-O binary.'
        }
    } finally { $reader.Dispose() }
    $destination = [System.IO.Compression.ZipFile]::Open($outputPath, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($entry in $sourceZip.Entries) {
            if ($entry.FullName.EndsWith('/')) { continue }
            if (!$entry.FullName.StartsWith($prefix) -or $entry.FullName.Contains('..') -or $entry.FullName.Contains('\')) {
                throw 'Unexpected archive path.'
            }
            $copy = $destination.CreateEntry($entry.FullName, [System.IO.Compression.CompressionLevel]::Fastest)
            $copy.ExternalAttributes = $entry.ExternalAttributes
            $sourceStream = $entry.Open()
            $destinationStream = $copy.Open()
            try { $sourceStream.CopyTo($destinationStream) }
            finally { $destinationStream.Dispose(); $sourceStream.Dispose() }
        }
        foreach ($archive in $archives) {
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $destination, $archive.FullName, $prefix + 'Data/' + $archive.Name,
                [System.IO.Compression.CompressionLevel]::NoCompression
            ) | Out-Null
        }
    } finally { $destination.Dispose() }
} catch {
    # Never leave an incomplete file labelled as an IPA.
    if (Test-Path -LiteralPath $outputPath) { Remove-Item -LiteralPath $outputPath }
    throw
} finally { $sourceZip.Dispose() }
Write-Output "Created unsigned IPA: $outputPath"
Write-Output 'It must be signed by your sideloading tool before installation. Device testing is still required.'
