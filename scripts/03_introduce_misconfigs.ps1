param(
  [string]$Region = "us-east-1",
  [string]$BucketName = "pbl-secure-before-bucket"
)

$ErrorActionPreference = "Stop"

function Require-Command($Name) {
  if ($null -eq (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "$Name is required. Run scripts/00_check_prereqs.ps1 for install guidance."
  }
}

function Append-MisconfigLog($Title, $Command, $ResourceArn, $CisControl, $Risk) {
  $block = @"

## $Title

- Command: ``$Command``
- Resource ARN: ``$ResourceArn``
- CIS control violated: $CisControl
- Why dangerous: $Risk
"@
  Add-Content -Encoding utf8 docs/misconfigs.md $block
}

Require-Command "awslocal"
New-Item -ItemType Directory -Force evidence/misconfigured | Out-Null

$env:AWS_DEFAULT_REGION = $Region
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

$inventory = Get-Content evidence/before/inventory.json | ConvertFrom-Json
$sgId = $inventory.security_group_id
$vpcId = $inventory.vpc_id
$privateSubnetIds = @($inventory.private_subnet_ids)
if ($privateSubnetIds.Count -eq 0) {
  $privateSubnetIds = @($inventory.private_subnet_id)
}

Write-Host "Making S3 bucket public and uploading sensitive-looking fixtures..."
awslocal s3api delete-public-access-block --bucket $BucketName | Out-Null
awslocal s3api put-bucket-acl --bucket $BucketName --acl public-read | Out-Null
awslocal s3 cp data/credentials.txt "s3://$BucketName/credentials.txt" | Out-Null
awslocal s3 cp data/db-backup.sql "s3://$BucketName/db-backup.sql" | Out-Null
Append-MisconfigLog "S3 public bucket exposes credentials and database backup" "awslocal s3api put-bucket-acl --bucket $BucketName --acl public-read" "arn:aws:s3:::$BucketName" "CIS 2.1.5 - Ensure S3 buckets do not allow public access" "Public ACLs can expose backups, credentials, and application data to unauthenticated users."

Write-Host "Opening high-risk ports to the internet..."
foreach ($port in @(22, 3306, 5432)) {
  try {
    awslocal ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port $port --cidr "0.0.0.0/0" | Out-Null
  } catch {
    Write-Host "Ingress rule for port $port may already exist; continuing."
  }
}
Append-MisconfigLog "Security group allows SSH, MySQL, and Postgres from anywhere" "awslocal ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22/3306/5432 --cidr 0.0.0.0/0" "arn:aws:ec2:$Region:000000000000:security-group/$sgId" "CIS 5.2 - Ensure no security groups allow ingress from 0.0.0.0/0 to remote server administration ports" "Internet-wide database and admin access increases brute-force, exploitation, and lateral movement risk."

Write-Host "Creating overprivileged IAM role and wildcard user policy..."
$assumeRolePolicy = (Resolve-Path "policies/ec2-assume-role-policy.json").Path
$wildcardPolicy = (Resolve-Path "policies/iam-wildcard-admin-policy.json").Path
awslocal iam create-role --role-name pbl-misconfigured-admin-role --assume-role-policy-document "file://$assumeRolePolicy" | Out-Null
awslocal iam attach-role-policy --role-name pbl-misconfigured-admin-role --policy-arn arn:aws:iam::aws:policy/AdministratorAccess | Out-Null
awslocal iam create-user --user-name pbl-wildcard-user | Out-Null
awslocal iam put-user-policy --user-name pbl-wildcard-user --policy-name pbl-wildcard-admin --policy-document "file://$wildcardPolicy" | Out-Null
Append-MisconfigLog "IAM wildcard and AdministratorAccess policies allow account takeover" "awslocal iam put-user-policy --user-name pbl-wildcard-user --policy-name pbl-wildcard-admin --policy-document file://policies/iam-wildcard-admin-policy.json" "arn:aws:iam::000000000000:user/pbl-wildcard-user" "CIS 1.16 - Ensure IAM policies that allow full administrative privileges are not attached" "A single exposed credential becomes full cloud account control."

Write-Host "Creating intentionally weak, public, unencrypted RDS-equivalent..."
$unsafeSubnetGroup = "pbl-misconfigured-db-subnets"
try {
  awslocal rds create-db-subnet-group --db-subnet-group-name $unsafeSubnetGroup --db-subnet-group-description "Misconfigured DB subnet group" --subnet-ids $privateSubnetIds | Out-Null
} catch {
  Write-Host "DB subnet group may already exist; continuing."
}
awslocal rds create-db-instance --db-instance-identifier pbl-misconfigured-db --db-instance-class db.t3.micro --engine postgres --master-username admin --master-user-password Password123 --allocated-storage 20 --no-storage-encrypted --publicly-accessible --db-subnet-group-name $unsafeSubnetGroup | Out-Null
Append-MisconfigLog "RDS-equivalent database is public, unencrypted, and uses weak credentials" "awslocal rds create-db-instance --db-instance-identifier pbl-misconfigured-db --no-storage-encrypted --publicly-accessible --master-user-password Password123" "arn:aws:rds:$Region:000000000000:db:pbl-misconfigured-db" "CIS 2.3.1 - Ensure RDS instances are encrypted; CIS 2.3.3 - Ensure RDS instances are not public" "Public access, no encryption, and weak credentials create a high-impact data breach path."

awslocal s3api get-bucket-acl --bucket $BucketName > evidence/misconfigured/s3-acl.json
awslocal s3api list-objects-v2 --bucket $BucketName > evidence/misconfigured/s3-objects.json
awslocal ec2 describe-security-groups --group-ids $sgId > evidence/misconfigured/security-group-open-ports.json
awslocal iam list-attached-role-policies --role-name pbl-misconfigured-admin-role > evidence/misconfigured/admin-role-policies.json
awslocal iam get-user-policy --user-name pbl-wildcard-user --policy-name pbl-wildcard-admin > evidence/misconfigured/wildcard-user-policy.json
awslocal rds describe-db-instances > evidence/misconfigured/rds.json

Write-Host "Misconfigured state complete. Evidence written to evidence/misconfigured/."
