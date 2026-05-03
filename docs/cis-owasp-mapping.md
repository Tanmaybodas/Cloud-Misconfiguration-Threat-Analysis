# CIS Benchmark and OWASP Cloud Top 10 Mapping

Mappings are aligned to the project scope and the CIS AWS Foundations Benchmark v1.5 references named in the assignment. Confirm exact control numbering against the benchmark PDF before final submission if your instructor requires verbatim CIS text.

| Finding | Prowler Check ID | CIS Control | CIS Section | OWASP Cloud Top 10 | Rationale |
| --- | --- | --- | --- | --- | --- |
| Public S3 bucket / public access block disabled | `s3_bucket_public_access_block_enabled` | CIS 2.1.5 | S3 | C6: Insecure Storage | Public object access exposes secrets and backups |
| S3 contains `credentials.txt` | `s3_bucket_public_access_block_enabled`, secrets checks if enabled | CIS 2.1.5 | S3 / Secrets | C7: Secrets Management | Secrets stored as bucket objects are easily leaked |
| Open SSH from internet | `ec2_securitygroup_allow_ingress_from_internet_to_tcp_port_22` | CIS 5.2 | Networking | C5: Insecure Network Configuration | Remote administration should not be open to the world |
| Open MySQL from internet | `ec2_securitygroup_allow_ingress_from_internet_to_tcp_port_3306` | CIS 5.2 | Networking | C5: Insecure Network Configuration | Database ports should not accept public inbound traffic |
| Open Postgres from internet | `ec2_securitygroup_allow_ingress_from_internet_to_tcp_port_5432` | CIS 5.2 | Networking | C5: Insecure Network Configuration | Public database exposure increases brute-force and exploit risk |
| Wildcard IAM user policy | `iam_policy_no_full_access_or_administrative_privileges` | CIS 1.16 | IAM | C2: IAM Misconfiguration | `Action:*` and `Resource:*` grants full administrative control |
| AdministratorAccess on EC2 role | `iam_policy_no_full_access_or_administrative_privileges` | CIS 1.16 | IAM | C2: IAM Misconfiguration | Compromised instance becomes account administrator |
| RDS unencrypted storage | `rds_instance_storage_encrypted` | CIS 2.3.1 | Databases | C6: Insecure Storage | At-rest encryption protects database media and snapshots |
| RDS publicly accessible | `rds_instance_public_access` | CIS 2.3.3 | Databases / Networking | C5: Insecure Network Configuration | DB should remain private behind application tier |
| Weak RDS master password | Scanner-dependent | CIS IAM/password-policy related controls | Identity / Databases | C1: Broken Access Control, C7: Secrets Management | Weak credentials make direct compromise likely |
| Missing audit evidence | CloudTrail/logging checks if enabled | CIS logging controls | Logging | C3: Insufficient Logging and Monitoring | Detection and investigation are weakened without logs |
| Missing WAF/rate limiting | API Gateway/WAF checks if enabled | Monitoring/network defense controls | Edge / Networking | C5: Insecure Network Configuration | Public entry point needs abuse controls |

## Priority Mapping

| Priority | Findings | Reason |
| --- | --- | --- |
| P0 | Wildcard IAM, AdministratorAccess EC2 role, public S3 secrets | Enables full account takeover |
| P1 | Public database, open SSH, unencrypted RDS | Enables direct system or data compromise |
| P2 | Missing logging, missing rate limiting, missing access logs | Reduces detection and resilience |
| P3 | Documentation and tagging gaps | Slows operations and incident response |
