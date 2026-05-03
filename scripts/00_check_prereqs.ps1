param()

$ErrorActionPreference = "Stop"

$required = @("docker", "python", "pip", "awslocal")
$optional = @("aws", "prowler", "scout")
$missingRequired = @()

Write-Host "Checking required tools..."
foreach ($tool in $required) {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  if ($null -eq $cmd) {
    $missingRequired += $tool
    Write-Host "MISSING  $tool"
  } else {
    Write-Host "OK       $tool -> $($cmd.Source)"
  }
}

Write-Host ""
Write-Host "Checking scanner/reporting tools..."
foreach ($tool in $optional) {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  if ($null -eq $cmd) {
    Write-Host "OPTIONAL $tool not found"
  } else {
    Write-Host "OK       $tool -> $($cmd.Source)"
  }
}

if ($missingRequired.Count -gt 0) {
  Write-Host ""
  Write-Host "Install missing Python tools with:"
  Write-Host "  pip install -r requirements.txt"
  Write-Host ""
  Write-Host "Install and start Docker Desktop if docker is missing."
  exit 1
}

Write-Host ""
Write-Host "Prerequisite check complete."
