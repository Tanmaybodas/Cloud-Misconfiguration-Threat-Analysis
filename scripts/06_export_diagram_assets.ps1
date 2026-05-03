param(
  [string]$OutDir = "infrastructure"
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force $OutDir | Out-Null

$pngPath = Join-Path $OutDir "cloud-misconfiguration-dfd.png"
$pdfPath = Join-Path $OutDir "cloud-misconfiguration-dfd.pdf"

Add-Type -AssemblyName System.Drawing

$width = 1600
$height = 1000
$bmp = New-Object System.Drawing.Bitmap $width, $height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::White)

function Brush($Hex) {
  return New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($Hex))
}

function Pen($Hex, $Width = 2, [bool]$Dashed = $false) {
  $p = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($Hex), $Width)
  if ($Dashed) {
    $p.DashPattern = @(8, 8)
  }
  return $p
}

function Text($Value, $X, $Y, $W, $H, $Size = 13, [bool]$Bold = $false, $Align = "Center") {
  $style = if ($Bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
  $font = New-Object System.Drawing.Font "Arial", $Size, $style
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = if ($Align -eq "Left") { [System.Drawing.StringAlignment]::Near } else { [System.Drawing.StringAlignment]::Center }
  $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
  $rect = New-Object System.Drawing.RectangleF $X, $Y, $W, $H
  $g.DrawString($Value, $font, (Brush "#111827"), $rect, $fmt)
  $font.Dispose()
  $fmt.Dispose()
}

function Zone($Label, $X, $Y, $W, $H, $Fill, $Stroke) {
  $rect = New-Object System.Drawing.Rectangle $X, $Y, $W, $H
  $g.FillRectangle((Brush $Fill), $rect)
  $g.DrawRectangle((Pen $Stroke 2 $true), $rect)
  Text $Label ($X + 10) ($Y + 10) ($W - 20) 50 13 $true "Center"
}

function Box($Label, $X, $Y, $W, $H, $Stroke) {
  $rect = New-Object System.Drawing.Rectangle $X, $Y, $W, $H
  $g.FillRectangle((Brush "#ffffff"), $rect)
  $g.DrawRectangle((Pen $Stroke 2 $false), $rect)
  Text $Label $X $Y $W $H 13 $true "Center"
}

function EllipseNode($Label, $X, $Y, $W, $H, $Stroke) {
  $rect = New-Object System.Drawing.Rectangle $X, $Y, $W, $H
  $g.FillEllipse((Brush "#ffffff"), $rect)
  $g.DrawEllipse((Pen $Stroke 2 $false), $rect)
  Text $Label $X $Y $W $H 13 $true "Center"
}

function Store($Label, $X, $Y, $W, $H, $Stroke) {
  $rect = New-Object System.Drawing.Rectangle $X, $Y, $W, $H
  $g.FillRectangle((Brush "#ffffff"), $rect)
  $g.DrawRectangle((Pen $Stroke 2 $false), $rect)
  $g.DrawEllipse((Pen $Stroke 2 $false), $X, $Y - 10, $W, 24)
  $g.DrawArc((Pen $Stroke 2 $false), $X, $Y + $H - 22, $W, 24, 0, 180)
  Text $Label $X ($Y + 8) $W ($H - 10) 12 $true "Center"
}

function Arrow($Label, $X1, $Y1, $X2, $Y2) {
  $p = Pen "#374151" 2 $false
  $cap = New-Object System.Drawing.Drawing2D.AdjustableArrowCap 5, 5
  $p.CustomEndCap = $cap
  $g.DrawLine($p, $X1, $Y1, $X2, $Y2)
  if ($Label.Trim().Length -gt 0) {
    $lx = [Math]::Min($X1, $X2) + [Math]::Abs($X2 - $X1) / 2 - 70
    $ly = [Math]::Min($Y1, $Y2) + [Math]::Abs($Y2 - $Y1) / 2 - 16
    Text $Label $lx $ly 140 32 10 $false "Center"
  }
}

Text "Cloud Misconfiguration Threat Analysis - Data Flow Diagram" 315 20 970 40 24 $true "Center"
Zone "Internet Zone`nTrust: untrusted" 40 80 280 760 "#fee2e2" "#b91c1c"
Zone "DMZ / Public Edge`nTrust: controlled public" 370 80 330 760 "#fef3c7" "#b45309"
Zone "Internal VPC`nTrust: private application/data" 750 80 470 760 "#dcfce7" "#15803d"
Zone "Admin Zone`nTrust: privileged identities" 1260 80 290 760 "#dbeafe" "#1d4ed8"

Box "External Entity`nInternet Users" 85 230 190 70 "#b91c1c"
Box "External Entity`nDevelopers" 1310 190 180 70 "#1d4ed8"
Box "External Entity`nCI/CD Pipeline" 1310 310 180 70 "#1d4ed8"
EllipseNode "Process`nAPI Gateway" 435 210 190 90 "#b45309"
EllipseNode "Process`nEC2 Web App" 435 410 190 90 "#b45309"
EllipseNode "Process`nLambda Functions" 815 210 190 90 "#15803d"
Store "Data Store`nS3 Bucket`n(misconfig: public ACL)" 800 530 190 100 "#15803d"
Store "Data Store`nRDS Database`n(misconfig: public, unencrypted)" 1020 530 190 100 "#15803d"
Store "Data Store`nSecrets Manager`n(intended control)" 910 700 190 100 "#15803d"
Box "Cloud Control Plane`nIAM Roles and Policies`n(misconfig: wildcard admin)" 1300 500 210 100 "#1d4ed8"

Text "TB-1 Internet / DMZ" 285 165 150 30 12 $true "Center"
Text "TB-2 DMZ / Internal" 655 165 170 30 12 $true "Center"
Text "TB-3 Admin / Control" 1160 165 190 30 12 $true "Center"
Text "TB-4 Service / Data" 845 445 170 30 12 $true "Center"

Arrow "HTTPS requests`nTB-1" 275 265 435 255
Arrow "HTTPS integration" 530 300 530 410
Arrow "Invoke`nTB-2" 625 250 815 250
Arrow "" 625 455 1020 580
Arrow "" 625 455 800 580
Arrow "" 910 300 895 530
Arrow "" 930 300 1005 700
Arrow "IAM / TB-3" 1400 260 1405 500
Arrow "Deploy / IAM" 1400 380 1405 500
Arrow "" 1300 550 625 455
Arrow "" 1300 550 1005 255

Box "Legend: red = untrusted internet, amber = public edge, green = private/data zone, blue = privileged admin. Dashed zone boxes are trust boundaries; labels TB-1 through TB-4 mark attack-surface crossings." 160 890 1280 50 "#6b7280"

$bmp.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

function PdfEscape($Text) {
  $escaped = $Text -replace "\\", "\\"
  $escaped = $escaped -replace "\(", "\("
  $escaped = $escaped -replace "\)", "\)"
  return $escaped
}

$pdfOps = New-Object System.Collections.Generic.List[string]
function PdfLine($S) { $script:pdfOps.Add($S) }
function PdfColor($Hex, [bool]$Stroke) {
  $c = [System.Drawing.ColorTranslator]::FromHtml($Hex)
  $r = [Math]::Round($c.R / 255, 3)
  $g2 = [Math]::Round($c.G / 255, 3)
  $b = [Math]::Round($c.B / 255, 3)
  if ($Stroke) { PdfLine "$r $g2 $b RG" } else { PdfLine "$r $g2 $b rg" }
}
function PdfRect($X, $Y, $W, $H, $Fill, $Stroke, [bool]$Dashed = $false) {
  $py = $height - $Y - $H
  PdfColor $Fill $false
  PdfColor $Stroke $true
  if ($Dashed) { PdfLine "[8 8] 0 d" } else { PdfLine "[] 0 d" }
  PdfLine "$X $py $W $H re B"
}
function PdfText($Text, $X, $Y, $Size = 12, [bool]$Bold = $false) {
  $font = if ($Bold) { "/F2" } else { "/F1" }
  $lines = $Text -split "`n"
  $lineY = $height - $Y
  foreach ($line in $lines) {
    $safe = PdfEscape $line
    PdfLine "BT $font $Size Tf $X $lineY Td ($safe) Tj ET"
    $lineY -= ($Size + 4)
  }
}
function PdfArrow($Label, $X1, $Y1, $X2, $Y2) {
  $py1 = $height - $Y1
  $py2 = $height - $Y2
  PdfColor "#374151" $true
  PdfLine "[] 0 d 2 w $X1 $py1 m $X2 $py2 l S"
  if ($Label.Trim().Length -gt 0) {
    PdfText $Label ([Math]::Min($X1, $X2) + [Math]::Abs($X2 - $X1) / 2 - 55) ([Math]::Min($Y1, $Y2) + [Math]::Abs($Y2 - $Y1) / 2 - 8) 10 $false
  }
}

PdfText "Cloud Misconfiguration Threat Analysis - Data Flow Diagram" 420 45 24 $true
PdfRect 40 80 280 760 "#fee2e2" "#b91c1c" $true
PdfRect 370 80 330 760 "#fef3c7" "#b45309" $true
PdfRect 750 80 470 760 "#dcfce7" "#15803d" $true
PdfRect 1260 80 290 760 "#dbeafe" "#1d4ed8" $true
PdfText "Internet Zone`nTrust: untrusted" 95 115 13 $true
PdfText "DMZ / Public Edge`nTrust: controlled public" 430 115 13 $true
PdfText "Internal VPC`nTrust: private application/data" 830 115 13 $true
PdfText "Admin Zone`nTrust: privileged identities" 1310 115 13 $true

$nodes = @(
  @{T="External Entity`nInternet Users"; X=85; Y=230; W=190; H=70; C="#b91c1c"},
  @{T="External Entity`nDevelopers"; X=1310; Y=190; W=180; H=70; C="#1d4ed8"},
  @{T="External Entity`nCI/CD Pipeline"; X=1310; Y=310; W=180; H=70; C="#1d4ed8"},
  @{T="Process`nAPI Gateway"; X=435; Y=210; W=190; H=90; C="#b45309"},
  @{T="Process`nEC2 Web App"; X=435; Y=410; W=190; H=90; C="#b45309"},
  @{T="Process`nLambda Functions"; X=815; Y=210; W=190; H=90; C="#15803d"},
  @{T="Data Store`nS3 Bucket`nmisconfig: public ACL"; X=800; Y=530; W=190; H=100; C="#15803d"},
  @{T="Data Store`nRDS Database`nmisconfig: public, unencrypted"; X=1020; Y=530; W=190; H=100; C="#15803d"},
  @{T="Data Store`nSecrets Manager`nintended control"; X=910; Y=700; W=190; H=100; C="#15803d"},
  @{T="Cloud Control Plane`nIAM Roles and Policies`nmisconfig: wildcard admin"; X=1300; Y=500; W=210; H=100; C="#1d4ed8"}
)
foreach ($n in $nodes) {
  PdfRect $n.X $n.Y $n.W $n.H "#ffffff" $n.C $false
  PdfText $n.T ($n.X + 14) ($n.Y + 25) 12 $true
}

PdfText "TB-1 Internet / DMZ" 285 190 12 $true
PdfText "TB-2 DMZ / Internal" 655 190 12 $true
PdfText "TB-3 Admin / Control" 1160 190 12 $true
PdfText "TB-4 Service / Data" 850 470 12 $true
PdfArrow "HTTPS requests / TB-1" 275 265 435 255
PdfArrow "HTTPS integration" 530 300 530 410
PdfArrow "Invoke / TB-2" 625 250 815 250
PdfArrow "" 625 455 1020 580
PdfArrow "" 625 455 800 580
PdfArrow "" 910 300 895 530
PdfArrow "" 930 300 1005 700
PdfArrow "IAM / TB-3" 1400 260 1405 500
PdfArrow "Deploy / IAM" 1400 380 1405 500
PdfArrow "" 1300 550 625 455
PdfArrow "" 1300 550 1005 255
PdfRect 160 890 1280 50 "#f9fafb" "#6b7280" $false
PdfText "Legend: dashed boxes are trust boundaries. TB-1 through TB-4 mark attack-surface crossings." 185 920 13 $false

$content = ($pdfOps -join "`n")
$objects = New-Object System.Collections.Generic.List[string]
$objects.Add("<< /Type /Catalog /Pages 2 0 R >>")
$objects.Add("<< /Type /Pages /Kids [3 0 R] /Count 1 >>")
$objects.Add("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $width $height] /Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> /Contents 6 0 R >>")
$objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")
$objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>")
$objects.Add("<< /Length $($content.Length) >>`nstream`n$content`nendstream")

$pdf = "%PDF-1.4`n"
$offsets = @(0)
for ($i = 0; $i -lt $objects.Count; $i++) {
  $offsets += $pdf.Length
  $pdf += "$($i + 1) 0 obj`n$($objects[$i])`nendobj`n"
}
$xref = $pdf.Length
$pdf += "xref`n0 $($objects.Count + 1)`n0000000000 65535 f `n"
for ($i = 1; $i -lt $offsets.Count; $i++) {
  $pdf += ("{0:0000000000} 00000 n `n" -f $offsets[$i])
}
$pdf += "trailer << /Size $($objects.Count + 1) /Root 1 0 R >>`nstartxref`n$xref`n%%EOF"
[System.IO.File]::WriteAllText((Resolve-Path $OutDir).Path + "\cloud-misconfiguration-dfd.pdf", $pdf, [System.Text.Encoding]::ASCII)

Write-Host "Wrote $pngPath"
Write-Host "Wrote $pdfPath"
