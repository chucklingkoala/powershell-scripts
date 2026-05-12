# PowerShell Scripts

Just a collection of scripts I've written/adapted over the years.

I decided to ask Claude to go through my PowerShell folder and determine what is still useful and what isn't, and then sanitise everything of passwords and hosts.

This is the result.

---

## The Good Stuff

Everything worth keeping lives here, organised into folders by category.
All scripts have been sanitised — no real hostnames, IPs, passwords, or credentials anywhere.
Where a script needs server names or credentials, they're exposed as `param()` block defaults that you fill in for your environment.

### Categories

| Folder | What's in there |
|---|---|
| [`ActiveDirectory/`](Good/ActiveDirectory/) | AD health reports, user/group reports, home drive audit, CN↔DN converter, account unlock |
| [`Exchange/`](Good/Exchange/) | Backpressure monitor, mailbox size report, message tracking log GUI, wildcard cert rotation, DAG alerts, EWS helpers, hybrid mailbox provisioning |
| [`Microsoft365/`](Good/Microsoft365/) | SharePoint backup, upload, migration, warm-up; OneDrive KFM, silent config, ADAL; password expiration management |
| [`Backup-DR/`](Good/Backup-DR/) | Veeam failover/undo, DR invocation menu, DPM/MABS tape reports, DNS changeover, EqualLogic SAN clone/cleanup |
| [`Infrastructure/`](Good/Infrastructure/) | Hyper-V setup, iSCSI tools, WSUS cleanup, IIS app pool recycle, cert export, SCOM agent proxy, IPv6 disable, GPO firewall rules |
| [`Monitoring/`](Good/Monitoring/) | Server-down alerting (SQL-backed + SMS), DFSR error monitor, security log full alert, service monitor, web URL health check, app error log diff |
| [`FTP-SFTP/`](Good/FTP-SFTP/) | Custom PowerShell FTP module (9 functions) + WinSCP and WS_FTP Pro patterns: multi-directory upload, atomic upload, download-with-verify, banking ABA/AFI upload, PGP download |
| [`Database/`](Good/Database/) | `Out-SQL` (pipe any object to a SQL table), SQL connection helpers |
| [`Security/`](Good/Security/) | Disable SMBv1 across domain, ransomware encrypted-file recovery, Firefox NTLM auth fix |
| [`Utilities/`](Good/Utilities/) | File sorting, batch rename, TV episode sort, folder size reports, remote PS session menu, WS_FTP cleanup, log rotation, script template |

---

## Using the Scripts

Most scripts use a `param()` block at the top. The defaults are generic placeholders — swap them out before running:

```powershell
param(
    [string]$SMTPServer  = 'smtp.domain.local',   # ← your mail relay
    [string]$ToAddress   = 'admin@domain.local',  # ← your address
    ...
)
```

For scripts that need credentials, they default to `Get-Credential` which will prompt you at runtime. You can hard-wire values in the param defaults for scheduled tasks, or supply them from a secrets store.

Scripts that call WinSCP reference a **pre-configured WinSCP session name** (set up once in the WinSCP UI) rather than embedding connection details.

