# User Stories with Edge Cases

## 1. Quick Capture

*As a user, I want to quickly add anything to Inbox without deciding its category yet, so my mind stays clear.*

- Edge: empty text submitted → block save, no blank items
- Edge: app offline → capture saves locally, syncs when CloudKit reachable
- Edge: duplicate text captured twice quickly → both save, no dedup (user decides during triage)
- Edge: very long text (paragraph) → capture accepts it, AI triage may need truncation for prompt limits

## 2. AI Auto-Triage

*As a user, I want captured items auto-categorized into GTD buckets, so I don't manually sort everything.*

- Edge: device lacks Apple Intelligence → falls back to heuristic rules, user sees no visible difference in flow
- Edge: AI miscategorizes → user can override with one tap, correction doesn't retrain AI (no learning loop initially)
- Edge: ambiguous text ("mom") → AI defaults to Inbox uncategorized rather than guessing wrong bucket
- Edge: Foundation Models times out/fails → falls back to heuristic silently, no error shown to user

## 3. Next Actions

*As a user, I want a clear list of single concrete tasks I can act on right now.*

- Edge: task has no due date → shows in list unordered/by creation date, not hidden
- Edge: task marked complete → moves to completed log, removed from active list, undo available for 10s
- Edge: task linked to a Project that gets deleted → task orphaned, becomes standalone Next Action, not deleted

## 4. Waiting For

*As a user, I want to track what I'm blocked on and who owes me a response.*

- Edge: no "who" specified → still allowed, field optional, shown as "Waiting For: [unspecified]"
- Edge: waiting item becomes overdue → surfaces in Today briefing, doesn't auto-escalate to Next Action
- Edge: user marks Waiting For as resolved → prompts to convert to Next Action or complete outright

## 5. Someday/Maybe

*As a user, I want to park non-actionable ideas without losing them or cluttering active lists.*

- Edge: Someday item never reviewed → surfaces in Weekly Review as "stale" after 30+ days, not auto-deleted
- Edge: user promotes Someday to Next Action → date fields reset, treated as newly created

## 6. Projects

*As a user, I want to group related Next Actions under a multi-step outcome.*

- Edge: project has zero Next Actions → flagged in Weekly Review as "needs next action defined"
- Edge: project marked complete with open Next Actions inside → warns user, asks to complete/reassign children first
- Edge: project deleted → prompts: delete all linked tasks, or orphan them to standalone

## 7. Areas (filter/tag)

*As a user, I want to filter everything by life context (Work, Health, etc.).*

- Edge: item has no Area assigned → shows under "Uncategorized" filter, not hidden from "all" view
- Edge: Area deleted while items still tagged → items fall back to "Uncategorized," Area removed from filter list
- Edge: user creates duplicate Area name → blocked, case-insensitive uniqueness check

## 8. Weekly Review

*As a user, I want a guided flow to review all buckets and keep the system trustworthy.*

- Edge: user exits mid-review → progress saved, resumes from last step next time
- Edge: no stale items found → review still runs full checklist, just skips flagged-item step
- Edge: user skips a step → allowed, review marked "partial complete," streak still counts

## 9. Daily Briefing

*As a user, I want a morning summary of what matters today.*

- Edge: no Next Actions due today → briefing shows "nothing due, X items in Waiting For" instead of empty state
- Edge: calendar integration off/unavailable → briefing generates without calendar section, no error
- Edge: AI generation fails → falls back to plain list format (due today, overdue, waiting) without narrative framing

## 10. Siri / App Intents

*As a user, I want to add tasks or start review via Siri without opening the app.*

- Edge: Siri mishears input → intent still saves raw text to Inbox, user corrects later during triage (never silently discard)
- Edge: app not yet launched once (no CloudKit container initialized) → intent fails gracefully, prompts user to open app first
- Edge: multiple intents chained in a Shortcut → each runs independently, no shared state between calls

## 11. Voice Capture — English

*As a user, I want to speak a capture using native dictation.*

- Edge: dictation permission denied → falls back to text input, no crash
- Edge: background noise garbles transcription → user sees transcribed text before save, can edit

## 12. Voice Capture — Malayalam

*As a user, I want to speak in Malayalam and have it captured accurately.*

- Edge: Pi/Tailscale bridge unreachable → capture fails with clear "voice bridge offline" message, falls back to English dictation or text
- Edge: code-switched speech (Malayalam + English mixed) → IndicWhisper attempts full transcription, no guaranteed accuracy, user reviews before save
- Edge: Pi is asleep/powered off → same offline fallback as above, no silent failure

## 13. CloudKit Sync

*As a user, I want my data synced across iPhone/iPad/Mac automatically.*

- Edge: sync conflict (edited same item on two devices offline) → CloudKit's last-write-wins applies, no manual merge UI initially
- Edge: iCloud account not signed in → app functions fully local-only, sync disabled with a visible banner
- Edge: CloudKit quota/error → app continues working locally, retries sync silently in background

## 14. Gmail Integration

*As a user, I want actionable emails pulled into Inbox.*

- Edge: OAuth token expires → integration pauses, user notified to re-auth, no silent data loss
- Edge: email has no clear action → still imported to Inbox as raw item, user triages manually
- Edge: user revokes Gmail access externally → app detects on next sync attempt, integration marked disconnected

## 15. GitHub Projects Integration

*As a user, I want GitHub issues to appear as Next Actions or Waiting For.*

- Edge: issue closed on GitHub while open in Synapse → next sync marks it complete
- Edge: same issue linked in multiple Synapse items (edge case from re-import) → dedup by GitHub issue ID

## 16. EventKit / Calendar

*As a user, I want calendar events to inform today's briefing.*

- Edge: calendar permission denied → briefing runs without calendar section
- Edge: all-day event → shown separately from timed events in briefing, not treated as "due today" task

## 17. Apple Reminders Import

*As a user, I want to migrate my existing Reminders into Synapse once.*

- Edge: import run twice → duplicate detection by title+date, second run skips existing matches
- Edge: Reminders list has 1000+ items (matches your actual Database list) → import runs in background, progress indicator, doesn't block UI

## 18. Focus/Pomodoro Timer

*As a user, I want to start a focus session tied to a specific task.*

- Edge: session interrupted (app backgrounded/call) → timer continues via background task/notification, resumes state on return
- Edge: user starts session with no task selected → allowed, generic "Focus Session" logged, not blocked

## 19. Subscription (Pro)

*As a user, I want to upgrade for AI-assisted review, unlimited integrations, Malayalam voice.*

- Edge: subscription lapses → Pro features lock gracefully, data not deleted, free tier limits apply
- Edge: restore purchase on new device → StoreKit restore flow, no re-purchase required
- Edge: trial period ends mid-Weekly-Review → current session allowed to finish, next session locked if not converted
