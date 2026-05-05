param(
  [string]$Region = "us-east-1",
  [string]$BucketName = "pbl-secure-before-bucket",
  [string]$VpcCidr = "10.20.0.0/16"
)

$ErrorActionPreference = "Stop"

function Require-Command($Name) {
  if ($null -eq (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "$Name is required. Run scripts/00_check_prereqs.ps1 for install guidance."
  }
}

function Save-Json($Name, $Value) {
  $path = Join-Path "evidence/before" $Name
  $Value | ConvertTo-Json -Depth 20 | Set-Content -Encoding utf8 $path
}

Require-Command "awslocal"
New-Item -ItemType Directory -Force evidence/before | Out-Null

$env:AWS_DEFAULT_REGION = $Region
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

Write-Host "Creating before-state VPC..."
$vpc = awslocal ec2 create-vpc --cidr-block $VpcCidr | ConvertFrom-Json
$vpcId = $vpc.Vpc.VpcId
awslocal ec2 create-tags --resources $vpcId --tags Key=Name,Value=pbl-before-vpc | Out-Null

$publicSubnet = awslocal ec2 create-subnet --vpc-id $vpcId --cidr-block "10.20.1.0/24" --availability-zone "${Region}a" | ConvertFrom-Json
$privateSubnetA = awslocal ec2 create-subnet --vpc-id $vpcId --cidr-block "10.20.2.0/24" --availability-zone "${Region}b" | ConvertFrom-Json
$privateSubnetB = awslocal ec2 create-subnet --vpc-id $vpcId --cidr-block "10.20.3.0/24" --availability-zone "${Region}c" | ConvertFrom-Json
$publicSubnetId = $publicSubnet.Subnet.SubnetId
$privateSubnetAId = $privateSubnetA.Subnet.SubnetId
$privateSubnetBId = $privateSubnetB.Subnet.SubnetId

$igw = awslocal ec2 create-internet-gateway | ConvertFrom-Json
$igwId = $igw.InternetGateway.InternetGatewayId
awslocal ec2 attach-internet-gateway --vpc-id $vpcId --internet-gateway-id $igwId | Out-Null

$routeTable = awslocal ec2 create-route-table --vpc-id $vpcId | ConvertFrom-Json
$routeTableId = $routeTable.RouteTable.RouteTableId
awslocal ec2 create-route --route-table-id $routeTableId --destination-cidr-block "0.0.0.0/0" --gateway-id $igwId | Out-Null
awslocal ec2 associate-route-table --route-table-id $routeTableId --subnet-id $publicSubnetId | Out-Null

Write-Host "Creating restrictive security group..."
$sg = awslocal ec2 create-security-group --group-name pbl-before-web-sg --description "Before-state web SG" --vpc-id $vpcId | ConvertFrom-Json
$sgId = $sg.GroupId
awslocal ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 443 --cidr "10.20.0.0/16" | Out-Null

Write-Host "Creating private S3 bucket with public access block..."
awslocal s3api create-bucket --bucket $BucketName | Out-Null
awslocal s3api put-public-access-block --bucket $BucketName --public-access-block-configuration "BlockPublicAcls=true,BlockPublicPolicy=true,IgnorePublicAcls=true,RestrictPublicBuckets=true" | Out-Null
awslocal s3api put-bucket-versioning --bucket $BucketName --versioning-configuration Status=Enabled | Out-Null

Write-Host "Creating least-privilege EC2 role..."
$assumeRolePolicy = (Resolve-Path "policies/ec2-assume-role-policy.json").Path
$leastPrivilegePolicy = (Resolve-Path "policies/ec2-s3-readonly-policy.json").Path
awslocal iam create-role --role-name pbl-before-ec2-role --assume-role-policy-document "file://$assumeRolePolicy" | Out-Null
awslocal iam put-role-policy --role-name pbl-before-ec2-role --policy-name pbl-before-s3-readonly --policy-document "file://$leastPrivilegePolicy" | Out-Null
awslocal iam create-instance-profile --instance-profile-name pbl-before-profile | Out-Null
awslocal iam add-role-to-instance-profile --instance-profile-name pbl-before-profile --role-name pbl-before-ec2-role | Out-Null

Write-Host "Creating EC2-like instance..."
$instance = awslocal ec2 run-instances --image-id ami-12345678 --count 1 --instance-type t3.micro --subnet-id $publicSubnetId --security-group-ids $sgId --iam-instance-profile Name=pbl-before-profile | ConvertFrom-Json
$instanceId = $instance.Instances[0].InstanceId

Write-Host "Creating RDS-equivalent database in private subnet..."
$dbSubnetGroupName = "pbl-before-db-subnets"
awslocal rds create-db-subnet-group --db-subnet-group-name $dbSubnetGroupName --db-subnet-group-description "Before-state private DB subnets" --subnet-ids $privateSubnetAId $privateSubnetBId | Out-Null
awslocal rds create-db-instance --db-instance-identifier pbl-before-db --db-instance-class db.t3.micro --engine postgres --master-username admin --master-user-password "Use-A-Strong-Local-Password-123!" --allocated-storage 20 --storage-encrypted --no-publicly-accessible --db-subnet-group-name $dbSubnetGroupName | Out-Null

$inventory = [ordered]@{
  region = $Region
  endpoint = "http://localhost:4566"
  vpc_id = $vpcId
  public_subnet_id = $publicSubnetId
  private_subnet_ids = @($privateSubnetAId, $privateSubnetBId)
  internet_gateway_id = $igwId
  route_table_id = $routeTableId
  security_group_id = $sgId
  bucket = $BucketName
  iam_role = "arn:aws:iam::000000000000:role/pbl-before-ec2-role"
  instance_id = $instanceId
  rds_instance = "pbl-before-db"
}

Save-Json "inventory.json" $inventory
awslocal ec2 describe-vpcs > evidence/before/vpcs.json
awslocal ec2 describe-security-groups > evidence/before/security-groups.json
awslocal s3api get-public-access-block --bucket $BucketName > evidence/before/s3-public-access-block.json
awslocal iam get-role --role-name pbl-before-ec2-role > evidence/before/iam-role.json
awslocal rds describe-db-instances > evidence/before/rds.json

Write-Host "Before-state complete. Inventory written to evidence/before/inventory.json"
