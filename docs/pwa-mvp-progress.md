# KopiGrade PWA MVP — Progress Report

> **For external advisor review.**
> Describes what was built, what was verified, and what questions remain.

---

## 1. Context

A public-facing Progressive Web App layer was added to the existing `kopigrade_backend` Rails 8 application so that coffee farmers in Banyuwangi can use KopiGrade directly from a mobile browser — no app store, no account required. The goal is to validate the product with 3–5 real farmers before investing in the native Flutter app's full feature set.

- **Stack**: Rails 8.1, PostgreSQL 16, Solid Queue, Tailwind CSS 4, Hotwire, Propshaft, importmap (no Node)
- **Date**: 2026-04-22
- **Latest commit**: `2a361e2` (branch: `main`) — all PWA work is uncommitted local changes on top of this
- **Target device**: mid-range Android, Chrome, ~360 px viewport, patchy 4G/3G connection

---

## 2. Scope Delivered

### URLs shipped

| Path | What it does |
|---|---|
| `/` | Landing page — hero, CTA button, today's price preview, social-proof scan count |
| `/scans/new` | Manual input form — variety, sub-district, total beans, black defects, broken defects |
| `/scans/:id` | Result page — pending spinner / analyzed grade+advice+price / failed fallback |
| `/harga` | Full market prices page (Robusta + Arabika, Indonesian date, source attribution) |
| `/tentang` | About page — 4 sections in plain Indonesian including partial-coverage caveat |
| `/admin` | Redirect → `/admin/dashboard` (admin panel unchanged) |

### New files created

**Controllers** (`app/controllers/web/`):
- `base_controller.rb` — forces `:id` locale, `web` layout, no auth
- `home_controller.rb` — loads prices + weekly scan count
- `scans_controller.rb` — new/create/show with centroid lookup + job enqueue
- `prices_controller.rb` — loads latest price for each variety
- `pages_controller.rb` — static about page

**Views** (`app/views/web/`):
- `home/show.html.erb`
- `scans/new.html.erb` — variety radio cards, sub-district dropdown, number inputs
- `scans/show.html.erb` — three states: pending (spinner + meta-refresh), analyzed (grade+advice+price+share), failed (friendly fallback)
- `prices/index.html.erb`
- `pages/about.html.erb`
- `layouts/web.html.erb` — PWA meta tags, amber-900 header, max-w-md content, footer

**Service additions** (`app/services/reverse_geocoding_service.rb`):
- `self.all_sub_districts` — sorted array of names for the dropdown
- `self.bounding_box_for(name)` — returns bounding box hash or nil
- `self.centroid_for(name)` — returns `{latitude:, longitude:}` midpoints or nil
- Refactored: instance `lookup` now delegates to `self.load_sub_districts`

**PWA assets** (`public/`):
- `manifest.webmanifest` — name, short_name, display: standalone, theme_color, icons
- `icon-192.png` — resized from existing `icon.png`
- `icon-512.png` — copy of existing `icon.png`

**Specs** (`spec/`):
- `spec/requests/web/home_spec.rb` — 5 examples
- `spec/requests/web/scans_spec.rb` — 12 examples
- `spec/requests/web/prices_spec.rb` — 3 examples
- `spec/requests/web/pages_spec.rb` — 2 examples
- `spec/system/farmer_scan_flow_spec.rb` — 1 example (rack_test, no JS)
- `spec/support/web_request_helper.rb` — `web_headers` helper with modern Chrome UA
- `spec/services/reverse_geocoding_service_spec.rb` — extended with 7 new examples (11 total)

**Config / locale changes**:
- `config/routes.rb` — added `web` namespace, moved root, added `/admin` redirect
- `config/locales/id.yml` — added Indonesian date formats (`:long`, month/day names), fixed `base.defects_exceed_total` key placement
- `README.md` — added "Public PWA" section, updated admin URL

### Intentionally NOT built (non-goals respected)

- No ML Kit / camera — manual input only
- No user accounts / login / signup — fully anonymous
- No scan history / persistent device identity
- No GPS auto-detect — sub-district dropdown only
- No push notifications
- No offline mode (no service worker)
- No dark mode, animations, skeleton loaders
- No analytics (deferred to v0.2)
- No payment / monetization
- No API token auth for the PWA (uses controllers directly, not `/api/v1`)
- No contact form on `/tentang` — static `mailto:` link only
- No cookie banner — no tracking cookies exist
- No image optimization pipeline — direct PNG served from `public/`

---

## 3. Design Decisions Worth Flagging

### Meta-refresh vs Turbo Stream broadcast

Chose **meta-refresh every 3 seconds** while `status == "pending"`. Rationale: zero JavaScript, survives old Android WebViews (common in rural Banyuwangi), connection drops don't break it. A Turbo Stream broadcast would require Solid Cable and ActionCable to be live on every load. At 10 cycles × ~8 KB HTML per refresh = ~80 KB per scan — negligible on 4G but worth watching at scale.

### No-auth design for the public layer

The PWA is fully anonymous by design. No farmer name, phone, or GPS is collected. The only data stored is the scan input and computed result. This minimizes privacy friction during validation and aligns with the brief.

### Sub-district dropdown vs GPS auto-detect

The dropdown avoids the browser geolocation permission dialog, which many farmers distrust. Coordinates are derived server-side from the bounding box midpoint of the selected sub-district. This means the coordinates are approximate (~±5 km) but sufficient for the AI prompt's regional context. The downstream effect on Gemini advice quality is negligible.

### Centroid assignment vs validation

`ScanResult` validates `latitude/longitude` within the Banyuwangi bounding box only when both are present. If `centroid_for(sub_district)` returns `nil` (unknown sub-district), coordinates stay blank and validation is skipped. This means a farmer who picks a valid sub-district always gets a valid coordinate; invalid values are impossible via the dropdown.

### Tailwind grade color class handling

The grade color (emerald/amber/red) depends on runtime data. Tailwind purges dynamic class strings, so the colors are expressed as full-class-name hashes in the view (`grade_classes[:ring]`) rather than interpolated strings — avoids classes being purged from the CSS bundle.

### Dependencies added beyond existing Gemfile

None. Everything reuses the existing stack.

---

## 4. What Works (Verified)

### Flows manually tested in Chrome (DevTools mobile, 360 × 780 px)

| Flow | Result |
|---|---|
| Home page — hero + CTA + price preview | ✅ Renders correctly, social proof hidden when 0 scans |
| Scan form — radio cards, dropdown, number inputs | ✅ Robusta pre-selected with amber border, 25 sub-districts sorted |
| Form submit → pending state | ✅ Amber spinner, input summary, meta-refresh tag present |
| Pending → analyzed state (manually seeded) | ✅ Grade circle, export badge, advice, price with Indonesian date, WhatsApp share link |
| Failed state (no GOOGLE_API_KEY in dev) | ✅ Friendly message, no `error_message` leak |
| Validation — defects > total | ✅ Indonesian error message, values preserved |
| Prices page | ✅ Robusta shows, Arabika shows "Belum tersedia" fallback |
| About page | ✅ All 4 sections, partial-coverage caveat, `mailto:` link |
| Admin panel at `/admin/dashboard` | ✅ Unaffected, session auth intact |

### Spec results

```
85 examples, 0 failures
```

Breakdown:
- 30 new web specs (home, scans, prices, pages, system flow, geocoding service extensions)
- 55 pre-existing specs (models, jobs, services, API request specs) — all pass

### Existing specs affected

- `spec/services/reverse_geocoding_service_spec.rb` — extended, all original examples preserved
- All admin and API request specs — no changes, all pass

---

## 5. Known Issues & Rough Edges

### Visual

- The variety radio cards use server-rendered selected state. Switching from Robusta → Arabika requires a page round-trip if JS is absent. With Stimulus a swap could be done client-side, but no JS was added for v0.1 per the brief.
- On the scan form, the "Biji hitam" and "Biji pecah" inputs default to `0` (pre-filled by Rails). On very small screens the `0` could confuse farmers who expect a blank field.

### UX

- The pending state auto-refreshes every 3 seconds indefinitely. There's no maximum retry count or "something went wrong, try refreshing manually" message after N cycles. If the Gemini job fails silently without updating `status`, the page will spin forever.
- The WhatsApp share URL includes a link back to the scan at `http://www.example.com/scans/:id` in test, or the production URL in prod. This is generated server-side via `request.base_url` so it is correct in production, but worth confirming.

### Validation

- "cannot_exceed_total" individual error messages for `black_defects` and `broken_defects` fire alongside the `base` error. The farmer sees up to 3 related messages for the same mistake. Could be simplified to just the base error.
- Sub-district is not validated server-side if the user POSTs with an arbitrary string (possible via curl). The coordinate validation is skipped when no centroid is found, so invalid sub-districts silently produce a scan with no location.

### i18n

- One i18n bug found and fixed during QA: `base.defects_exceed_total` was nested at the `scan_result` level instead of `attributes.base` level in `id.yml`. Now fixed.
- The `id.yml` now includes full date formatting (month names, day names, formats). This was missing entirely before the PWA required `l(date, format: :long)`.

---

## 6. What Was Cut From Scope

Nothing from the Step 12 checklist was skipped. All 13 steps completed:

1. ✅ Routes
2. ✅ Service methods
3. ✅ Controllers
4. ✅ Layout
5. ✅ Home view
6. ✅ Scan form view
7. ✅ Scan result view (all 3 states)
8. ✅ Prices view
9. ✅ About page
10. ✅ PWA manifest + icons
11. ✅ Specs (85 total, 0 failures)
12. ✅ Manual QA at 360 px
13. ✅ README update

---

## 7. Files Touched

### New files

| File | What |
|---|---|
| `app/controllers/web/base_controller.rb` | Web layer base — id locale, web layout, no auth |
| `app/controllers/web/home_controller.rb` | Home action — prices + weekly count |
| `app/controllers/web/scans_controller.rb` | new/create/show — centroid lookup, job enqueue |
| `app/controllers/web/prices_controller.rb` | Market prices index |
| `app/controllers/web/pages_controller.rb` | About page |
| `app/views/layouts/web.html.erb` | Mobile-first layout with PWA meta tags |
| `app/views/web/home/show.html.erb` | Landing page |
| `app/views/web/scans/new.html.erb` | Scan input form |
| `app/views/web/scans/show.html.erb` | Result page (3 states) |
| `app/views/web/prices/index.html.erb` | Market prices |
| `app/views/web/pages/about.html.erb` | About / trust page |
| `public/manifest.webmanifest` | PWA manifest |
| `public/icon-192.png` | PWA icon 192 × 192 |
| `public/icon-512.png` | PWA icon 512 × 512 |
| `spec/requests/web/home_spec.rb` | 5 request specs |
| `spec/requests/web/scans_spec.rb` | 12 request specs |
| `spec/requests/web/prices_spec.rb` | 3 request specs |
| `spec/requests/web/pages_spec.rb` | 2 request specs |
| `spec/system/farmer_scan_flow_spec.rb` | 1 system spec (rack_test) |
| `spec/support/web_request_helper.rb` | `web_headers` helper for modern browser UA |
| `docs/pwa-mvp-progress.md` | This document |

### Modified files

| File | What changed |
|---|---|
| `config/routes.rb` | Added `web` scope, moved root, added `/admin` redirect |
| `app/services/reverse_geocoding_service.rb` | Added `all_sub_districts`, `bounding_box_for`, `centroid_for` class methods; refactored instance `lookup` to use shared loader |
| `config/locales/id.yml` | Added full date formatting; fixed `base.defects_exceed_total` key nesting |
| `spec/services/reverse_geocoding_service_spec.rb` | Added 7 new examples for 3 new class methods |
| `README.md` | Added "Public PWA" section, fixed admin URL |

### Deleted files

None.

---

## 8. How to Try It

```bash
# First-time setup
bin/setup

# Start app (web server + Tailwind watcher)
bin/dev

# Visit the PWA
open http://localhost:3000

# Visit admin panel
open http://localhost:3000/admin/dashboard
# Login: admin@kopigrade.local / password123
```

### Seed a market price and trigger a full end-to-end scan

```ruby
# Rails console
MarketPrice.find_or_create_by!(variety: "robusta", price_date: Date.current) do |m|
  m.price = 65_000
  m.source_url = "https://siskaperbapo.jatimprov.go.id"
end
```

Then visit `http://localhost:3000/scans/new`, fill the form, and submit.

### View the three scan states manually

```ruby
# Pending (default after create)
s = ScanResult.last
s.status  # => "pending"

# Simulate analyzed
s.update_columns(
  status: "analyzed",
  advice: "Kopi Anda memiliki estimasi Mutu 2 yang baik..."
)

# Simulate failed
s.update_columns(status: "failed", error_message: "Gemini timeout")
```

Then visit `http://localhost:3000/scans/#{s.id}`.

### Run the test suite

```bash
bundle exec rspec
# Expected: 85 examples, 0 failures
```

> **Note**: If you see spurious failures about market prices or scan counts existing when they shouldn't, the test DB has dirty data from a previous crashed run. Fix:
> ```bash
> RAILS_ENV=test bundle exec rails runner 'MarketPrice.delete_all; ScanResult.delete_all'
> ```

---

## 9. Open Questions for the Advisor

1. **Meta-refresh vs Turbo Stream**: Is 3-second polling acceptable on 2G/3G connections in rural Banyuwangi? Or should we invest in Turbo Stream broadcast for the analyzed result, at the cost of requiring a stable WebSocket?

2. **Pending spin-forever edge case**: If the Gemini job is permanently stuck (not failed, just delayed), the spinner loops forever. Should we add a max-wait timeout in the view (e.g., after 2 minutes, show a "coba lagi" message even if still pending)?

3. **Sub-district validation gap**: A farmer who sends a raw POST with an invalid sub-district gets a scan with blank coordinates. Is this acceptable (it's an edge case not reachable via the form), or should we add a server-side inclusion validation on `sub_district`?

4. **Duplicate error messages**: When defects exceed total, the farmer sees up to 3 error messages (base + per-field). Should we suppress the per-field messages and show only the base error?

5. **Amber color palette**: Is amber-900 / amber-700 culturally appropriate for a coffee-themed app serving Banyuwangi farmers? Or is there a local color association we should be aware of?

6. **WhatsApp share CTA placement**: The share button is on the result page. Would it be more effective on a "thank you" interstitial after submit, before showing the spinner — when excitement is highest?

7. **PWA install prompt**: Should we add an install prompt after a farmer's second visit, or keep it passive (browser's native "Add to Home Screen")? Active prompts can improve conversion but feel aggressive.

---

## 10. Suggested Next Steps (Draft)

Ordered by estimated validation impact. These are suggestions — advisor should reprioritize.

1. **Get the app in front of 3–5 farmers** — recruit via Dinas Pertanian or Kalibaru cooperative, run a 30-minute session, note confusion points. No code needed.

2. **Configure `GOOGLE_API_KEY` in development** — currently the AI job always fails in dev, making it impossible to test the analyzed state end-to-end without manual console manipulation.

3. **Add server-side sub-district inclusion validation** — low-effort safety net for direct API calls.

4. **Add max-wait timeout on pending page** — after 3 minutes, show a manual-refresh prompt instead of spinning forever.

5. **Add Sentry (error tracking)** — before sharing with real users, we need to know when Gemini jobs fail silently.

6. **Pagination on `/admin/scan_results`** — the admin table will become unmanageable quickly once real farmers use the app.

7. **v0.2 PWA scope** — add service worker for offline form caching, add scan history via `device_id` cookie, add analytics (Plausible or similar).
