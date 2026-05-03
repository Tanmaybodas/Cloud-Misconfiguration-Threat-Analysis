# Before-State Architecture

## Goal

The before-state lab represents a small cloud application before deliberate misconfiguration. It is designed to be safer than the later attack-surface state and to provide baseline evidence for comparison.

## Components

| Zone | Component | Purpose | Initial control |
| --- | --- | --- | --- |
| Internet zone | Internet users | Send HTTPS traffic to the public application entry point | Only HTTPS is intended |
| Admin zone | Developers | Administer infrastructure through IAM and CI/CD | Least privilege is expected |
| Admin zone | CI/CD pipeline | Deploy application changes and infrastructure updates | Scoped IAM permissions are expected |
| DMZ | API Gateway | Public API front door | Rate limiting and auth should be enabled in a real account |
| DMZ | EC2 web app | Handles web traffic | Security group allows TCP/443 only from VPC CIDR in the local baseline |
| Internal VPC | Lambda functions | Async processing and integration logic | Service role should be least privilege |
| Internal VPC | RDS database | Stores application records | Private subnet, encrypted at rest, not publicly accessible |
| Internal VPC | S3 bucket | Stores files and backups | Public access block enabled, bucket ACL private |
| Internal VPC | Secrets Manager | Stores secrets in the intended secure design | Secrets should not be written to S3 or instance files |
| Admin zone | IAM roles and users | Authorize service and human activity | No wildcard admin policies in the baseline |

## Baseline Resource Model

The `scripts/02_create_before_state.ps1` script creates:

| Resource | Name | Baseline property |
| --- | --- | --- |
| VPC | `pbl-before-vpc` | `10.20.0.0/16` |
| Public subnet | generated ID | `10.20.1.0/24` |
| Private subnet A | generated ID | `10.20.2.0/24` |
| Private subnet B | generated ID | `10.20.3.0/24` |
| Security group | `pbl-before-web-sg` | Allows TCP/443 from `10.20.0.0/16` only |
| S3 bucket | `pbl-secure-before-bucket` | Public access block enabled |
| IAM role | `pbl-before-ec2-role` | Inline S3 read-only policy scoped to the lab bucket |
| EC2-like instance | generated ID | Uses the least-privilege instance profile |
| RDS-equivalent | `pbl-before-db` | Encrypted and not publicly accessible |

## Trust Boundaries

| Boundary | From | To | Main risk at crossing |
| --- | --- | --- | --- |
| TB-1 | Internet zone | DMZ | Spoofing, denial of service, injection, credential stuffing |
| TB-2 | DMZ | Internal VPC | Lateral movement from exposed app tier to database/storage |
| TB-3 | Admin zone | Cloud control plane | Overprivileged CI/CD or developer identities changing resources |
| TB-4 | Services | Data stores | Unauthorized reads/writes, data tampering, secret leakage |

## Evidence to Capture

After running `scripts/02_create_before_state.ps1`, collect:

- `evidence/before/inventory.json`
- `evidence/before/security-groups.json`
- `evidence/before/s3-public-access-block.json`
- `evidence/before/iam-role.json`
- `evidence/before/rds.json`
