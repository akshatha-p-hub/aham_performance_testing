param(
    [ValidateRange(1, 10000)]
    [int]$Count = 300,

    [ValidateNotNullOrEmpty()]
    [string]$EmailDomain = 'example.test',

    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = 'aham-test-users.csv'
)

$rows = [System.Collections.Generic.List[string]]::new()
$rows.Add('email,password')

for ($i = 1; $i -le $Count; $i++) {
    $email = 'load-user-{0:D3}@{1}' -f $i, $EmailDomain
    $rows.Add('"{0}","REPLACE_WITH_VALID_STAGING_PASSWORD"' -f $email)
}

$resolvedPath = [System.IO.Path]::GetFullPath($OutputPath)
if (Test-Path -LiteralPath $resolvedPath) {
    throw "Refusing to overwrite existing file: $resolvedPath"
}

[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($resolvedPath)) | Out-Null
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllLines($resolvedPath, $rows, $utf8NoBom)
Write-Output "Created $Count placeholder account rows at $resolvedPath. Replace all placeholder emails/passwords with provisioned staging test accounts before running JMeter."
