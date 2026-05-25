# Render.com Deployment Design

**Date:** 2026-05-25
**Project:** KopiGrade Backend (Rails 8.1)

## Goal

Deploy the KopiGrade Rails app to Render.com using the existing Dockerfile, a single managed PostgreSQL instance, and Solid Queue running in-process with Puma (free tier).

## Architecture

| Component | Render resource | Notes |
|---|---|---|
| Web app | Web Service (Docker, free) | Builds from existing `Dockerfile` |
| Database | PostgreSQL (free, 90-day trial) | One DB for primary + queue + cache + cable |
| Background jobs | In-process (Solid Queue via Puma) | `SOLID_QUEUE_IN_PUMA=true` |

All four Rails databases (primary, queue, cache, cable) are consolidated onto the single Render Postgres instance. Each uses separate table namespaces so there are no conflicts.

## Changes Required

### 1. `render.yaml` (new file, project root)

Render Infrastructure as Code blueprint defining:
- Web service: Docker build, free instance, `DATABASE_URL` linked from the Postgres service
- PostgreSQL: free plan, linked to the web service
- Environment variables (clear + secret)

### 2. `config/database.yml` — production section

Replace the four separate databases with a single `DATABASE_URL`-based config:

```yaml
production:
  primary:
    url: <%= ENV["DATABASE_URL"] %>
  queue:
    url: <%= ENV["DATABASE_URL"] %>
    migrations_paths: db/queue_migrate
  cache:
    url: <%= ENV["DATABASE_URL"] %>
    migrations_paths: db/cache_migrate
  cable:
    url: <%= ENV["DATABASE_URL"] %>
    migrations_paths: db/cable_migrate
```

Rails will use the same Postgres connection for all four, with each Solid adapter managing its own tables.

### 3. `bin/docker-entrypoint`

Extend to also run queue (and optionally cache/cable) migrations on startup:

```bash
if [ "${@: -2:1}" == "./bin/rails" ] && [ "${@: -1:1}" == "server" ]; then
  ./bin/rails db:prepare
  ./bin/rails db:migrate:queue
  ./bin/rails db:migrate:cache
  ./bin/rails db:migrate:cable
fi
```

## Environment Variables

| Variable | Source | Notes |
|---|---|---|
| `DATABASE_URL` | Auto-injected by Render | Links to managed Postgres |
| `RAILS_MASTER_KEY` | Secret (set manually) | From `config/master.key` |
| `GOOGLE_API_KEY` | Secret (set manually) | Gemini AI key |
| `SOLID_QUEUE_IN_PUMA` | Clear (`true`) | Runs jobs in web process |
| `JOB_CONCURRENCY` | Clear (`2`) | Solid Queue threads |
| `RAILS_LOG_TO_STDOUT` | Clear (`true`) | Required for Render log streaming |

## Deployment Steps (post-implementation)

1. Push code to GitHub
2. Go to Render dashboard → New → Blueprint → connect repo → Render reads `render.yaml`
3. Set secret env vars (`RAILS_MASTER_KEY`, `GOOGLE_API_KEY`) in the Render dashboard
4. Deploy — entrypoint runs migrations automatically

## Out of Scope

- Custom domain / SSL (can be added later via Render dashboard)
- Separate worker service (in-process is sufficient for this workload)
- Render disk / persistent storage for Active Storage (current setup uses local storage)
