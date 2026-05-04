param(
  [switch]$Detached
)

$ErrorActionPreference = "Stop"

if ($null -eq (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw "Docker is required. Install Docker Desktop, start it, then rerun this script."
}

$name = "pbl-localstack"
$existing = docker ps -a --filter "name=$name" --format "{{.Names}}"
if ($existing -contains $name) {
  $running = docker ps --filter "name=$name" --format "{{.Names}}"
  if ($running -contains $name) {
    Write-Host "LocalStack container '$name' is already running on http://localhost:4566"
    exit 0
  }
  docker start $name | Out-Null
  Write-Host "Started existing LocalStack container '$name'."
  exit 0
}

$mode = @()
if ($Detached) {
  $mode += "-d"
}
else {
  $mode += "-it"
}

docker run --rm @mode `
  --name $name `
  -p 4566:4566 `
  -e "SERVICES=s3,ec2,iam,rds,lambda,apigateway,secretsmanager,sts" `
  -e DEBUG=0 `
  localstack/localstack:3.4.0
