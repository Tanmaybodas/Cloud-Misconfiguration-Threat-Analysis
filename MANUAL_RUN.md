# Manual Terminal Execution Guide

For advanced users who want to run individual project steps manually instead of using `python run_project.py`.

## Prerequisites

Make sure you have completed the installation steps from [README.md](README.md):

```powershell
# Activate virtual environment
.venv\Scripts\Activate.ps1

# Verify prerequisites
powershell -ExecutionPolicy Bypass -File .\scripts\00_check_prereqs.ps1
```

---

## Step-by-Step Manual Execution

### Step 1: Start LocalStack

Starts the LocalStack container for AWS local emulation:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\01_start_localstack.ps1 -Detached
```

**What it does:**

- Launches `pbl-localstack` container
- Exposes AWS API at `http://localhost:4566`
- Wait for container to be ready before running next steps

**Status check:**

```powershell
docker ps | findstr pbl-localstack
```

---

### Step 2: Create Secure Baseline

Creates the initial secure architecture in LocalStack:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\02_create_before_state.ps1
```

**What it creates:**

- VPC with public and private subnets
- Security group with restrictive rules
- S3 bucket with public access block enabled
- EC2 IAM role with least-privilege policy
- RDS database in private subnet
- Inventory saved to `evidence/before/inventory.json`

---

### Step 3: Introduce Misconfigurations

Intentionally introduces vulnerabilities to the baseline:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\03_introduce_misconfigs.ps1
```

**What it does:**

- Makes S3 bucket public (ACL: public-read)
- Opens security group to SSH (port 22) from `0.0.0.0/0`
- Opens security group to MySQL (port 3306) and Postgres (port 5432)
- Attaches wildcard `AdministratorAccess` IAM policy
- Inventory saved to `evidence/misconfigured/inventory.json`

**⚠️ WARNING:** Environment is intentionally insecure at this point.

---

### Step 4: Run Security Scanners

Executes Prowler and ScoutSuite security scanners (optional):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\04_run_scanners.ps1
```

**What it does:**

- Runs Prowler security scanner (if installed) → `prowler-results/`
- Runs ScoutSuite cloud reconnaissance (if installed) → `scoutsuite-results/`
- Both scanners are optional; script will note if not installed

**Note:** Install optional scanners:

```powershell
pip install prowler-cloud scoutsuite
```

---

### Step 5: Apply Hardening

Remediates all misconfigurations and applies security controls:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\05_harden.ps1
```

**What it does:**

- Reverts S3 bucket to private
- Removes overprivileged IAM policies
- Restricts security group ingress to internal only
- Removes public access from RDS
- Inventory saved to `evidence/hardened/inventory.json`

**Result:** Environment returns to secure baseline state.

---

### Step 6: Export Architecture Diagrams

Exports the Data Flow Diagram to portable formats:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\06_export_diagram_assets.ps1
```

**What it exports:**

- PNG image → `infrastructure/cloud-misconfiguration-dfd.png`
- PDF document → `infrastructure/cloud-misconfiguration-dfd.pdf`

**Note:** Requires draw.io CLI. If not installed, download from:

```
https://github.com/jgraph/drawio-desktop/releases
```

---

## Running in Sequence

To manually run all steps one after another:

```powershell
# 1. Start LocalStack
powershell -ExecutionPolicy Bypass -File .\scripts\01_start_localstack.ps1 -Detached

# 2. Wait a few seconds for LocalStack to be ready
Start-Sleep -Seconds 5

# 3. Create baseline
powershell -ExecutionPolicy Bypass -File .\scripts\02_create_before_state.ps1

# 4. Introduce misconfigs
powershell -ExecutionPolicy Bypass -File .\scripts\03_introduce_misconfigs.ps1

# 5. Run scanners (optional)
powershell -ExecutionPolicy Bypass -File .\scripts\04_run_scanners.ps1

# 6. Apply hardening
powershell -ExecutionPolicy Bypass -File .\scripts\05_harden.ps1

# 7. Export diagrams
powershell -ExecutionPolicy Bypass -File .\scripts\06_export_diagram_assets.ps1
```

---

## Troubleshooting

### Docker not running

```powershell
# Start Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker.exe"
```

### LocalStack not responding

```powershell
# Check container status
docker ps | findstr pbl-localstack

# View logs
docker logs pbl-localstack

# Restart container
docker stop pbl-localstack
docker rm pbl-localstack
# Then run Step 1 again
```

### Python/pip not found

```powershell
# Activate virtual environment
.venv\Scripts\Activate.ps1
```

### Permission denied errors

```powershell
# Set execution policy for current session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

---

## Cleanup

To remove all project artifacts and start fresh:

```powershell
# Stop LocalStack container
docker stop pbl-localstack
docker rm pbl-localstack

# Delete evidence folders
Remove-Item -Recurse -Force evidence/

# Delete scanner results
Remove-Item -Recurse -Force prowler-results/
Remove-Item -Recurse -Force scoutsuite-results/
```

---

**Prefer automated execution?** Use `python run_project.py` for a fully orchestrated experience with visual progress tracking.
