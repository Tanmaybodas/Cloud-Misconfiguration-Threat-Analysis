# Cloud Misconfiguration Threat Analysis 

This repository implements a safe, LocalStack-first cloud misconfiguration lab for threat modeling, scanner triage, CIS/OWASP mapping, and remediation evidence.

The lab intentionally creates insecure cloud resources only against `http://localhost:4566`. Do not point these scripts at a real AWS account unless you have a throwaway account and have reviewed every command.

## Deliverables

- LocalStack setup and automation scripts in `scripts/`
- Intentional misconfiguration log in `docs/misconfigs.md`
- Architecture before-state notes in `docs/before-architecture.md`
- Data Flow Diagram source in `infrastructure/cloud-misconfiguration-dfd.drawio`
- STRIDE table in `docs/stride-threat-table.md`
- Scanner triage in `docs/scanner-findings-analysis.md`
- CIS/OWASP mapping in `docs/cis-owasp-mapping.md`
- Hardening checklist in `docs/hardening-checklist.md`
- Final report in `docs/final-report.md`
- Evidence capture folders under `evidence/`

## Prerequisites

Install these tools locally:

```powershell
pip install -r requirements.txt
```

Install and start Docker Desktop, then start LocalStack:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\01_start_localstack.ps1 -Detached
```

## Quick Run

Run the phases in order:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\00_check_prereqs.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\01_start_localstack.ps1 -Detached
powershell -ExecutionPolicy Bypass -File .\scripts\02_create_before_state.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\03_introduce_misconfigs.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\04_run_scanners.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\05_harden.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\06_export_diagram_assets.ps1
```

Evidence is written under `evidence/`. The report files are already populated with the expected analysis and can be updated with the exact outputs from your run.

## Diagram Export

The editable source is `infrastructure/cloud-misconfiguration-dfd.drawio`. You can either run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\06_export_diagram_assets.ps1
```

or open the draw.io file in [diagrams.net](https://app.diagrams.net/) and export:

- `infrastructure/cloud-misconfiguration-dfd.png`
- `infrastructure/cloud-misconfiguration-dfd.pdf`

Use the exported PNG/PDF in the final report.

## Safety Notes

- Fake AWS credentials are used: `test` / `test`.
- All AWS commands target LocalStack with `--endpoint-url http://localhost:4566` through `awslocal`.
- Risky examples such as public S3 ACLs, open security groups, wildcard IAM, and weak database passwords are deliberate local lab states.
- The hardening script reverses or replaces the high-risk settings.

