# Security and tenant-data handling

This repository is public. Treat every committed file as permanently public and searchable.

## Never commit

- tenant IDs, subscription IDs, verified production domains, or customer names
- real user names, user principal names, email addresses, object IDs, or device IDs
- access tokens, refresh tokens, passwords, application secrets, certificates, or API keys
- raw Microsoft Graph, Exchange Online, SharePoint, Teams, or Intune exports
- production screenshots or logs containing identifiers
- client-specific configurations, tickets, or internal documentation

## Default operating model

- Discovery scripts must be read-only unless a project is explicitly labeled otherwise.
- Aggregate and redact by default.
- Write generated reports only to ignored `output/` or `reports/` directories.
- Use synthetic data for committed samples.
- List required Microsoft Graph and service permissions before execution.
- Prefer the narrowest permission that can complete the task.
- Disconnect administrative sessions when the lab is finished.
- Review `git diff --staged` before every public commit.

## Before publishing evidence

1. Search for domain names, email addresses, GUIDs, IP addresses, and organization names.
2. Confirm that every screenshot and report is synthetic or sanitized.
3. Verify that no token, certificate, or local configuration file is staged.
4. Document the evidence boundary in the project README.

## Reporting a security concern

Do not open a public issue containing sensitive information. Send a short description to [hello@m365fixer.com](mailto:hello@m365fixer.com).

