param(
  [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force prowler-results,scoutsuite-results,evidence/scanners | Out-Null

$env:AWS_DEFAULT_REGION = $Region
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

if ($null -ne (Get-Command awslocal -ErrorAction SilentlyContinue)) {
  awslocal s3 ls > evidence/scanners/awslocal-s3-ls.txt
}

if ($null -ne (Get-Command prowler -ErrorAction SilentlyContinue)) {
  Write-Host "Running targeted Prowler checks against LocalStack..."
  prowler aws --endpoint-url http://localhost:4566 --output-formats json html --output-directory ./prowler-results --checks s3_bucket_public_access_block_enabled iam_policy_no_full_access_or_administrative_privileges ec2_securitygroup_allow_ingress_from_internet_to_tcp_port_22 rds_instance_storage_encrypted rds_instance_public_access | Tee-Object evidence/scanners/prowler-targeted.log

  Write-Host "Running broader Prowler AWS checks against LocalStack..."
  prowler aws --endpoint-url http://localhost:4566 --output-formats json html --output-directory ./prowler-results | Tee-Object evidence/scanners/prowler-full.log
} else {
  Write-Host "[OPTIONAL] Prowler scanner not installed (optional analysis tool). Install with: pip install prowler"
}

if ($null -ne (Get-Command scout -ErrorAction SilentlyContinue)) {
  Write-Host "Running ScoutSuite. LocalStack coverage may be limited; use output as supplemental evidence."
  scout aws --report-dir ./scoutsuite-results --no-browser --force | Tee-Object evidence/scanners/scoutsuite.log
} else {
  Write-Host "[OPTIONAL] ScoutSuite scanner not installed (optional analysis tool). Install with: pip install scoutsuite"
}

Write-Host "Scanner phase complete. Triage notes belong in docs/scanner-findings-analysis.md."
