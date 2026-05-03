# STRIDE Threat Table

Ratings use `Critical`, `High`, `Medium`, and `Low` based on blast radius, exploitability, and expected business impact in the intentionally misconfigured state.

| Service | Threat Category | Threat Description | Attack Vector | Impact | Existing Control | STRIDE Rating |
| --- | --- | --- | --- | --- | --- | --- |
| API Gateway | Spoofing | Unauthenticated requests impersonate legitimate users or services | Missing auth, stolen bearer token, weak API key handling | Unauthorized API use and data access | HTTPS endpoint assumed | High |
| API Gateway | Tampering | Request payloads modify downstream state | Injection, parameter tampering, unsafe deserialization | Data corruption or malicious workflow execution | Application validation expected | High |
| API Gateway | Repudiation | Users deny sensitive calls | Missing request IDs, incomplete access logs | Weak incident reconstruction | None documented in LocalStack baseline | Medium |
| API Gateway | Information Disclosure | Verbose errors leak resource names or secrets | Error responses expose stack traces, ARNs, or tokens | Reconnaissance and credential exposure | HTTPS only | Medium |
| API Gateway | Denial of Service | No throttling or WAF allows high-volume abuse | Request floods, expensive endpoint loops | Service disruption and cost impact in real AWS | None documented | Medium |
| API Gateway | Elevation of Privilege | Gateway invokes backend with excessive permissions | Misconfigured integration role | Backend actions beyond user authorization | IAM intended but not validated | High |
| EC2 Web App | Spoofing | Attacker reaches instance metadata or spoofs internal service calls | SSRF to IMDS, missing IMDSv2 enforcement | Credential theft and lateral movement | Security group baseline only | High |
| EC2 Web App | Tampering | Attacker modifies application files or runtime configuration | RCE through exposed service or vulnerable app | Web defacement, malware staging, data manipulation | No host hardening evidenced | High |
| EC2 Web App | Repudiation | Admin or attacker actions are not attributable | Missing CloudTrail/application logs | Slow forensic response | None documented | Medium |
| EC2 Web App | Information Disclosure | Instance profile credentials leak | SSRF, local file read, debug endpoint | Cloud API access under instance role | Least-privilege role before misconfig | High |
| EC2 Web App | Denial of Service | Open public attack surface increases service exhaustion | SSH brute force, app request floods | App outage | Security group later becomes overexposed | Medium |
| EC2 Web App | Elevation of Privilege | Admin role attached to app instance enables full cloud control | Compromise instance, use role credentials | Full account takeover | None after AdministratorAccess attachment | Critical |
| Lambda Functions | Spoofing | Unauthorized service invokes Lambda | Weak resource policy or API integration | Execution under trusted context | IAM expected | Medium |
| Lambda Functions | Tampering | Deployment package or environment variables altered | Overprivileged CI/CD role changes function code | Backdoor execution | CI/CD trust boundary documented | High |
| Lambda Functions | Repudiation | Function invocations lack traceability | Missing CloudWatch logs or request correlation | Poor incident reconstruction | None documented | Medium |
| Lambda Functions | Information Disclosure | Secrets exposed through environment variables or logs | Log scraping, role compromise | Credential disclosure | Secrets Manager intended | High |
| Lambda Functions | Denial of Service | Unbounded invocation consumes concurrency | Event flood or recursive invocation | Service degradation | No concurrency limit documented | Medium |
| Lambda Functions | Elevation of Privilege | Function role has wildcard permissions | Compromised function calls IAM/S3/RDS APIs | Cross-service compromise | Least privilege expected but must be validated | High |
| S3 Bucket | Spoofing | Anonymous or unintended principal accesses bucket | Public ACL or permissive bucket policy | Untrusted identity reads objects | Public access block disabled in misconfig | High |
| S3 Bucket | Tampering | Public write allows malicious object upload or overwrite | `public-read-write`, leaked credentials, wildcard IAM | Data poisoning, malware hosting, backup corruption | Versioning baseline helps but is insufficient | High |
| S3 Bucket | Repudiation | Object access cannot be attributed | Missing server access logs or CloudTrail data events | Weak audit trail | No access logging documented | Medium |
| S3 Bucket | Information Disclosure | Public ACL exposes `credentials.txt` and `db-backup.sql` | Anonymous `GetObject` | Secret leakage and privacy breach | None after public ACL | Critical |
| S3 Bucket | Denial of Service | Attacker floods bucket with reads/writes | Public access or leaked IAM key | Availability and cost impact in real AWS | None after public exposure | Medium |
| S3 Bucket | Elevation of Privilege | Exposed credentials enable higher cloud privileges | Read `credentials.txt`, use leaked keys | Account compromise path | Secrets should be in Secrets Manager | Critical |
| RDS Database | Spoofing | Internet user attempts direct database login | Public endpoint plus weak password | Unauthorized DB session | None after public access | High |
| RDS Database | Tampering | Attacker changes application data | Credential guessing, SQL injection, exposed port | Data integrity loss | No encryption or network isolation after misconfig | High |
| RDS Database | Repudiation | Query and admin actions are not traceable | No database audit logging | Weak forensic timeline | None documented | Medium |
| RDS Database | Information Disclosure | Data at rest and in transit may be exposed | Unencrypted storage, public network path | Sensitive record disclosure | Encryption disabled in misconfig | High |
| RDS Database | Denial of Service | Public DB receives brute-force or query floods | Internet exposure on 5432/3306 | App outage | Security group open to world | High |
| RDS Database | Elevation of Privilege | Weak master password gives attacker DB admin | Password spraying `Password123` | Full DB takeover | Password policy not enforced in lab | Critical |
| IAM Roles and Users | Spoofing | Stolen access key impersonates developer, CI/CD, or instance role | Exposed keys in S3 or host compromise | Unauthorized cloud API calls | Fake lab creds only; real-world impact critical | Critical |
| IAM Roles and Users | Tampering | Wildcard identity changes policies, roles, and resources | `Action:*`, `Resource:*` | Cloud environment manipulation | None after wildcard policy | Critical |
| IAM Roles and Users | Repudiation | Overprivileged shared users hide accountability | Shared account or missing CloudTrail | Weak attribution | Individual IAM users expected | Medium |
| IAM Roles and Users | Information Disclosure | Wildcard IAM reads secrets, buckets, and database metadata | `s3:GetObject`, `secretsmanager:GetSecretValue`, `rds:Describe*` | Broad sensitive data exposure | Least privilege removed | Critical |
| IAM Roles and Users | Denial of Service | Admin identity deletes or disables resources | `ec2:TerminateInstances`, `s3:DeleteBucket`, `rds:DeleteDBInstance` | Full service outage | No permission boundary | High |
| IAM Roles and Users | Elevation of Privilege | User grants itself or others admin permissions | `iam:PutUserPolicy`, `iam:PassRole`, `sts:AssumeRole` | Account takeover | No SCP or permission boundary in lab | Critical |
| Security Groups | Spoofing | Attackers present as arbitrary internet clients | `0.0.0.0/0` inbound rules | No source trust | CIDR unrestricted after misconfig | Medium |
| Security Groups | Tampering | Open admin/database ports enable exploitation that changes systems | SSH, MySQL, Postgres exposed | Host or DB integrity loss | None after open ingress | High |
| Security Groups | Repudiation | Network attempts are not logged | No VPC Flow Logs documented | Poor source tracking | None documented | Medium |
| Security Groups | Information Disclosure | Exposed database ports leak banners or data | Direct DB probing | Reconnaissance and data leakage | None after open ingress | High |
| Security Groups | Denial of Service | Public ports receive brute-force and traffic floods | Internet-wide scans and credential stuffing | Service degradation | None after open ingress | High |
| Security Groups | Elevation of Privilege | SSH exposure leads to host compromise and role abuse | Brute force, vulnerable SSH service, stolen key | Instance and cloud role takeover | SSH should be replaced with Session Manager | Critical |
| Secrets Manager / Secret Handling | Spoofing | App retrieves attacker-controlled secret or wrong secret | Weak IAM resource scoping | Credential substitution | Secrets Manager intended but not enforced | Medium |
| Secrets Manager / Secret Handling | Tampering | Secret value changed by overprivileged identity | Wildcard IAM updates secret | App connects to attacker-controlled service | No permission boundary | High |
| Secrets Manager / Secret Handling | Repudiation | Secret reads/updates are not audited | Missing CloudTrail events | Weak investigation | None documented | Medium |
| Secrets Manager / Secret Handling | Information Disclosure | Secrets stored in S3 object instead of managed secret store | Public `credentials.txt` | Credential compromise | No secret rotation in lab | Critical |
| Secrets Manager / Secret Handling | Denial of Service | Secret deleted or disabled by wildcard identity | Admin policy misuse | Application outage | No recovery control documented | Medium |
| Secrets Manager / Secret Handling | Elevation of Privilege | Exposed secret unlocks IAM, DB, or CI/CD access | Public S3 read or log leak | Privilege escalation across services | Secrets Manager should isolate and rotate secrets | Critical |
| CI/CD Pipeline | Spoofing | Attacker impersonates build agent | Leaked token or weak federated identity | Unauthorized deployments | IAM expected | High |
| CI/CD Pipeline | Tampering | Pipeline deploys malicious infrastructure or code | Compromised repo secret or admin policy | Backdoors and policy weakening | Code review expected | High |
| CI/CD Pipeline | Repudiation | Build changes are not attributable | Shared deploy key, missing audit logs | Weak rollback decision making | Version control expected | Medium |
| CI/CD Pipeline | Information Disclosure | Build logs expose secrets | Echoed environment variables, failed deploy logs | Credential compromise | Secrets should be masked | High |
| CI/CD Pipeline | Denial of Service | Pipeline disables or deletes infrastructure | Wildcard deploy role | Environment outage | Least privilege expected | High |
| CI/CD Pipeline | Elevation of Privilege | Pipeline role can pass or attach admin roles | `iam:PassRole`, `AdministratorAccess` | Full account takeover | No permission boundary documented | Critical |
