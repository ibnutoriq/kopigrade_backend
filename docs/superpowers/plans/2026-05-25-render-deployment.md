# Render Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy KopiGrade Rails 8.1 to Render.com using Docker, a single managed PostgreSQL instance, and Solid Queue running in-process with Puma.

**Architecture:** A single Render Web Service (Docker) connects to one Render-managed PostgreSQL. All four Rails database roles (primary, queue, cache, cable) share the same Postgres connection via `DATABASE_URL`. Solid Queue runs in-process via `SOLID_QUEUE_IN_PUMA=true` — no separate worker service needed.

**Tech Stack:** Rails 8.1, PostgreSQL, Solid Queue / Cache / Cable, Docker, Render.com, render.yaml (Blueprint IaC)

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `render.yaml` | Create | Render Blueprint — declares web service + Postgres + env vars |
| `config/database.yml` | Modify | Consolidate production DB roles onto single `DATABASE_URL` |
| `bin/docker-entrypoint` | Modify | Run queue/cache/cable migrations on startup |

---

### Task 1: Consolidate production database config

The current `database.yml` production section references four separate databases with username/password. On Render, a single `DATABASE_URL` covers everything. We point all four roles at it so only one Postgres instance is needed.

**Files:**
- Modify: `config/database.yml`

- [ ] **Step 1: Open `config/database.yml` and replace the entire `production:` block**

Replace:
```yaml
production:
  primary: &primary_production
    <<: *default
    database: kopigrade_backend_production
    username: kopigrade_backend
    password: <%= ENV["KOPIGRADE_BACKEND_DATABASE_PASSWORD"] %>
  cache:
    <<: *primary_production
    database: kopigrade_backend_production_cache
    migrations_paths: db/cache_migrate
  queue:
    <<: *primary_production
    database: kopigrade_backend_production_queue
    migrations_paths: db/queue_migrate
  cable:
    <<: *primary_production
    database: kopigrade_backend_production_cable
    migrations_paths: db/cable_migrate
```

With:
```yaml
production:
  primary:
    url: <%= ENV["DATABASE_URL"] %>
  cache:
    url: <%= ENV["DATABASE_URL"] %>
    migrations_paths: db/cache_migrate
  queue:
    url: <%= ENV["DATABASE_URL"] %>
    migrations_paths: db/queue_migrate
  cable:
    url: <%= ENV["DATABASE_URL"] %>
    migrations_paths: db/cable_migrate
```

- [ ] **Step 2: Verify YAML syntax is valid**

```bash
bin/rails runner "puts ActiveRecord::Base.configurations.configs_for(env_name: 'production').map(&:name)" RAILS_ENV=production DATABASE_URL=postgres://localhost/test 2>&1 | head -10
```

Expected output (4 lines): `primary`, `cache`, `queue`, `cable`

- [ ] **Step 3: Commit**

```bash
git add config/database.yml
git commit -m "Configure production databases to use single DATABASE_URL for Render"
```

---

### Task 2: Extend docker-entrypoint to run all migrations

On startup, the entrypoint currently only runs `db:prepare` (primary migrations). Solid Queue/Cache/Cable each have their own migration paths and must be migrated separately.

**Files:**
- Modify: `bin/docker-entrypoint`

- [ ] **Step 1: Replace the entrypoint body**

Open `bin/docker-entrypoint` and replace its contents with:

```bash
#!/bin/bash -e

# If running the rails server then create or migrate existing database
if [ "${@: -2:1}" == "./bin/rails" ] && [ "${@: -1:1}" == "server" ]; then
  ./bin/rails db:prepare
  ./bin/rails db:migrate:queue
  ./bin/rails db:migrate:cache
  ./bin/rails db:migrate:cable
fi

exec "${@}"
```

- [ ] **Step 2: Verify the file is executable**

```bash
ls -la bin/docker-entrypoint
```

Expected: permissions start with `-rwx` (executable). If not, run:
```bash
chmod +x bin/docker-entrypoint
```

- [ ] **Step 3: Commit**

```bash
git add bin/docker-entrypoint
git commit -m "Run queue/cache/cable migrations in docker-entrypoint for Render"
```

---

### Task 3: Create render.yaml Blueprint

`render.yaml` tells Render exactly what services to create when you connect the repo. It defines the web service (Docker), the Postgres database, and all environment variables.

**Files:**
- Create: `render.yaml`

- [ ] **Step 1: Create `render.yaml` in the project root**

```yaml
services:
  - type: web
    name: kopigrade-backend
    runtime: docker
    plan: free
    healthCheckPath: /up
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: kopigrade-db
          property: connectionString
      - key: RAILS_MASTER_KEY
        sync: false
      - key: GOOGLE_API_KEY
        sync: false
      - key: SOLID_QUEUE_IN_PUMA
        value: "true"
      - key: JOB_CONCURRENCY
        value: "2"
      - key: RAILS_LOG_TO_STDOUT
        value: "true"
      - key: RAILS_SERVE_STATIC_FILES
        value: "true"

databases:
  - name: kopigrade-db
    plan: free
    databaseName: kopigrade_production
    user: kopigrade
```

- [ ] **Step 2: Verify the file is valid YAML**

```bash
ruby -e "require 'yaml'; YAML.load_file('render.yaml'); puts 'OK'"
```

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add render.yaml
git commit -m "Add render.yaml Blueprint for Render.com deployment"
```

---

### Task 4: Push to GitHub and deploy on Render

With code changes done, connect the repo to Render and trigger the first deploy.

**Files:** none (Render dashboard steps)

- [ ] **Step 1: Push the branch to GitHub**

```bash
git push origin main
```

- [ ] **Step 2: Create a new Blueprint on Render**

1. Go to [dashboard.render.com](https://dashboard.render.com)
2. Click **New** → **Blueprint**
3. Connect your GitHub repo (`kopigrade_backend`)
4. Render detects `render.yaml` automatically — click **Apply**

- [ ] **Step 3: Set secret environment variables**

In the Render dashboard, navigate to the `kopigrade-backend` web service → **Environment**:

| Key | Value |
|---|---|
| `RAILS_MASTER_KEY` | Contents of your local `config/master.key` |
| `GOOGLE_API_KEY` | Your Gemini API key |

Click **Save Changes** — this triggers a redeploy.

- [ ] **Step 4: Verify the deploy succeeds**

In Render dashboard → `kopigrade-backend` → **Logs**, watch for:

```
=> Booting Puma
=> Rails 8.1.x application starting in production
=> Run `bin/rails server --help` for more startup options
Puma starting...
```

If you see migration errors, check that `DATABASE_URL` is linked correctly (web service → Environment → should show `DATABASE_URL` from database).

- [ ] **Step 5: Hit the health check endpoint**

```bash
curl https://<your-render-slug>.onrender.com/up
```

Expected: HTTP 200 with body `OK` (or similar Rails health response).
