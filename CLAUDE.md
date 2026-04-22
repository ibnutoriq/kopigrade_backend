# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KopiGrade is a Rails 8.1 backend for an AI-powered coffee bean quality grading system targeting Banyuwangi, Indonesia. It uses Google Gemini 1.5 Flash to generate grading advice based on the SNI 01-2907-2008 Indonesian coffee grading standard.

## Commands

### Development

```bash
bin/dev                        # Start web server + Tailwind watcher
bin/jobs start                 # Start Solid Queue worker (separate terminal)
bin/setup                      # Full first-time setup (bundle, db:prepare, db:reset)
```

### Database

```bash
bin/rails db:create            # Create primary + queue databases
bin/rails db:migrate           # Run primary migrations
bin/rails db:migrate:queue     # Run queue migrations
bin/rails db:seed              # Seed default admin (admin@kopigrade.local / password123)
```

### Testing

```bash
bin/rails test                        # Run all tests
bin/rails test test/models/user_test.rb  # Run a single test file
bin/rails test test/models/user_test.rb:15  # Run a single test by line number
bin/rails test:system                 # Run system tests
```

### Linting & Security

```bash
bin/rubocop                    # Lint (rubocop-rails-omakase style)
bin/brakeman --no-pager        # Static security analysis
bin/bundler-audit              # Dependency vulnerability scan
bin/importmap audit            # JS dependency audit
bin/ci                         # Full CI: setup → lint → security → tests
```

## Architecture

### Authentication

Session-based auth via signed cookies (httponly, same_site: lax). The `Authentication` concern in `app/controllers/concerns/authentication.rb` handles `require_authentication` and `allow_unauthenticated_access`. `Current` (`app/models/current.rb`) is a `CurrentAttributes` subclass that exposes `Current.session` and `Current.user` throughout the request lifecycle.

Admin access is gated by `User#admin` (boolean). `Admin::BaseController` enforces this with `before_action :require_admin`.

### Key Models

- **User** — `has_secure_password`, normalizes `email_address` to lowercase. Session tokens are separate `Session` records.
- **Session** — Tracks user sessions with `user_agent` and `ip_address`.
- **ScanResult** — Core domain object. Stores bean counts (`total_beans`, `black_defects`, `broken_defects`), geolocation (`latitude`, `longitude`, `sub_district`), and AI-generated `advice`. Status enum: `pending` → `graded` or `failed`.

### AI Integration

`GeminiAdvisorService` (`app/services/gemini_advisor_service.rb`) wraps the `gemini-ai` gem. The Gemini client is initialized in `config/initializers/gemini.rb` using `GOOGLE_API_KEY` — if the key is absent it silently skips initialization. The service returns a `Result` Struct with `advice` and `success?`.

### Background Jobs

Solid Queue is the job adapter, backed by a **separate PostgreSQL database** (`*_queue`). In development and production it runs in-process via Puma (configured via `SOLID_QUEUE_IN_PUMA=true`). Queue migrations are at `db/queue_schema.rb` and require `bin/rails db:migrate:queue` separately.

### Multi-Database Setup

The app uses four separate databases in production: primary, queue, cache, and cable — all PostgreSQL. In development, only primary and queue are active. Always run migrations for all databases when schema changes affect queue, cache, or cable.

### Frontend

Propshaft asset pipeline, Tailwind CSS 4, Hotwire (Turbo + Stimulus), and importmap (no Node/bundler needed). CSS is compiled by `bin/rails tailwindcss:watch`, which `bin/dev` starts automatically via Foreman.

### Deployment

Kamal 2 with Docker multi-stage builds. The entrypoint (`bin/docker-entrypoint`) runs `db:prepare` before starting Puma. `RAILS_MASTER_KEY` must be available at deploy time. See `config/deploy.yml` for server configuration.

## Environment Variables

| Variable | Required | Purpose |
|---|---|---|
| `GOOGLE_API_KEY` | Optional | Gemini AI — grading advice degrades gracefully without it |
| `RAILS_MASTER_KEY` | Production | Decrypts credentials |
| `JOB_CONCURRENCY` | Optional | Solid Queue threads (default: 1) |

## Test Helpers

`test/test_helpers/session_test_helper.rb` provides `sign_in_as(user)` and `sign_out` for integration tests. It's included automatically in `ActionDispatch::IntegrationTest`.

Fixtures are in `test/fixtures/`. Parallel test execution is enabled by default.
