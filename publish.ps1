$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$repo = 'Stedvorak/mlr-ex08'
$expectedUrl = 'https://stedvorak.github.io/mlr-ex08/'

function Invoke-Gh {
    param([string[]]$Arguments)
    $output = & gh @Arguments
    if ($LASTEXITCODE -ne 0) { throw "gh failed: $($Arguments -join ' ')" }
    return $output
}

function Invoke-Git {
    param([string[]]$Arguments)
    & git @Arguments
    if ($LASTEXITCODE -ne 0) { throw "git failed: $($Arguments -join ' ')" }
}

$login = Invoke-Gh -Arguments @('api', 'user', '--jq', '.login')
if ($login -ine 'Stedvorak') { throw 'Use the Stedvorak GitHub account: the page and QR target that account.' }

$repoList = (Invoke-Gh -Arguments @('repo', 'list', 'Stedvorak', '--limit', '1000', '--json', 'nameWithOwner')) | ConvertFrom-Json
if ($repoList.nameWithOwner -notcontains $repo) {
    Invoke-Gh -Arguments @('repo', 'create', $repo, '--public', '--description', 'Live leaf classification with ONNX Runtime Web, rear camera and photo upload')
}
$repoInfo = (Invoke-Gh -Arguments @('repo', 'view', $repo, '--json', 'visibility')) | ConvertFrom-Json
if ($repoInfo.visibility -ne 'PUBLIC') { throw 'The existing repository is private; refusing to change its visibility automatically.' }

if (!(Test-Path -LiteralPath '.git')) { Invoke-Git -Arguments @('init', '-b', 'main') }
$branch = & git branch --show-current
if ($branch -ne 'main') { throw 'Expected the local main branch.' }
$remotes = & git remote
if ($remotes -notcontains 'origin') {
    Invoke-Git -Arguments @('remote', 'add', 'origin', "https://github.com/$repo.git")
} else {
    $origin = & git remote get-url origin
    if ($origin -notin @("https://github.com/$repo.git", "https://github.com/$repo", "git@github.com:$repo.git")) { throw 'origin points at a different repository.' }
}

$readme = Get-Content -LiteralPath 'README.md' -Raw -Encoding UTF8
$readme = $readme.Replace('Publication is pending. This URL is the intended GitHub Pages address; it has not yet been verified online.', 'Configured for GitHub Pages from the root of the main branch. The publishing script verifies the live page before reporting success.')
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'README.md'), $readme, [Text.UTF8Encoding]::new($false))
Invoke-Git -Arguments @('add', '--', 'index.html', 'README.md', 'publish.ps1', '.gitignore', 'leaf_model.onnx', 'model_info.json', 'check_image.jpg', 'check_expected.json')
& git diff --cached --quiet
if ($LASTEXITCODE -eq 1) { Invoke-Git -Arguments @('commit', '-m', 'Build mobile leaf classifier with reference check and app QR') }
elseif ($LASTEXITCODE -ne 0) { throw 'Cannot inspect the staged changes.' }
Invoke-Gh -Arguments @('auth', 'setup-git')
Invoke-Git -Arguments @('push', '-u', 'origin', 'main')

# GET distinguishes an absent Pages site from authentication/server failures.
$ErrorActionPreference = 'Continue'
$pagesOutput = & gh api "repos/$repo/pages" 2>&1
$pagesExitCode = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($pagesExitCode -ne 0) {
    if (($pagesOutput -join "`n") -notmatch '404') { throw ($pagesOutput -join "`n") }
    Invoke-Gh -Arguments @('api', '--method', 'POST', "repos/$repo/pages", '-f', 'build_type=legacy', '-f', 'source[branch]=main', '-f', 'source[path]=/')
} else {
    Invoke-Gh -Arguments @('api', '--method', 'PUT', "repos/$repo/pages", '-f', 'build_type=legacy', '-f', 'source[branch]=main', '-f', 'source[path]=/')
}
$invite = Invoke-Gh -Arguments @('api', '--method', 'PUT', "repos/$repo/collaborators/MLRteacher", '-f', 'permission=push')
Write-Host 'MLRteacher collaborator invitation requested.'
$pages = (Invoke-Gh -Arguments @('api', "repos/$repo/pages")) | ConvertFrom-Json
if ($pages.html_url -ine $expectedUrl) { throw "Pages URL $($pages.html_url) does not match the QR URL $expectedUrl." }

Write-Host "Waiting for $expectedUrl"
$deadline = (Get-Date).AddMinutes(12)
$online = $false
do {
    $ErrorActionPreference = 'Continue'
    $buildOutput = & gh api "repos/$repo/pages/builds/latest" 2>&1
    $buildExitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($buildExitCode -ne 0) {
        if (($buildOutput -join "`n") -notmatch '404') { throw ($buildOutput -join "`n") }
        Start-Sleep -Seconds 15
        continue
    }
    $build = ($buildOutput -join "`n") | ConvertFrom-Json
    if ($build.status -eq 'errored') { throw "Pages build failed: $($build.error.message)" }
    if ($build.status -eq 'built') {
        try {
            $response = Invoke-WebRequest -Uri $expectedUrl -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' }
            if ($response.StatusCode -eq 200) {
                $localHtml = Get-Content -LiteralPath 'index.html' -Raw -Encoding UTF8
                if ($response.Content.Trim() -ceq $localHtml.Trim()) { $online = $true; break }
            }
        } catch { Write-Host 'Pages is still propagating.' }
    }
    Start-Sleep -Seconds 15
} while ((Get-Date) -lt $deadline)
if (!$online) { throw 'Timed out waiting for the deployed page. Rerun this script to check again.' }

# The QR was independently decoded locally. Compare that exact SVG in the live
# HTML and ensure its declared target and adjacent link match GitHub's Pages URL.
$liveTarget = [regex]::Match($response.Content, "const PUBLIC_URL = '([^']+)';").Groups[1].Value
$localQr = [regex]::Match($localHtml, '(?m)^const QR_SVG = (.+);$').Groups[1].Value
$liveQr = [regex]::Match($response.Content, '(?m)^const QR_SVG = (.+);$').Groups[1].Value
if ($liveTarget -cne $expectedUrl -or !$localQr -or $liveQr -cne $localQr -or !$response.Content.Contains(('href="' + $expectedUrl + '"'))) {
    throw 'The deployed QR or clickable URL does not match the verified app URL.'
}
Write-Host "Online, with verified QR target: $expectedUrl"
Write-Host "Repository: https://github.com/$repo"
