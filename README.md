# KopiGrade Backend

Rails 8 backend for an AI-powered coffee bean quality grading system targeting farmers in Banyuwangi, Indonesia (Ijen, Raung, Kalibaru, Glenmore regions). A Flutter app counts bean defects offline; this backend receives scan data, computes an SNI grade, and generates post-harvest advice via Google Gemini.

## Stack

| Layer | Technology |
|---|---|
| Runtime | Ruby 3.4.4, Rails 8.1 |
| Database | PostgreSQL 16 (primary + queue) |
| Background jobs | Solid Queue (in-process via Puma) |
| Admin auth | Rails 8 session-based (bcrypt, httponly cookie) |
| API auth | Bearer token SHA256 (`ApiClient`) |
| AI | gemini-ai gem — Gemini 1.5 Flash |
| Scraping | HTTParty + Nokogiri (Siskaperbapo Jatim) |
| Rate limiting / CORS | rack-attack + rack-cors |
| Admin frontend | Tailwind CSS 4, Hotwire (Turbo + Stimulus), Chartkick |
| Testing | RSpec Rails + FactoryBot + WebMock |
| Deployment | Docker multi-stage + Kamal |

---

## Prerequisites

- Ruby 3.4.4 (via rbenv or asdf)
- PostgreSQL 16+
- `foreman` gem (installed automatically by `bin/dev`)

---

## First-time Setup

```bash
bundle install

# Create and migrate databases (primary + queue)
bin/rails db:create db:migrate
bin/rails db:migrate:queue

# Seed: admin user, sample ApiClient (token printed once), today's market prices
bin/rails db:seed
```

The seed task prints the ApiClient bearer token to stdout once — store it, it cannot be retrieved again.

---

## Configuration

### Rails Credentials

```bash
bin/rails credentials:edit
```

```yaml
gemini_api_key: sk-...
admin_seed_email: admin@kopigrade.local
admin_seed_password: password123
```

### Environment Variables

| Variable | Purpose |
|---|---|
| `GOOGLE_API_KEY` | Google AI Studio key — app degrades gracefully without it |
| `RAILS_MASTER_KEY` | Decrypts credentials in production |
| `CORS_ALLOWED_ORIGINS` | Comma-separated origins allowed for `/api/*` |
| `JOB_CONCURRENCY` | Solid Queue thread count (default: 1) |
| `SOLID_QUEUE_IN_PUMA` | Set `true` to run the worker inside Puma |

---

## Running the App

```bash
# Web server + Tailwind watcher
bin/dev

# Solid Queue worker (separate terminal, optional in development)
bin/jobs start
```

Admin dashboard: `http://localhost:3000`
Default login: `admin@kopigrade.local` / `password123`

---

## Flutter API

### Authentication

All API endpoints require:

```
Authorization: Bearer <token>
```

Generate a token with:

```bash
bin/rake "api:clients:create[Flutter Mobile v1]"
```

### Endpoints

#### `POST /api/v1/scan_results`

```json
{
  "scan_result": {
    "device_id": "uuid-v4",
    "total_beans": 500,
    "black_defects": 20,
    "broken_defects": 30,
    "latitude": -8.2191,
    "longitude": 114.0112,
    "variety": "robusta",
    "scanned_at": "2026-04-22T08:30:00+07:00"
  }
}
```

Response `202 Accepted` — returns the SNI estimate immediately and enqueues `GeminiAdvisorJob`:

```json
{
  "id": 1,
  "status": "pending",
  "sni_defect_value": 54.0,
  "sni_grade": "Mutu 4a",
  "sni_grade_label": "Mutu 4a (cacat 45–60)",
  "export_eligible": true,
  "partial_coverage_notice": "Estimasi SNI hanya berdasarkan biji hitam dan biji pecah; ...",
  "polling_url": "/api/v1/scan_results/1"
}
```

#### `GET /api/v1/scan_results/:id`

Poll until `status == "analyzed"`. Response includes `advice` (Gemini output) when complete.

#### `GET /api/v1/market_prices?variety=robusta&date=2026-04-22`

Both parameters are optional. Defaults to the latest robusta price.

---

## SNI 01-2907-2008 Grading Methodology

> **Partial coverage caveat**

The ML Kit model currently detects only two defect types:
- **Full black beans** (defect value: 1.0 per bean)
- **Broken beans** (defect value: 0.2 per bean)

Because other defect types (immature, bored, brown, hull, foreign matter) are not yet detected, the computed SNI defect value is a **lower bound**. All responses, dashboard values, and Gemini prompts explicitly label this as an estimate.

### Extrapolation to 300 g sample

```
ref_beans  = 1800 (robusta) | 2000 (arabika)
scale      = ref_beans / total_beans_in_sample
raw_defect = (black_defects × 1.0) + (broken_defects × 0.2)
sni_value  = raw_defect × scale   # rounded to 1 decimal
```

### Grade thresholds

| Grade | Robusta | Arabika |
|---|---|---|
| Mutu 1 | ≤ 11 | ≤ 11 |
| Mutu 2 | 12–25 | 12–25 |
| Mutu 3 | 26–44 | 26–44 |
| Mutu 4a | 45–60 | — |
| Mutu 4b | 61–80 | — |
| Mutu 4 | — | 45–80 |
| Mutu 5 | 81–150 | 81–150 |
| Mutu 6 | 151–225 | 151–225 |

Export eligibility per ICO Resolution 407: Robusta ≤ 150, Arabika ≤ 86.

Full constants: `lib/sni/defect_values.rb` and `config/sni_grading.yml`.

---

## Background Jobs

| Job | Trigger | Description |
|---|---|---|
| `GeminiAdvisorJob` | After `POST /api/v1/scan_results` | Resolves sub-district → calls Gemini → updates `advice` |
| `PriceScraperJob` | Cron `0 23 * * *` UTC (= 06:00 WIB) | Scrapes Siskaperbapo Jatim → upserts `MarketPrice` |

Recurring schedule: `config/recurring.yml`.
Retry policy: 3 attempts with polynomial backoff via `retry_on StandardError`.

---

## Admin Dashboard

| Path | Features |
|---|---|
| `/admin/dashboard` | MTD metric cards, daily scan volume chart, avg defect value by sub-district (bar), SNI grade distribution (pie), latest 10 scans |
| `/admin/scan_results` | Turbo Frame filters (sub-district, status, grade, date range), show with OSM map pin, delete, CSV export |
| `/admin/market_prices` | Full CRUD + "Scrape Now" button |
| `/admin/users` | Admin account management |

---

## Testing

```bash
# Run all 55 specs
bundle exec rspec

# Single file
bundle exec rspec spec/models/scan_result_spec.rb

# Lint
bin/rubocop

# Security scan
bin/brakeman --no-pager

# Full CI
bin/ci
```

Test coverage:
- **Model spec** — validations + all SNI grade boundaries (Mutu 1–6, Robusta 4a/4b, Arabika merged Mutu 4)
- **Service spec** — `ReverseGeocodingService`, `SiskaperbapoScraperService` (WebMock stubs)
- **Job spec** — `GeminiAdvisorJob` (rspec-mocks `instance_double`)
- **Request spec** — API happy path, 401, 422

---

## Deployment (Kamal)

```bash
# First deploy
kamal setup

# Redeploy
kamal deploy
```

Update `config/deploy.yml` with your actual VPS IP. A PostgreSQL 16 accessory is pre-configured; alternatively point `DB_HOST` to a managed database.

Health check: `GET /up`

---

## Project Structure

```
app/
  controllers/
    api/v1/                    # Flutter API (BaseController, ScanResults, MarketPrices)
    admin/                     # Dashboard, ScanResults, MarketPrices, Users, Exports
    concerns/
      authenticatable/api.rb   # Bearer token authentication
      authentication.rb        # Cookie session authentication (admin)
  models/
    concerns/sni_grading.rb    # SNI grading logic (before_save callback)
  services/
    gemini_advisor_service.rb  # Builds Gemini prompt and parses response
    siskaperbapo_scraper_service.rb
    reverse_geocoding_service.rb
  jobs/
    gemini_advisor_job.rb
    price_scraper_job.rb
config/
  sni_grading.yml              # Grade thresholds, reference beans per 300 g
  banyuwangi_sub_districts.yml # 25 sub-district bounding boxes
  recurring.yml                # Solid Queue scheduled jobs
  initializers/
    gemini.rb                  # GEMINI_CLIENT constant (graceful skip if key absent)
    rack_attack.rb             # API rate limiting (60 req/min per token)
    cors.rb                    # CORS for /api/* paths
lib/
  sni/defect_values.rb         # SNI defect value constants (all 15 types)
  tasks/api_clients.rake       # rake api:clients:create[name]
spec/
  models/ services/ jobs/ requests/
  factories/                   # FactoryBot factories
  support/                     # session_helper, api_token_helper
```
