# Evidence Folder

The scripts write command output here:

| Folder | Purpose |
| --- | --- |
| `before/` | Baseline architecture evidence before misconfiguration |
| `misconfigured/` | Evidence after intentionally risky changes |
| `scanners/` | Prowler, ScoutSuite, and supporting scanner logs |
| `hardened/` | Evidence after remediation |

Do not commit real cloud credentials or real customer data. The provided fixture files are fake local lab data.
