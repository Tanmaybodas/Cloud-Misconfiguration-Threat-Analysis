# Hardening Checklist

Use this as the remediation runbook and as the before/after evidence index for the final report.

| Priority | Area | Fix | Command or policy | CIS control satisfied | Before evidence | After evidence |
| --- | --- | --- | --- | --- | --- | --- |
| P0 | S3 | Enable public access block and private ACL | `awslocal s3api put-public-access-block --bucket pbl-secure-before-bucket --public-access-block-configuration "BlockPublicAcls=true,BlockPublicPolicy=true,IgnorePublicAcls=true,RestrictPublicBuckets=true"` | CIS 2.1.5 | `evidence/misconfigured/s3-acl.json` | `evidence/hardened/s3-public-access-block.json` |
| P0 | S3 | Move secrets out of S3 and rotate exposed credentials | Use Secrets Manager and delete `credentials.txt` from the bucket | CIS 2.1.5, secrets management best practice | `evidence/misconfigured/s3-objects.json` | Capture `awslocal s3api list-objects-v2` after deletion |
| P0 | IAM | Remove `AdministratorAccess` from EC2 role | `awslocal iam detach-role-policy --role-name pbl-misconfigured-admin-role --policy-arn arn:aws:iam::aws:policy/AdministratorAccess` | CIS 1.16 | `evidence/misconfigured/admin-role-policies.json` | `evidence/hardened/admin-role-attached-policies.json` |
| P0 | IAM | Delete wildcard user inline policy | `awslocal iam delete-user-policy --user-name pbl-wildcard-user --policy-name pbl-wildcard-admin` | CIS 1.16 | `evidence/misconfigured/wildcard-user-policy.json` | Rerun `awslocal iam list-user-policies --user-name pbl-wildcard-user` |
| P1 | IAM | Replace broad policy with least privilege | `policies/ec2-s3-readonly-policy.json` | CIS 1.16 | Wildcard policy evidence | Hardened role policy evidence |
| P1 | Security groups | Remove `0.0.0.0/0` for SSH, MySQL, and Postgres | `awslocal ec2 revoke-security-group-ingress --group-id <sg-id> --protocol tcp --port 22 --cidr 0.0.0.0/0` | CIS 5.2 | `evidence/misconfigured/security-group-open-ports.json` | `evidence/hardened/security-group-remediated.json` |
| P1 | Security groups | Replace SSH with Session Manager or restrict to admin CIDR | `.\scripts\05_harden.ps1 -AdminCidr 203.0.113.10/32` | CIS 5.2 | Open ingress evidence | Hardened SG evidence |
| P1 | RDS | Create encrypted replacement database | `awslocal rds create-db-instance --storage-encrypted --no-publicly-accessible ...` | CIS 2.3.1 | `evidence/misconfigured/rds.json` | `evidence/hardened/rds.json` |
| P1 | RDS | Disable public access by using private subnet and security group controls | Create replacement with `--no-publicly-accessible` | CIS 2.3.3 | Public DB evidence | Hardened DB evidence |
| P1 | RDS | Replace weak password and rotate any exposed DB credentials | Strong generated password stored in Secrets Manager | Password/security best practice | `Password123` command evidence in `docs/misconfigs.md` | Secrets Manager evidence |
| P2 | Logging | Enable CloudTrail management events and S3 data events in a real AWS account | `aws cloudtrail create-trail ...` and event selectors | CIS logging controls | Scanner logging finding | CloudTrail configuration evidence |
| P2 | Network visibility | Enable VPC Flow Logs in a real AWS account | `aws ec2 create-flow-logs ...` | CIS logging/network monitoring controls | Missing flow log finding | Flow log configuration evidence |
| P2 | API Gateway | Add throttling, auth, and WAF in a real AWS account | API Gateway stage settings and WAF association | Edge/network defense controls | STRIDE DoS finding | API configuration screenshot or CLI output |

## Scripted Remediation

Most P0/P1 fixes are implemented in:

```powershell
.\scripts\05_harden.ps1
```

RDS encryption cannot be changed in place. The safe remediation is snapshot, restore or recreate with encryption enabled, migrate traffic, and delete the unencrypted instance. The lab script creates `pbl-hardened-db` as the replacement target.
