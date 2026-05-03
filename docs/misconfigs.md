# Deliberate Misconfiguration Log

This log records each intentionally introduced weakness, the command used, the affected resource, the CIS control it violates, and why the change is dangerous.

Run `scripts/03_introduce_misconfigs.ps1` to append command-specific evidence generated from your LocalStack resource IDs.

## Planned Misconfigurations

| Area | Misconfiguration | Primary CIS mapping | Risk |
| --- | --- | --- | --- |
| S3 | Disable public access block, set public ACL, upload `credentials.txt` and `db-backup.sql` | CIS 2.1.5 | Information disclosure of secrets and backups |
| Security groups | Allow `0.0.0.0/0` inbound to ports 22, 3306, and 5432 | CIS 5.2 | Brute-force, remote exploitation, and database exposure |
| IAM | Attach `AdministratorAccess` to an EC2 role and create wildcard user policy | CIS 1.16 | Full account takeover after one credential compromise |
| RDS | Publicly accessible, unencrypted DB with `Password123` | CIS 2.3.1, CIS 2.3.3 | Data breach, tampering, and credential guessing |
