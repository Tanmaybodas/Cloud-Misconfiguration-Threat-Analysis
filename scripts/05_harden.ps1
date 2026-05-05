param(
  [string]$Region = "us-east-1",
  [string]$BucketName = "pbl-secure-before-bucket",
  [string]$AdminCidr = "203.0.113.10/32"
)

$ErrorActionPreference = "Stop"

function Require-Command($Name) {
  if ($null -eq (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "$Name is required. Run scripts/00_check_prereqs.ps1 for install guidance."
  }
}

Require-Command "awslocal"
New-Item -ItemType Directory -Force evidence/hardened | Out-Null

$env:AWS_DEFAULT_REGION = $Region
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

$inventory = Get-Content evidence/before/inventory.json | ConvertFrom-Json
$sgId = $inventory.security_group_id
$privateSubnetIds = @($inventory.private_subnet_ids)
if ($privateSubnetIds.Count -eq 0) {
  $privateSubnetIds = @($inventory.private_subnet_id)
}

Write-Host "Hardening S3 public access..."
awslocal s3api put-public-access-block --bucket $BucketName --public-access-block-configuration "BlockPublicAcls=true,BlockPublicPolicy=true,IgnorePublicAcls=true,RestrictPublicBuckets=true" | Out-Null
awslocal s3api put-bucket-acl --bucket $BucketName --acl private | Out-Null

Write-Host "Replacing internet-wide ingress rules..."
foreach ($port in @(22, 3306, 5432)) {
  try {
    awslocal ec2 revoke-security-group-ingress --group-id $sgId --protocol tcp --port $port --cidr "0.0.0.0/0" | Out-Null
  } catch {
    Write-Host "No 0.0.0.0/0 rule found for port $port; continuing."
  }
}
try {
  awslocal ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr $AdminCidr | Out-Null
} catch {
  Write-Host "Admin SSH CIDR may already exist; continuing."
}

Write-Host "Removing overprivileged IAM access..."
try {
  awslocal iam detach-role-policy --role-name pbl-misconfigured-admin-role --policy-arn arn:aws:iam::aws:policy/AdministratorAccess | Out-Null
} catch {
  Write-Host "AdministratorAccess was not attached or role is absent; continuing."
}
try {
  awslocal iam delete-user-policy --user-name pbl-wildcard-user --policy-name pbl-wildcard-admin | Out-Null
} catch {
  Write-Host "Wildcard user policy was not present; continuing."
}
$leastPrivilegePolicy = (Resolve-Path "policies/ec2-s3-readonly-policy.json").Path
try {
  awslocal iam put-role-policy --role-name pbl-misconfigured-admin-role --policy-name pbl-remediated-s3-readonly --policy-document "file://$leastPrivilegePolicy" | Out-Null
} catch {
  Write-Host "Could not attach least-privilege inline policy to pbl-misconfigured-admin-role; continuing."
}

Write-Host "Creating hardened replacement database because RDS encryption cannot be toggled in place..."
$safeSubnetGroup = "pbl-hardened-db-subnets"
try {
  awslocal rds create-db-subnet-group --db-subnet-group-name $safeSubnetGroup --db-subnet-group-description "Hardened private DB subnet group" --subnet-ids $privateSubnetIds | Out-Null
} catch {
  Write-Host "Hardened DB subnet group may already exist; continuing."
}
try {
  awslocal rds create-db-instance --db-instance-identifier pbl-hardened-db --db-instance-class db.t3.micro --engine postgres --master-username admin --master-user-password "Use-A-Strong-Local-Password-123!" --allocated-storage 20 --storage-encrypted --no-publicly-accessible --db-subnet-group-name $safeSubnetGroup | Out-Null
} catch {
  Write-Host "Hardened DB may already exist; continuing."
}

awslocal s3api get-public-access-block --bucket $BucketName > evidence/hardened/s3-public-access-block.json
awslocal s3api get-bucket-acl --bucket $BucketName > evidence/hardened/s3-acl.json
awslocal ec2 describe-security-groups --group-ids $sgId > evidence/hardened/security-group-remediated.json
awslocal iam list-attached-role-policies --role-name pbl-misconfigured-admin-role > evidence/hardened/admin-role-attached-policies.json
awslocal rds describe-db-instances > evidence/hardened/rds.json

Write-Host "Hardening complete. Evidence written to evidence/hardened/."
