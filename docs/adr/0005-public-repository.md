# 0005 — Public repository, all rights reserved

- Status: accepted
- Date: 2026-11-12

## Context

The team wants to share the project with people who have no GitHub account. The repository holds no secrets: real keys live in Supabase function secrets, EAS and GitHub Actions secrets, and gitleaks scans every commit and the full history in CI. Security does not depend on hiding the code: the server is authoritative (ADR 0003) and access is enforced by RLS. On the GitHub Free plan, secret scanning, push protection and branch rules are only available for public repositories.

## Decision

- Make the repository public.
- Keep the code proprietary: `LICENSE` grants no rights beyond viewing.
- Turn on secret scanning with push protection, a ruleset on `main` (pull request and passing CI required) and approval for workflows from outside contributors.

## Consequences

- Product docs and code are visible to anyone, including competitors; the licence protects the code, not the idea.
- Commit history, including author emails, is public.
- Any committed secret is exposed at once and must be rotated; gitleaks and push protection are the guard rails.
- Switching back to private later does not remove existing forks or caches.
