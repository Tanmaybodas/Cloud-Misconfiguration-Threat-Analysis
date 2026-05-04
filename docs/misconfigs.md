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

## S3 public bucket exposes credentials and database backup

- Command: `awslocal s3api put-bucket-acl --bucket pbl-secure-before-bucket --acl public-read`
- Resource ARN: `arn:aws:s3:::pbl-secure-before-bucket`
- CIS control violated: CIS 2.1.5 - Ensure S3 buckets do not allow public access
- Why dangerous: Public ACLs can expose backups, credentials, and application data to unauthenticated users.

## Security group allows SSH, MySQL, and Postgres from anywhere

- Command: `awslocal ec2 authorize-security-group-ingress --group-id sg-926149297bd9931f2 --protocol tcp --port 22/3306/5432 --cidr 0.0.0.0/0`
- Resource ARN: `arn:aws:ec2:-group/sg-926149297bd9931f2`
- CIS control violated: CIS 5.2 - Ensure no security groups allow ingress from 0.0.0.0/0 to remote server administration ports
- Why dangerous: Internet-wide database and admin access increases brute-force, exploitation, and lateral movement risk.

## IAM wildcard and AdministratorAccess policies allow account takeover

- Command: `awslocal iam put-user-policy --user-name pbl-wildcard-user --policy-name pbl-wildcard-admin --policy-document file://policies/iam-wildcard-admin-policy.json`
- Resource ARN: `arn:aws:iam::000000000000:user/pbl-wildcard-user`
- CIS control violated: CIS 1.16 - Ensure IAM policies that allow full administrative privileges are not attached
- Why dangerous: A single exposed credential becomes full cloud account control.

## RDS-equivalent database is public, unencrypted, and uses weak credentials

- Command: `awslocal rds create-db-instance --db-instance-identifier pbl-misconfigured-db --no-storage-encrypted --publicly-accessible --master-user-password Password123`
- Resource ARN: `arn:aws:rds:-misconfigured-db`
- CIS control violated: CIS 2.3.1 - Ensure RDS instances are encrypted; CIS 2.3.3 - Ensure RDS instances are not public
- Why dangerous: Public access, no encryption, and weak credentials create a high-impact data breach path.

## S3 public bucket exposes credentials and database backup

- Command: `awslocal s3api put-bucket-acl --bucket pbl-secure-before-bucket --acl public-read`
- Resource ARN: `arn:aws:s3:::pbl-secure-before-bucket`
- CIS control violated: CIS 2.1.5 - Ensure S3 buckets do not allow public access
- Why dangerous: Public ACLs can expose backups, credentials, and application data to unauthenticated users.

## Security group allows SSH, MySQL, and Postgres from anywhere

- Command: `awslocal ec2 authorize-security-group-ingress --group-id sg-545fba922f2baf01b --protocol tcp --port 22/3306/5432 --cidr 0.0.0.0/0`
- Resource ARN: `arn:aws:ec2:-group/sg-545fba922f2baf01b`
- CIS control violated: CIS 5.2 - Ensure no security groups allow ingress from 0.0.0.0/0 to remote server administration ports
- Why dangerous: Internet-wide database and admin access increases brute-force, exploitation, and lateral movement risk.

## IAM wildcard and AdministratorAccess policies allow account takeover

- Command: `awslocal iam put-user-policy --user-name pbl-wildcard-user --policy-name pbl-wildcard-admin --policy-document file://policies/iam-wildcard-admin-policy.json`
- Resource ARN: `arn:aws:iam::000000000000:user/pbl-wildcard-user`
- CIS control violated: CIS 1.16 - Ensure IAM policies that allow full administrative privileges are not attached
- Why dangerous: A single exposed credential becomes full cloud account control.

## RDS-equivalent database is public, unencrypted, and uses weak credentials

- Command: `awslocal rds create-db-instance --db-instance-identifier pbl-misconfigured-db --no-storage-encrypted --publicly-accessible --master-user-password Password123`
- Resource ARN: `arn:aws:rds:-misconfigured-db`
- CIS control violated: CIS 2.3.1 - Ensure RDS instances are encrypted; CIS 2.3.3 - Ensure RDS instances are not public
- Why dangerous: Public access, no encryption, and weak credentials create a high-impact data breach path.
