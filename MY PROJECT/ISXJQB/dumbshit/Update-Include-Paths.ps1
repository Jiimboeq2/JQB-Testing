param (
    [string]$rootPath,
    [string]$outputFile = "GeneratedIncludePaths.props"
)

function Get-RelativePath {
    param (
        [string]$from,
        [string]$to
    )
    $fromUri = New-Object System.Uri($from)
    $toUri = New-Object System.Uri($to)
    return  ".\$($fromUri.MakeRelativeUri($toUri).ToString().Replace('/', '\'))"
}

function Get-Subdirectories {
    param ([string]$path)
    Get-ChildItem -Path $path -Directory -Recurse | ForEach-Object { $_.FullName }
}

$includePaths = Get-Subdirectories -path $rootPath
$relativePaths = $includePaths | ForEach-Object { Get-RelativePath -from $rootPath -to $_ }
$propsContent = "<Project>`n  <PropertyGroup>`n    <IncludePath>"
$propsContent += ($relativePaths -join ';') + '</IncludePath>`n  </PropertyGroup>`n</Project>'

$propsContent -replace '`n', "`r`n" | Out-File -FilePath $outputFile -Encoding UTF8
