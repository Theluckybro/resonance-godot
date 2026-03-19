param(
    [string]$ProjectRoot = ""
)

$ErrorActionPreference = "Stop"

if ($ProjectRoot -ne "") {
    $repoRoot = Resolve-Path $ProjectRoot
} else {
    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
}

$projectFile = Join-Path $repoRoot "project.godot"
$playerSceneFile = Join-Path $repoRoot "scenes/player/player.tscn"
$playerAssetsDir = Join-Path $repoRoot "assets/Sprites/Player"
$playerFinalAssetsDir = Join-Path $playerAssetsDir "Final16x32"

$failures = New-Object System.Collections.Generic.List[string]
$passes = New-Object System.Collections.Generic.List[string]

function Add-Pass {
    param([string]$Message)
    $passes.Add($Message) | Out-Null
}

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message) | Out-Null
}

function Add-Warning {
    param([string]$Message)
    Write-Output ("WARNING: {0}" -f $Message)
}

function Require-Contains {
    param(
        [string]$Content,
        [string]$Needle,
        [string]$Label
    )

    if ($Content.Contains($Needle)) {
        Add-Pass $Label
    } else {
        Add-Failure "$Label (missing: $Needle)"
    }
}

function Read-PngSize {
    param([string]$FilePath)

    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    if ($bytes.Length -lt 24) {
        throw "PNG too small: $FilePath"
    }

    # PNG signature check
    $signature = @(137, 80, 78, 71, 13, 10, 26, 10)
    for ($i = 0; $i -lt $signature.Count; $i++) {
        if ($bytes[$i] -ne $signature[$i]) {
            throw "Invalid PNG signature: $FilePath"
        }
    }

    $width = (($bytes[16] -shl 24) -bor ($bytes[17] -shl 16) -bor ($bytes[18] -shl 8) -bor $bytes[19])
    $height = (($bytes[20] -shl 24) -bor ($bytes[21] -shl 16) -bor ($bytes[22] -shl 8) -bor $bytes[23])

    return @($width, $height)
}

if (-not (Test-Path -LiteralPath $projectFile)) {
    throw "File not found: $projectFile"
}
if (-not (Test-Path -LiteralPath $playerSceneFile)) {
    throw "File not found: $playerSceneFile"
}
if (-not (Test-Path -LiteralPath $playerAssetsDir)) {
    throw "Directory not found: $playerAssetsDir"
}
if (-not (Test-Path -LiteralPath $playerFinalAssetsDir)) {
    throw "Directory not found: $playerFinalAssetsDir"
}

$projectContent = Get-Content -LiteralPath $projectFile -Raw -Encoding UTF8
$sceneContent = Get-Content -LiteralPath $playerSceneFile -Raw -Encoding UTF8

# Project settings validation
Require-Contains -Content $projectContent -Needle 'window/stretch/mode="viewport"' -Label "Stretch mode uses viewport"
Require-Contains -Content $projectContent -Needle 'window/stretch/scale_mode="integer"' -Label "Scale mode uses integer"
Require-Contains -Content $projectContent -Needle 'textures/canvas_textures/default_texture_filter=0' -Label "Default texture filter is nearest"
Require-Contains -Content $projectContent -Needle '2d/snap/snap_2d_transforms_to_pixel=true' -Label "2D transform snap to pixel enabled"
Require-Contains -Content $projectContent -Needle '2d/snap/snap_2d_vertices_to_pixel=true' -Label "2D vertices snap to pixel enabled"

# Player frame region validation (must be 16x32)
$regionPattern = '(?m)^\s*region\s*=\s*Rect2\(\s*[-\d\.]+\s*,\s*[-\d\.]+\s*,\s*(?<w>[-\d\.]+)\s*,\s*(?<h>[-\d\.]+)\s*\)\s*$'
$regionMatches = [regex]::Matches($sceneContent, $regionPattern)
if ($regionMatches.Count -eq 0) {
    Add-Failure "No player frame region Rect2 entries found in player scene"
} else {
    $invalidRegions = @()
    foreach ($match in $regionMatches) {
        $w = [double]::Parse($match.Groups["w"].Value, [System.Globalization.CultureInfo]::InvariantCulture)
        $h = [double]::Parse($match.Groups["h"].Value, [System.Globalization.CultureInfo]::InvariantCulture)
        if (($w -ne 16.0) -or ($h -ne 32.0)) {
            $invalidRegions += $match.Value.Trim()
        }
    }

    if ($invalidRegions.Count -eq 0) {
        Add-Pass "All player frame regions are 16x32"
    } else {
        Add-Failure ("Found non-16x32 frame regions: " + ($invalidRegions -join " | "))
    }
}

# Sword region validation (also 16x32)
$swordRegionPattern = '(?m)^\s*region_rect\s*=\s*Rect2\(\s*[-\d\.]+\s*,\s*[-\d\.]+\s*,\s*(?<w>[-\d\.]+)\s*,\s*(?<h>[-\d\.]+)\s*\)\s*$'
$swordRegionMatch = [regex]::Match($sceneContent, $swordRegionPattern)
if ($swordRegionMatch.Success) {
    $sw = [double]::Parse($swordRegionMatch.Groups["w"].Value, [System.Globalization.CultureInfo]::InvariantCulture)
    $sh = [double]::Parse($swordRegionMatch.Groups["h"].Value, [System.Globalization.CultureInfo]::InvariantCulture)
    if (($sw -eq 16.0) -and ($sh -eq 32.0)) {
        Add-Pass "Sword region is 16x32"
    } else {
        Add-Failure "Sword region is not 16x32"
    }
} else {
    Add-Failure "Sword region_rect not found"
}

# Guard against random visual wobble from AnimatedSprite2D animation tracks.
$animatedSpriteTrackPattern = 'NodePath\("AnimatedSprite2D:(position|offset)"\)'
if ([regex]::IsMatch($sceneContent, $animatedSpriteTrackPattern)) {
    Add-Failure "Animation tracks modify AnimatedSprite2D position/offset"
} else {
    Add-Pass "No animation track modifies AnimatedSprite2D position/offset"
}

# Ensure AnimatedSprite2D anchor position remains the agreed baseline.
$animatedPositionPattern = '(?s)\[node name="AnimatedSprite2D".*?\nposition = Vector2\((?<x>[-\d\.]+), (?<y>[-\d\.]+)\)'
$animatedPositionMatch = [regex]::Match($sceneContent, $animatedPositionPattern)
if ($animatedPositionMatch.Success) {
    $px = [double]::Parse($animatedPositionMatch.Groups["x"].Value, [System.Globalization.CultureInfo]::InvariantCulture)
    $py = [double]::Parse($animatedPositionMatch.Groups["y"].Value, [System.Globalization.CultureInfo]::InvariantCulture)
    if (($px -eq 0.0) -and ($py -eq -7.0)) {
        Add-Pass "AnimatedSprite2D baseline position is Vector2(0, -7)"
    } else {
        Add-Failure ("AnimatedSprite2D baseline changed: Vector2({0}, {1})" -f $px, $py)
    }
} else {
    Add-Failure "AnimatedSprite2D node position not found"
}

# Validate new player PNG dimensions against 16x32 grid.
$legacyRootPngAllowList = @(
    "Attack.png",
    "Dash.png",
    "Death.png",
    "Hit.png",
    "Idle.png",
    "PlayerSprite.png",
    "Run.png"
)

$rootPngFiles = Get-ChildItem -LiteralPath $playerAssetsDir -File -Filter "*.png"
$unexpectedRootPngs = @()
foreach ($file in $rootPngFiles) {
    if ($legacyRootPngAllowList -notcontains $file.Name) {
        $unexpectedRootPngs += $file.Name
    }
}

if ($unexpectedRootPngs.Count -gt 0) {
    Add-Failure ("New player PNG found outside Final16x32 folder: " + ($unexpectedRootPngs -join ", "))
} else {
    Add-Pass "No misplaced new player PNG in assets/Sprites/Player root"
}

$legacyMismatches = @()
foreach ($file in $rootPngFiles) {
    if ($legacyRootPngAllowList -contains $file.Name) {
        $size = Read-PngSize -FilePath $file.FullName
        $width = [int]$size[0]
        $height = [int]$size[1]
        if (($width % 16 -ne 0) -or ($height % 32 -ne 0)) {
            $legacyMismatches += ("{0} ({1}x{2})" -f $file.Name, $width, $height)
        }
    }
}
if ($legacyMismatches.Count -gt 0) {
    Add-Warning ("Legacy player PNG not on 16x32 grid (kept as legacy): " + ($legacyMismatches -join ", "))
}

$finalPngFiles = Get-ChildItem -LiteralPath $playerFinalAssetsDir -File -Filter "*.png"
if ($finalPngFiles.Count -eq 0) {
    Add-Pass "Final16x32 folder exists and is ready for new compliant player assets"
} else {
    $invalidFinalPngs = @()
    foreach ($file in $finalPngFiles) {
        $size = Read-PngSize -FilePath $file.FullName
        $width = [int]$size[0]
        $height = [int]$size[1]

        if (($width % 16 -ne 0) -or ($height % 32 -ne 0)) {
            $invalidFinalPngs += ("{0} ({1}x{2})" -f $file.Name, $width, $height)
        }
    }

    if ($invalidFinalPngs.Count -eq 0) {
        Add-Pass "All Final16x32 player PNG files align to 16x32 frame grid"
    } else {
        Add-Failure ("Final16x32 PNG outside 16x32 grid: " + ($invalidFinalPngs -join ", "))
    }
}

Write-Output "=== Player Pixel Spec Validation ==="
Write-Output ("Repository: {0}" -f $repoRoot)
Write-Output ""

Write-Output "PASS checks:"
foreach ($line in $passes) {
    Write-Output ("  - {0}" -f $line)
}

if ($failures.Count -gt 0) {
    Write-Output ""
    Write-Output "FAIL checks:"
    foreach ($line in $failures) {
        Write-Output ("  - {0}" -f $line)
    }
    Write-Output ""
    Write-Error "Player pixel specification validation failed."
    exit 1
}

Write-Output ""
Write-Output "Result: PASS"
