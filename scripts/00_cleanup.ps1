param(
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "SilentlyContinue"

function Require-Command($Name) {
    if ($null -eq (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name is required. Run scripts/00_check_prereqs.ps1 for install guidance."
    }
}

Require-Command "awslocal"

$env:AWS_DEFAULT_REGION = $Region
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

Write-Host "Cleaning up all project resources from LocalStack..."

# Terminate EC2 instances
Write-Host "  Terminating EC2 instances..."
awslocal ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text | ForEach-Object { 
    if ($_ -and $_ -ne "None") { 
        awslocal ec2 terminate-instances --instance-ids $_ | Out-Null
    }
}

# Remove IAM resources
Write-Host "  Removing IAM roles and users..."
@("pbl-before-ec2-role", "pbl-misconfigured-admin-role") | ForEach-Object {
    $roleName = $_
    awslocal iam list-role-policies --role-name $roleName --query "PolicyNames[]" --output text | ForEach-Object {
        if ($_ -and $_ -ne "None") {
            awslocal iam delete-role-policy --role-name $roleName --policy-name $_ | Out-Null
        }
    }
    awslocal iam detach-role-policy --role-name $roleName --policy-arn arn:aws:iam::aws:policy/AdministratorAccess | Out-Null
    awslocal iam delete-role --role-name $roleName | Out-Null
}

awslocal iam delete-user-policy --user-name pbl-wildcard-user --policy-name pbl-wildcard-admin | Out-Null
awslocal iam delete-user --user-name pbl-wildcard-user | Out-Null

# Remove instance profiles
Write-Host "  Removing instance profiles..."
awslocal iam remove-role-from-instance-profile --instance-profile-name pbl-before-profile --role-name pbl-before-ec2-role | Out-Null
awslocal iam delete-instance-profile --instance-profile-name pbl-before-profile | Out-Null

# Remove RDS instances and subnets
Write-Host "  Removing RDS instances and subnet groups..."
awslocal rds delete-db-instance --db-instance-identifier pbl-before-db --skip-final-snapshot | Out-Null
awslocal rds delete-db-instance --db-instance-identifier pbl-misconfigured-db --skip-final-snapshot | Out-Null
awslocal rds delete-db-instance --db-instance-identifier pbl-hardened-db --skip-final-snapshot | Out-Null
awslocal rds delete-db-subnet-group --db-subnet-group-name pbl-before-db-subnets | Out-Null
awslocal rds delete-db-subnet-group --db-subnet-group-name pbl-misconfigured-db-subnets | Out-Null
awslocal rds delete-db-subnet-group --db-subnet-group-name pbl-hardened-db-subnets | Out-Null

# Remove S3 buckets
Write-Host "  Removing S3 buckets..."
@("pbl-secure-before-bucket", "pbl-misconfigured-bucket", "pbl-hardened-bucket") | ForEach-Object {
    awslocal s3 rm "s3://$_" --recursive | Out-Null
    awslocal s3api delete-bucket --bucket $_ | Out-Null
}

# Remove VPCs and all dependent resources
Write-Host "  Removing VPCs..."
awslocal ec2 describe-vpcs --filters "Name=tag:Name,Values=pbl-before-vpc" --query "Vpcs[].VpcId" --output text | ForEach-Object {
    if ($_ -and $_ -ne "None") {
        $vpcId = $_
    
        # Remove all internet gateways
        awslocal ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpcId" --query "InternetGateways[].InternetGatewayId" --output text | ForEach-Object {
            if ($_ -and $_ -ne "None") {
                awslocal ec2 detach-internet-gateway --internet-gateway-id $_ --vpc-id $vpcId | Out-Null
                awslocal ec2 delete-internet-gateway --internet-gateway-id $_ | Out-Null
            }
        }
    
        # Remove all subnets
        awslocal ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcId" --query "Subnets[].SubnetId" --output text | ForEach-Object {
            if ($_ -and $_ -ne "None") {
                awslocal ec2 delete-subnet --subnet-id $_ | Out-Null
            }
        }
    
        # Remove all route tables
        awslocal ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpcId" --query "RouteTables[].RouteTableId" --output text | ForEach-Object {
            if ($_ -and $_ -ne "None") {
                awslocal ec2 describe-route-table-associations --filters "Name=route-table-id,Values=$_" --query "Associations[].RouteTableAssociationId" --output text | ForEach-Object {
                    if ($_ -and $_ -ne "None") {
                        awslocal ec2 disassociate-route-table --association-id $_ | Out-Null
                    }
                }
                awslocal ec2 delete-route-table --route-table-id $_ | Out-Null
            }
        }
    
        # Remove all security groups except default
        awslocal ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text | ForEach-Object {
            if ($_ -and $_ -ne "None") {
                awslocal ec2 delete-security-group --group-id $_ | Out-Null
            }
        }
    
        # Finally delete VPC
        awslocal ec2 delete-vpc --vpc-id $vpcId | Out-Null
    }
}

# Clear evidence directories
Write-Host "  Clearing evidence directories..."
Remove-Item -Recurse -Force evidence/before -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force evidence/misconfigured -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force evidence/hardened -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force prowler-results -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force scoutsuite-results -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Cleanup complete! Environment is reset."
Write-Host "You can now run: python run_project.py"
