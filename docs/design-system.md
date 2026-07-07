# Design System — Prayer Community App

A design system for a Bible / prayer community app — a place for praying together, sharing prayer requests, and gathering scripture. Ported from the Debriefd print-newspaper system, which gives the product a calm, paper-like, reverent feel rather than a noisy social-app feel.

---

## Core principle

One palette. **No dark mode, no theming, no gradients, no rounded corners, no drop shadows.** Everything looks like paper — printed scripture, a prayer journal, a parish bulletin. This restraint is the point: it makes the product feel quiet and considered, which suits prayer.

---

## Color palette

| Token | Hex | Use |
|---|---|---|
| Paper | `#F3EDE0` | primary background |
| Paper Deep | `#EBE3D2` | secondary surfaces, cards, quiet panels |
| Paper Bright | `#FAF5E9` | elevated surfaces |
| Ink | `#1A1612` | primary text, rules, headings |
| Ink Soft | `#3A342C` | body text on emphasized surfaces |
| Ink Faded | `#6B6359` | metadata, captions, dividers, timestamps |
| Ink Ghost | `#A8997F` | inactive states, hints, placeholders |
| Accent | `#B3321F` | red — section markers, drop caps, active nav, "praying now" markers |
| Accent Deep | `#8A1F10` | hover / pressed states |
| Green | `#2D5A3D` | answered-prayer / success states, used sparingly |

**Notes**
- The four-step ink ramp (Ink → Ink Soft → Ink Faded → Ink Ghost) carries the hierarchy. Use it instead of reaching for more colors.
- Accent red is used *surgically* — section eyebrows, drop caps on a verse of the day, the active tab, a "currently praying" pill. Never decorative.
- Green is reserved for genuine resolution (a prayer marked answered). Keep it rare so it carries weight.

---

## Typography — five typefaces, each with one job

| Typeface | Role | Sizes / weights |
|---|---|---|
| **DM Serif Display** | display headlines, the masthead/app name, verse-of-the-day numbers, drop caps | 24–90pt, regular only (never bold) |
| **Crimson Pro** | all body copy — scripture text, prayers, reflections, descriptions | 13–16pt, 400 / 600, italic available |
| **Old Standard TT** | italic flourishes, captions, verse references, subheads, taglines, soft labels | 10–17pt, always italic, always small |
| **IBM Plex Mono** | all metadata — timestamps, kickers, button labels, attributions, status pills, counts | 8–11pt, 400 / 500, **always uppercase + letter-spacing** |
| **Special Elite** | typewriter character — community-board notes, member testimonies, "established" marks | character only, never headlines or running prose |

---

## Visual language

### Rules & borders (the backbone of the layout)
- `3px double black` — major section dividers, masthead underline, end-of-page framing
- `1px solid black` — card edges, list dividers, button/form borders
- `1px dotted faded ink` — soft dividers between prayer entries or briefs
- `1px dashed accent/black` — informal frames (community notes, testimonies)

No rounded corners. No drop shadows. No gradients.

### Buttons
Rectangular. Mono uppercase labels with letter-spacing. Two variants:
- **Primary** — solid black background, paper-colored text. Hover shifts background to **accent red**.
- **Secondary** — transparent background, black text, 1px black border. Hover shifts background to **paper-deep**.

### Form fields
1px black border. No radius, no shadow. No focus ring except a subtle ink-soft inset on the active state. Helper text below in italic Old Standard TT, faded ink color.

### Section headers
1. Mono uppercase "eyebrow" label in accent color
2. DM Serif Display headline (large)
3. Italic Old Standard TT subline

### Paper texture
Every screen gets a grain overlay: a fixed-positioned div with `mix-blend-mode: multiply`, low opacity, an SVG noise pattern as background. Subtle — present but not distracting. It softens the digital edge.

---

## Iconography

Minimal — the product favors typography over icons.

When icons are unavoidable:
- Prefer typographic ornaments where possible (✝ ❦ ☧ ✟ ❀ ✎ ⊙)
- Otherwise use **Phosphor Icons**, regular weight (not bold)
- Never use color in icons — always ink black or accent red

A "next" / forward affordance can use a DM Serif Display "→" rather than an icon font.

---

## Imagery

Text-first and restrained. Let scripture and typography carry the page rather than decorating it with photos.

- No stock photography.
- Where imagery appears (e.g. a community illustration or seasonal mark), keep it to two colors max — black and accent red — and line-art / editorial style.
- Marketing imagery: direct app screenshots in stylized phone frames, or two-color editorial illustration.

---

## What to keep when adapting

- The palette and the five typefaces are the identity — don't add to them.
- The "no rounded corners / no shadows / no gradients" rule is what makes it feel like print. Removing it removes the soul.
- Use color sparingly. The reverent, quiet feeling comes from restraint.
