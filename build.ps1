[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = $PSScriptRoot
$pluginXmlPath = Join-Path $repositoryRoot 'plugin.xml'
[xml]$pluginXml = Get-Content -LiteralPath $pluginXmlPath
$pluginName = $pluginXml.plugin.name
$pluginVersion = $pluginXml.plugin.version
$outputDirectory = Join-Path $repositoryRoot "dist\$pluginName"
$outputPath = Join-Path $outputDirectory "${pluginName}_${pluginVersion}.zip"
$stagingDirectory = Join-Path ([System.IO.Path]::GetTempPath()) (
    'enrollment-express-form-explorer-' + [guid]::NewGuid().ToString('N')
)

try {
    New-Item -ItemType Directory -Path $stagingDirectory | Out-Null
    Copy-Item -LiteralPath $pluginXmlPath -Destination $stagingDirectory
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'pagecataloging') -Destination $stagingDirectory -Recurse
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'web_root') -Destination $stagingDirectory -Recurse

    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    Compress-Archive -Path (Join-Path $stagingDirectory '*') -DestinationPath $outputPath -Force
    Write-Output $outputPath
}
finally {
    if (Test-Path -LiteralPath $stagingDirectory) {
        $resolvedStagingDirectory = [System.IO.Path]::GetFullPath($stagingDirectory)
        $resolvedTempDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())

        if (-not $resolvedStagingDirectory.StartsWith(
            $resolvedTempDirectory,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Refusing to remove staging directory outside the temporary directory."
        }

        Remove-Item -LiteralPath $resolvedStagingDirectory -Recurse -Force
    }
}
