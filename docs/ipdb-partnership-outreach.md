# IPDb partnership outreach (draft)

Use this as a starting point. Personalize before sending. IPDb is run by volunteers; a concise, respectful note works best.

## Outreach strategy (internal)

**Lead with product, not permission.** Polish Puzzle Buddy until it is demo-ready, then reach out with a **TestFlight link** so their team and power users can export from IPDb and try migration themselves. **IPDb CSV import is available in all builds** (Settings → Collection).

| Phase | When | What |
|-------|------|------|
| **1. Polish** | Now | Core loop rock-solid: collection UX, barcode + shopping mode, stats, accessibility, share collage. Fix rough edges App Store reviewers and IPDb users would hit on day one. |
| **2. TestFlight + migration** | Outreach trigger | Ship TestFlight build. Include migration steps in every outreach message — import/export round-trips with IPDb CSV format. |
| **3. Conversation** | After they try it | Partnership ideas (API, deep links, attribution) from a position of working software — they have felt the offline shopping + native iOS UX and tested CSV import with their own export. |

**Migration path (include in outreach):**

1. In IPDb: Listview → **Export** → **CSV** (their [documented flow](https://ipdb.tawk.help/article/what-can-i-do-in-the-listview)).
2. Install Puzzle Buddy (TestFlight or App Store).
3. **Settings** → **Collection** → **Import from IPDb CSV** → pick the file.
4. Re-add box photos locally (CSV does not include images). Use the **Needs photo** filter on the collection list to find puzzles still missing images.

---

## Context (internal — do not paste into email)

- IPDb already ships [iOS/iPad](https://apps.apple.com/us/app/the-internet-puzzle-database/id6737433560) and [Android](https://ipdb.tawk.help/article/accessing-downloading-installing-ipdb) apps (Henrik Rasmussen). Their help center states IPDb is **built on web technology** with the same experience on web, iOS, and Android — the ~3.3 MB iOS binary fits a thin cross-platform shell.
- App Store reviews praise the database and community; some cite cluttered UI and [no listed accessibility features](https://apps.apple.com/us/app/the-internet-puzzle-database/id6737433560). Puzzle Buddy differentiates on **native SwiftUI**, **offline shopping duplicate-check**, and **VoiceOver / Dynamic Type** — not on replacing IPDb’s catalog.
- Pitch **integration** (read-only API, deep links, attribution) after they have tried migration on TestFlight — not “you need a mobile app.”
- **Community tone:** IPDb is volunteer-run and publicly welcomes help. Henrik and admins are active in [r/Jigsawpuzzles](https://www.reddit.com/r/Jigsawpuzzles/comments/1gn6xxv/the_internet_puzzle_database_is_now_available_in/) (app-launch thread and follow-ups) — constructive, “join and improve” energy rather than gatekeeping. A warm public comment or DM after a genuine contribution (bug report, UX feedback, catalog entry) can be easier than a cold email.

**Suggested contacts**

- **Warm path:** Comment or DM on [r/Jigsawpuzzles — IPDb app launch thread](https://www.reddit.com/r/Jigsawpuzzles/comments/1gn6xxv/the_internet_puzzle_database_is_now_available_in/) (or a newer IPDb post). Introduce Puzzle Buddy, share TestFlight + migration steps, ask who to talk to about deeper integration.
- IPDb Help Center / in-app support
- Henrik Rasmussen (listed as developer on the [App Store listing](https://apps.apple.com/us/app/the-internet-puzzle-database/id6737433560))
- IPDb Contributors → Admins (burger menu on IPDb home screen, per their help docs)

---

## Subject line options

- Puzzle Buddy × IPDb — TestFlight for your collectors to try
- Native iOS collection app + easy IPDb CSV migration (TestFlight)
- Complement to IPDb — offline shopping + import (beta invite)

---

## Email draft

Hi Henrik and the IPDb team,

I'm Jacob Rozell, an iOS developer and puzzle collector building **[Puzzle Buddy](https://github.com/jacobrozell/PuzzleBuddy)** — a **local-first** iPhone app for cataloging jigsaw puzzles, tracking progress, and **checking duplicates while shopping** (fully offline via barcode scan).

I've been impressed by what IPDb has built: ~40k community-curated records, barcode-first cataloging, and the Digital Assistant for fast box entry. It fills a gap that generic UPC databases never will. I've been using your [iOS app](https://apps.apple.com/us/app/the-internet-puzzle-database/id6737433560) and following the community on r/Jigsawpuzzles — it's clear the project is built by puzzlers who welcome people pitching in.

### TestFlight invite

I'd love for you (and any power users you suggest) to try Puzzle Buddy on **TestFlight** — you can migrate a real collection in minutes:

1. Export a folder from IPDb (Listview → Export → CSV)
2. Install from TestFlight: **[TestFlight link]**
3. Settings → Collection → Import from IPDb CSV

No account required for the core app. Happy to walk through it on a quick call if useful.

### What Puzzle Buddy focuses on

- **Offline shopping mode** — scan a barcode at a thrift store; instant “already in my collection?”
- **Native iOS polish** — VoiceOver, Dynamic Type, reduce motion
- **Local-first** — collection data stays on device
- Progress tracking, stats, share collage — no ads, no paid API for core features

### Ideas I'd love to discuss after you've tried it

1. **Read-only barcode / title lookup** against IPDb for signed-in users, with clear attribution and your terms respected.
2. **Co-branded integration** — Puzzle Buddy surfaces IPDb as the canonical catalog; we handle offline shopping and local collection UX.
3. **Deep links** — scan in Puzzle Buddy → open the full IPDb record for reviews, images, and community context.
4. **Contribution path** — optional flow to send new discoveries back to IPDb (with your duplicate checks).

I'm happy to sign whatever data-use agreement you need and build to your specifications. Deeper integration (read-only API, deep links) can follow once you've tried migration and we align on attribution and terms.

Would you be open to a 20-minute call, or async feedback once you've tried the beta?

Thanks for building something the puzzle community genuinely needs.

Best,  
Jacob Rozell  
[your email]  
TestFlight: [link]  
GitHub: https://github.com/jacobrozell/PuzzleBuddy

---

## Shorter version (DM / forum)

Hi — I'm building Puzzle Buddy, a native local-first iOS puzzle catalog with offline barcode duplicate-check. TestFlight beta is ready with **IPDb CSV import** so you can export your collection from IPDb and try migration in a few taps: [TestFlight link]. Huge respect for IPDb — would love feedback and to explore read-only API / deep links with proper attribution. Open to your terms.

---

## Reddit comment (public, warm intro)

Use on [the IPDb app thread](https://www.reddit.com/r/Jigsawpuzzles/comments/1gn6xxv/the_internet_puzzle_database_is_now_available_in/) or a fresh IPDb post — **after** the app feels polished. Offer value first (feedback, catalog contributions), then share TestFlight.

> I've been using IPDb on phone and web — thanks for building this for the community. I'm an iOS dev working on **Puzzle Buddy**, a local-first collection app with offline barcode duplicate-check for thrift-store runs (no account required). TestFlight beta is up with **IPDb CSV import** — export your folder as CSV from IPDb, import in Settings, and you're migrated (photos you re-add locally). [TestFlight link] Would love feedback, and happy to talk about deeper integration (deep links, attribution) if there's interest. Who's the right person on the IPDb side?

---

## Talking points if they reply

| Their concern | Our answer |
|---------------|------------|
| You already have a mobile app | Yes — we target a different job: offline thrift-store duplicate check, local-only collection, native accessibility. Happy to deep-link into IPDb for the full record. |
| Competing with IPDb | We complement: offline-first shopping mode, local data ownership, SwiftUI accessibility; you keep canonical DB + community |
| Data licensing | Read-only API on your terms; clear IPDb attribution; user-initiated lookups only |
| Revenue | Puzzle Buddy 1.0 has no IAP; tip jar only; happy to discuss revenue share if co-branded |
| Maintenance | Jacob maintains Puzzle Buddy iOS; IPDb maintains data quality and API |
| Images | Don't hotlink without permission; deep link to IPDb detail view |
| Why reach out on TestFlight first | Lets your team validate migration and UX before a public App Store launch; import is already in the app for anyone who tries it |

## Before you send

- [ ] **Phase 1 done** — app feels robust for IPDb power users (not just dev-complete)
- [ ] TestFlight build uploaded (or App Store build if skipping beta)
- [ ] Paste **TestFlight link** in email, DM, and Reddit draft
- [ ] Attach 2–3 screenshots (shopping mode, import summary, collection list)
- [ ] Include the 3-step migration path (export CSV → TestFlight → import)
- [ ] Do **not** imply affiliation until agreed in writing
- [ ] **Reddit path:** Engage the community first (genuine feedback or catalog help), then share TestFlight
