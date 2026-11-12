# Security policy

## Reporting a vulnerability

Please report security issues privately through GitHub: open the repository's **Security** tab and choose **Report a vulnerability**. Do not open a public issue, pull request or discussion for a security problem.

Include what you found, where (file, endpoint or screen), how to reproduce it, and the impact you expect. We will acknowledge the report, keep you updated while we investigate, and credit you when the fix ships if you wish.

## Scope

- This repository: the mobile app, the scoring engine, database migrations, row-level security policies and Edge Functions.
- Leaked credentials: if you find a key or token anywhere in this repository or its history, report it the same way.

## Supported versions

Only the latest version on `main` is supported.

## Internal policy

How the team handles secrets and personal data is described in [`docs/SECURITY.md`](../docs/SECURITY.md).
