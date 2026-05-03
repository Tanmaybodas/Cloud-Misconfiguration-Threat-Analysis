# Cloud Misconfiguration Threat Analysis Final Report

## Executive Summary

This project built a LocalStack-based AWS lab to model common cloud misconfigurations without using paid cloud resources. The before-state architecture used a private S3 bucket, scoped IAM role, restricted security group, and private encrypted database. The misconfigured state intentionally introduced public S3 exposure, internet-open administrative and database ports, wildcard IAM permissions, and a public unencrypted database with weak credentials.

The resulting risk posture moves from controlled lab architecture to a critical exposure chain: public storage can leak secrets, leaked credentials can abuse wildcard IAM, overprivileged instance roles can take over the account, and open database ports can expose or corrupt sensitive data. The hardening phase reverses these weaknesses with public access blocks, least privilege IAM, restricted ingress, encrypted private database replacement, and evidence capture.

## Architecture DFD

Source diagram: `infrastructure/cloud-misconfiguration-dfd.drawio`

Export the draw.io source to PNG and PDF for submission:

- `infrastructure/cloud-misconfiguration-dfd.png`
- `infrastructure/cloud-misconfiguration-dfd.pdf`

The DFD separates four trust zones:

| Trust Zone | Components | Boundary Risk |
| --- | --- | --- |
| Internet zone | Internet users | Untrusted traffic enters the cloud edge |
| DMZ | API Gateway, EC2 web app | Public application tier can be exploited |
| Internal VPC | Lambda, S3, RDS, Secrets Manager | Sensitive application data and secrets live here |
| Admin zone | Developers, CI/CD, IAM control plane | Privileged identities can alter the whole environment |

Primary trust-boundary crossings are internet-to-DMZ HTTPS, DMZ-to-internal database connections, DMZ-to-S3 object access, CI/CD-to-IAM control plane calls, and service-to-secret retrieval.

## STRIDE Threat Table

The full STRIDE matrix is in `docs/stride-threat-table.md`. The highest-risk entries are:

| Service | STRIDE Category | Threat | Rating |
| --- | --- | --- | --- |
| S3 Bucket | Information Disclosure | Public ACL exposes credentials and database backup | Critical |
| IAM Roles and Users | Elevation of Privilege | Wildcard policy enables full account takeover | Critical |
| EC2 Web App | Elevation of Privilege | AdministratorAccess instance role turns host compromise into account compromise | Critical |
| Security Groups | Elevation of Privilege | SSH open to the internet enables host takeover and role abuse | Critical |
| RDS Database | Elevation of Privilege | Weak master password enables DB admin access | Critical |
| Secrets Handling | Information Disclosure | Secrets stored in public S3 instead of Secrets Manager | Critical |

## Scanner Findings Analysis

Scanner guidance and triage are in `docs/scanner-findings-analysis.md`.

Expected critical and high findings:

| Finding | Severity | Intentional |
| --- | --- | --- |
| Public S3 bucket / disabled public access block | Critical | Yes |
| IAM wildcard or full administrative policy | Critical | Yes |
| SSH open from `0.0.0.0/0` | Critical | Yes |
| MySQL/Postgres open from `0.0.0.0/0` | High | Yes |
| RDS unencrypted | High | Yes |
| RDS publicly accessible | High | Yes |

Use `evidence/misconfigured/` to confirm scanner output when LocalStack scanner coverage is incomplete.

## CIS/OWASP Mapping Table

The complete mapping is in `docs/cis-owasp-mapping.md`.

| Finding | Prowler Check ID | CIS Control | OWASP Cloud Top 10 |
| --- | --- | --- | --- |
| Public S3 bucket | `s3_bucket_public_access_block_enabled` | CIS 2.1.5 | C6: Insecure Storage |
| Open SSH security group | `ec2_securitygroup_allow_ingress_from_internet_to_tcp_port_22` | CIS 5.2 | C5: Insecure Network Configuration |
| Wildcard IAM policy | `iam_policy_no_full_access_or_administrative_privileges` | CIS 1.16 | C2: IAM Misconfiguration |
| Unencrypted RDS | `rds_instance_storage_encrypted` | CIS 2.3.1 | C6: Insecure Storage |
| Public RDS | `rds_instance_public_access` | CIS 2.3.3 | C5: Insecure Network Configuration |
| Exposed credentials | S3/secrets checks depending on scanner support | CIS 2.1.5 | C7: Secrets Management |

## Hardening Checklist

The prioritized checklist is in `docs/hardening-checklist.md`, and the scripted remediation is `scripts/05_harden.ps1`.

Key fixes:

| Priority | Fix | Evidence |
| --- | --- | --- |
| P0 | Enable S3 public access block and set bucket ACL private | `evidence/hardened/s3-public-access-block.json` |
| P0 | Remove AdministratorAccess and wildcard IAM policy | `evidence/hardened/admin-role-attached-policies.json` |
| P1 | Remove `0.0.0.0/0` ingress on SSH, MySQL, and Postgres | `evidence/hardened/security-group-remediated.json` |
| P1 | Replace unencrypted public RDS with encrypted private RDS | `evidence/hardened/rds.json` |
| P2 | Add logging, VPC Flow Logs, API throttling, and WAF in real AWS | Real-account evidence or design screenshots |

## Conclusion

Before deliberate misconfiguration, the lab had a defensible posture: private storage, scoped IAM, restricted ingress, and encrypted private database storage. After misconfiguration, the environment became critical risk because several weaknesses chained together into account takeover and data breach scenarios. Public S3 disclosed secrets, wildcard IAM removed privilege boundaries, open security groups exposed administration and database ports, and the weak public database created a direct data-compromise route.

After hardening, the posture returns to controlled risk: public access is blocked, IAM is least-privilege, risky ingress is removed, and the database is replaced with an encrypted private instance. Remaining improvements for a real AWS account are centralized logging, VPC Flow Logs, secret rotation, WAF/rate limiting, and continuous compliance scanning.
