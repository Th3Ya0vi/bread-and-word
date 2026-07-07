# Bread & Word

**Daily bread for the soul.**

Scripture and a fresh devotional every morning, a prayer wall where the
community bears one another up, and live rooms to pray and read the Bible
together. True community in Christ.

Bread & Word is built for people just finding their way to God, for those who
already walk with Him, and for those seeking real community, whether or not a
church building is part of their story yet. Come as you are; learn, pray, and
be carried.

Built for the [Scripture in New Frontiers](https://www.kaggle.com/competitions/scripture-in-new-frontiers)
challenge: Scripture as conversation, not broadcast.

## What's inside

| Pillar | Experience |
|---|---|
| **Today** | Verse of the day and a devotional written fresh each morning |
| **Pray** | The prayer wall: share requests, pray for others, answered prayers become testimony |
| **Circles** | Small private groups for reading Scripture, prayer, and testimony together |
| **Rooms** | Live audio rooms to pray or read the Bible together |
| **Bible** | A full Scripture reader in multiple translations |

The look is a calm, paper-like print aesthetic (see
[`docs/design-system.md`](docs/design-system.md)): one warm palette, five
typefaces, hard edges. No rounded corners, no shadows, no gradients.

## How the APIs are used

| Service | Used for | Code |
|---|---|---|
| **YouVersion Platform API** | Verse of the day, passages in multiple versions (BSB default), the full 66-book reader with on-device caching | `lib/services/youversion/` |
| **Gloo AI Studio API** | Faith-tuned generation: the daily devotional (`DevotionalWriter`) and drafted, Scripture-grounded encouragement for prayers and testimonies (`EncouragementWriter`), always edited and sent by a human, never auto-posted | `lib/services/gloo/` |

Gloo auth is the OAuth client-credentials flow (`scope=api/access`) against
`platform.ai.gloo.com`; completions run on `gloo-anthropic-claude-sonnet-4.6`.
YouVersion is REST (`api.youversion.com/v1`) with the `X-YVP-App-Key` header.

## Running it

This is a Flutter app (iOS-first). API keys are never committed; supply your
own free keys:

1. Get a YouVersion Platform key at [developers.youversion.com](https://developers.youversion.com)
   and Gloo AI Studio credentials at [studio.ai.gloo.com](https://studio.ai.gloo.com).
2. Copy `dart_defines.example.json` to `dart_defines.local.json` and fill them in.
3. ```bash
   flutter pub get
   flutter run --dart-define-from-file=dart_defines.local.json
   ```

Without keys the app still runs. Today falls back to a built-in verse and
reflection.

Note: this repo contains the full client implementation for judging. The
production backend configuration (security rules, cloud functions, indexes)
is intentionally not published.

## License

Source-available for hackathon review. Copyright Kpoga Software LLC, all
rights reserved. See [LICENSE](LICENSE).
