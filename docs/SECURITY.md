# Security and secrets policy

## Where every secret lives

| Secret                                                                      | Lives in                                       | Never in                                        |
| --------------------------------------------------------------------------- | ---------------------------------------------- | ----------------------------------------------- |
| Supabase URL + anon/publishable key (public by design, protected by RLS)    | `.env` locally, EAS env vars (`EXPO_PUBLIC_*`) | hard-coded in source                            |
| Supabase service role / secret key                                          | Supabase Edge Function secrets only            | the app, `.env` of the app, the repo, chat logs |
| Database password                                                           | password manager                               | anywhere in the repo                            |
| Apple signing certs, provisioning profiles, App Store Connect API key (.p8) | managed by EAS credentials                     | the repo, shared drives                         |
| Sentry / PostHog tokens                                                     | EAS env vars, GitHub Actions secrets           | source code                                     |
| GitHub tokens                                                               | GitHub secrets                                 | source code                                     |

Rule of thumb: anything prefixed `EXPO_PUBLIC_` is shipped inside the app and readable by anyone. Only put values there that are safe to be public.

## Repository rules

- `.env*` files are git-ignored. Only `.env.example` (keys with empty or fake values) is committed.
- No real user data, photos, step data or screenshots with personal info in the repo. Seeds use fake data.
- gitleaks runs as a pre-commit hook and in CI. A failing scan blocks the merge.
- GitHub settings: private repo, secret scanning + push protection on, `main` protected (PR + passing CI required), Dependabot alerts on.
- Lockfile committed; new dependencies need a reason in the PR description. Prefer well-maintained packages.

## App data rules

- Health data: only per-day step totals with source and sync time. No raw samples, no location.
- Photos: private bucket, signed URLs with short expiry, removable by the owner.
- Account deletion removes profile, memberships' personal data, check-ins, photos and step summaries.
- Health data is sensitive personal data under Vietnamese law; legal review before public release.

## If a secret leaks

1. Rotate it immediately (Supabase dashboard / EAS / provider).
2. Remove it from history only after rotation (rewriting history does not un-leak it).
3. Note what happened in `docs/incidents/` without repeating the secret.
