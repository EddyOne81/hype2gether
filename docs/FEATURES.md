# Feature codes (MVP)

Each item: code — what — acceptance criteria (AC). Reference the code in commits and PRs.

| Code     | Feature                 | Acceptance criteria                                                                                                    |
| -------- | ----------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| AUTH-01  | Sign in / sign out      | New user can sign in with Apple; session survives app restart; sign-out clears local data                              |
| AUTH-02  | Delete account          | Deletes profile, memberships' personal data, check-ins, photos, step summaries; cannot be undone; confirmed twice      |
| STEP-01  | HealthKit permission    | Clear explanation before the system prompt; denied state shows how to enable in Settings                               |
| STEP-02  | Daily step sync         | Daily totals per party time zone; re-sync never double-counts; status shows "synced / not synced yet"                  |
| PARTY-01 | Create party            | Name + time zone; creator becomes member; party is private                                                             |
| PARTY-02 | Join by invite          | 6-character server-generated code or link; expired/invalid code shows an error; joining mid-round waits for next round |
| PARTY-03 | Leave party             | Confirmed; user stays in the current round's locked list                                                               |
| ROUND-01 | Start round             | Locks member list (3–8), stores rule_version and time zone                                                             |
| ROUND-02 | Finalize round          | Runs after step (+12 h) and vote (+24 h) deadlines; re-run safe; provisional when data missing or dispute open         |
| LEAD-01  | Daily leaderboard       | Shows points and real steps; updates in realtime; ties share place                                                     |
| CHECK-01 | Photo check-in          | Camera only; one counted per member per day; stored in private bucket                                                  |
| CHECK-02 | Verify vote             | One per voter, no self-vote, closes 24 h after posting; reactions never score                                          |
| RANK-01  | Rating and tier         | ΔR per PRODUCT_BRIEF; rating per party; tiers Bronze → Platinum                                                        |
| CARD-01  | Weekly cards            | Winner card + summary card for all; provisional label when not final                                                   |
| CARD-02  | Export and share        | 9:16 and 4:5 PNG; preview first; hide party name/photo option; never auto-posts                                        |
| SOLO-01  | Solo weekly card        | Personal card without rank or votes; invite friends from it                                                            |
| MOD-01   | Report content          | Report a check-in; reported item hidden for the reporter; queue for review                                             |
| NOTI-01  | Essential notifications | Sync reminder before deadline, vote requests, weekly result; user can turn each off                                    |
