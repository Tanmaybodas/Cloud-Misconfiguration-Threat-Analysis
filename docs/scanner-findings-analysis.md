# Scanner Findings Analysis

## Scanner Plan

| Scanner | Purpose | Command | Output |
| --- | --- | --- | --- |
| Prowler targeted | Validate specific introduced misconfigurations | `prowler aws --endpoint-url http://localhost:4566 --checks s3_bucket_public_access_block_enabled iam_policy_no_full_access_or_administrative_privileges ec2_securitygroup_allow_ingress_from_internet_to_tcp_port_22 rds_instance_storage_encrypted rds_instance_public_access` | `prowler-results/` and `evidence/scanners/prowler-targeted.log` |
| Prowler broad | CIS-style coverage across supported services | `prowler aws --endpoint-url http://localhost:4566 --output-formats json html --output-directory ./prowler-results` | `prowler-results/` |
| ScoutSuite | Visual cloud posture report | `scout aws --report-dir ./scoutsuite-results --no-browser --force` | `scoutsuite-results/` |

LocalStack coverage is useful for lab evidence, but scanner support can differ from real AWS because LocalStack emulates APIs. Treat scanner output as supporting evidence and cross-check it against the CLI evidence captured in `evidence/misconfigured/`.

## Triage

| Finding | Severity | Maps to intentional misconfig? | Evidence | Notes |
| --- | --- | --- | --- | --- |
| S3 public access block disabled / bucket public ACL | Critical | Yes | `evidence/misconfigured/s3-acl.json`, Prowler S3 checks | Public objects include `credentials.txt` and `db-backup.sql` |
| Security group allows `0.0.0.0/0` on TCP/22 | Critical | Yes | `evidence/misconfigured/security-group-open-ports.json` | SSH exposure can lead to host compromise |
| Security group allows `0.0.0.0/0` on TCP/3306 | High | Yes | `evidence/misconfigured/security-group-open-ports.json` | MySQL exposure enables brute-force and exploitation |
| Security group allows `0.0.0.0/0` on TCP/5432 | High | Yes | `evidence/misconfigured/security-group-open-ports.json` | Postgres exposure enables brute-force and exploitation |
| IAM policy allows full administrative privileges | Critical | Yes | `evidence/misconfigured/wildcard-user-policy.json`, `evidence/misconfigured/admin-role-policies.json` | Wildcard user and EC2 admin role create full takeover path |
| RDS instance storage not encrypted | High | Yes | `evidence/misconfigured/rds.json` | Unencrypted database storage violates secure baseline |
| RDS instance publicly accessible | High | Yes | `evidence/misconfigured/rds.json` | Public DB endpoint increases direct attack surface |
| Missing S3 access logging | Medium | No, supporting weakness | Prowler if supported | Improves forensic visibility |
| Missing CloudTrail / log monitoring | Medium | No, supporting weakness | Prowler if supported | LocalStack may not fully emulate organization logging |
| Missing API Gateway throttling or WAF | Medium | No, architectural risk | STRIDE table | Include as design remediation even if scanner cannot verify |

## Evidence Annotation Process

1. Run `scripts/03_introduce_misconfigs.ps1`.
2. Run `scripts/04_run_scanners.ps1`.
3. Copy the relevant scanner result IDs into the table above.
4. Confirm each scanner finding with CLI evidence in `evidence/misconfigured/`.
5. After `scripts/05_harden.ps1`, capture fixed-state evidence in `evidence/hardened/`.

## Risk Summary

The critical path is chained: public S3 exposes credentials, wildcard IAM converts those credentials into account takeover, and open security groups plus weak RDS credentials enable direct data access. The scanner findings should be presented as validation of this attack chain, not as isolated checklist failures.
