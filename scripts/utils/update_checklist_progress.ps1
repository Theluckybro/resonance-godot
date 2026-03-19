param(
    [string]$ChecklistPath = "docs/ASSET_CHECKLIST_MVP.md"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$checklistFile = Join-Path $repoRoot $ChecklistPath

if (-not (Test-Path -LiteralPath $checklistFile)) {
    throw "Checklist file not found: $ChecklistPath"
}

$content = Get-Content -LiteralPath $checklistFile -Raw -Encoding UTF8
$newline = if ($content.Contains("`r`n")) { "`r`n" } else { "`n" }

$itemPattern = '(?m)^\s*-\s\[(?<state>[ xX])\]\s.+\[(?<priority>P[0-2])\]\s*$'
$matches = [regex]::Matches($content, $itemPattern)

if ($matches.Count -eq 0) {
    throw "No checklist items with [P0]/[P1]/[P2] tags found."
}

$priorityOrder = @("P0", "P1", "P2")
$stats = @{}
foreach ($priority in $priorityOrder) {
    $stats[$priority] = [ordered]@{
        Done = 0
        Total = 0
    }
}

foreach ($match in $matches) {
    $state = $match.Groups["state"].Value
    $priority = $match.Groups["priority"].Value

    $stats[$priority].Total += 1
    if ($state -match "[xX]") {
        $stats[$priority].Done += 1
    }
}

$totalDone = 0
$totalItems = 0
foreach ($priority in $priorityOrder) {
    $totalDone += [int]$stats[$priority].Done
    $totalItems += [int]$stats[$priority].Total
}

function Format-Percent {
    param(
        [int]$Done,
        [int]$Total
    )

    if ($Total -eq 0) {
        return "0.0%"
    }

    return ("{0:N1}%" -f (($Done * 100.0) / $Total))
}

$summaryLines = @()
$summaryLines += "<!-- PROGRESS_SUMMARY_START -->"
$summaryLines += ("_Auto-updated: {0}_" -f (Get-Date -Format "yyyy-MM-dd HH:mm"))
$summaryLines += ""
$summaryLines += "| Prioritas | Selesai | Total | Progress |"
$summaryLines += "| --- | ---: | ---: | ---: |"

foreach ($priority in $priorityOrder) {
    $done = [int]$stats[$priority].Done
    $total = [int]$stats[$priority].Total
    $percent = Format-Percent -Done $done -Total $total
    $summaryLines += ("| {0} | {1} | {2} | {3} |" -f $priority, $done, $total, $percent)
}

$overallPercent = Format-Percent -Done $totalDone -Total $totalItems
$summaryLines += ("| Total | {0} | {1} | {2} |" -f $totalDone, $totalItems, $overallPercent)
$summaryLines += "<!-- PROGRESS_SUMMARY_END -->"

$summaryBlock = ($summaryLines -join $newline)
$summaryPattern = '(?s)<!-- PROGRESS_SUMMARY_START -->.*?<!-- PROGRESS_SUMMARY_END -->'

if ([regex]::IsMatch($content, $summaryPattern)) {
    $updatedContent = [regex]::Replace($content, $summaryPattern, $summaryBlock, 1)
} else {
    $sectionHeader = "## Ringkasan Progress Otomatis"
    $insertBlock = @(
        $sectionHeader,
        "",
        "Jalankan `./scripts/utils/update_checklist_progress.ps1` setiap kali checklist berubah untuk memperbarui ringkasan ini.",
        "",
        $summaryBlock,
        ""
    ) -join $newline

    $anchorHeader = "## Tabel Kebutuhan Asset MVP"
    if ($content.Contains($anchorHeader)) {
        $updatedContent = $content.Replace($anchorHeader, ($insertBlock + $anchorHeader))
    } else {
        $updatedContent = $content + $newline + $newline + $insertBlock
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($checklistFile, $updatedContent, $utf8NoBom)

Write-Output ("Updated checklist summary: {0}" -f $ChecklistPath)
