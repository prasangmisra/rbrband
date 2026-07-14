# Migration Guide

This guide explains how to manage database migrations in rbrband using Atlas and GORM.

## Overview

- **GORM Models**: Defined in `internal/db/entity/` - these are the source of truth
- **Atlas**: Automatically generates SQL migrations from GORM models
- **Migrations**: Stored in `migrations/` with timestamps for version control
- **No Database Required for Generation**: Create migrations without a running database

## Quick Start

### Generate Your First Migration

```bash
# Build the project
make build

# Generate migration from GORM models
make migration.gen desc="create_initial_schema"
```

This creates `migrations/20260713225444_create_initial_schema.sql` with all table definitions.

## Detailed Workflow

### Step 1: Update GORM Models

Edit models in `internal/db/entity/`:

```go
// internal/db/entity/user.go
package entity

import "time"

type User struct {
	ID           int64     `gorm:"primaryKey;autoIncrement"`
	Email        string    `gorm:"uniqueIndex;type:text"`
	PasswordHash string    `gorm:"type:text"`
	DisplayName  string    `gorm:"type:text"`
	RatingAvg    float32   `gorm:"type:numeric(5,2);default:0"`
	RatingCount  int64     `gorm:"default:0"`
	CreatedAt    time.Time `gorm:"autoCreateTime"`
}

func (User) TableName() string {
	return "users"
}
```

### Step 2: Register Models

Update `internal/db/entity/entities.go` to include all models:

```go
package entity

var AllEntities = []interface{}{
	&User{},
	&Band{},
	&Gig{},
	&Rating{},
	&BandMembership{},
}
```

### Step 3: Generate Migration SQL

**Option A: No Database Required (Recommended for Development)**

```bash
# Simple and fast - uses GORM models directly
make migration.gen desc="add_user_preferences"
```

**Option B: With Database (For schema validation)**

First, start the database:

```bash
make db.start
```

Then generate using Atlas:

```bash
make migration desc="add_user_preferences"
```

This compares your GORM models against the actual database schema.

### Step 4: Review Generated Migration

```bash
# View the generated SQL
cat migrations/20260713225755_add_user_preferences.sql
```

Example output:

```sql
-- Migration: add_user_preferences
-- Generated: 2026-07-14 02:57:55 UTC
CREATE TABLE "users" (
  "id" bigserial,
  "email" text,
  "password_hash" text,
  "display_name" text,
  "rating_avg" numeric(5,2) DEFAULT 0,
  "rating_count" bigint DEFAULT 0,
  "created_at" timestamptz,
  PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "idx_users_email" ON "users" ("email");
```

### Step 5: Apply Migrations to Database

```bash
# Start database if not already running
make db.start

# Apply all pending migrations
make migration.apply

# Verify migrations were applied
make migration.status
```

## Making Model Changes

### Example: Add a Field to User

1. Update the model:

```go
// internal/db/entity/user.go
type User struct {
	// ... existing fields ...
	LastLoginAt *time.Time `gorm:"index"`           // New field
	PreferredGenre string    `gorm:"type:text"`     // New field
}
```

2. Generate a new migration:

```bash
make migration.gen desc="add_login_tracking_to_users"
```

3. This creates a new SQL file with only the new schema.

4. Apply when ready:

```bash
make db.start
make migration.apply
```

## Advanced Operations

### Generate Empty Migration

```bash
make migration.new desc="manual_data_fix"
```

This creates an empty migration file for manual SQL or data fixes.

### Check Migration Status

```bash
make db.start
make migration.status
```

Output:

```
Migration Status:

Gig:
  -- 20260713225444_create_initial_schema (OK)
  -- 20260713225755_add_user_preferences (OK)
```

### Rollback Latest Migration

```bash
make migration.rollback
```

⚠️ **Warning**: This is destructive. Make sure you have backups!

### Delete Latest Migration File

```bash
make migration.recreate desc="fix_typo_in_schema"
```

This deletes the latest migration and generates a new one. Use when you caught an error before applying.

## Database Management

### Start PostgreSQL

```bash
make db.start
```

Starts PostgreSQL via Docker Compose on `localhost:5432`.

### Connect to Database

```bash
make db.shell
```

Opens a `psql` prompt. Now you can run SQL queries:

```sql
-- List tables
\dt

-- Describe a table
\d users

-- View indexes
\di

-- Check constraints
\d+ bands
```

### View Database Logs

```bash
make db.logs
```

### Stop Database

```bash
make db.stop
```

### Reset Database (Delete All Data)

```bash
make db.reset
```

⚠️ **This deletes all data!** Use only for development.

## GORM Model Tags Reference

Common GORM tags used in this project:

| Tag | Example | Description |
|-----|---------|-------------|
| `primaryKey` | `gorm:"primaryKey"` | Mark as primary key |
| `autoIncrement` | `gorm:"autoIncrement"` | Auto-increment ID |
| `uniqueIndex` | `gorm:"uniqueIndex"` | Create unique index |
| `index` | `gorm:"index"` | Create regular index |
| `type` | `gorm:"type:text"` | PostgreSQL type |
| `default` | `gorm:"default:0"` | Default value |
| `autoCreateTime` | `gorm:"autoCreateTime"` | Auto-set created_at |
| `autoUpdateTime` | `gorm:"autoUpdateTime"` | Auto-set updated_at |

## Troubleshooting

### Issue: "Migration file already exists"

If you're generating multiple migrations quickly, filenames might collide. Wait a second between generations or use unique descriptions.

### Issue: Migration generation fails

Check that:

1. GORM models are properly defined in `internal/db/entity/`
2. Models are registered in `internal/db/entity/entities.go`
3. Build is up-to-date: `make build`

### Issue: Docker won't start

```bash
# If Docker Desktop is stuck, use local PostgreSQL instead
# Or restart Docker: killall Docker && open /Applications/Docker.app
```

### Issue: Migration won't apply

```bash
# Check if database is running
make db.logs

# Check migration status
make migration.status

# Verify schema exists
make db.shell
> SELECT * FROM public.schema_migrations;
```

## Best Practices

1. **Descriptive Names**: Use clear migration names: `add_user_preferences` instead of `update_schema`

2. **One Change Per Migration**: Don't combine multiple unrelated changes in one migration

3. **Review Before Applying**: Always review generated SQL before applying to production

4. **Test Migrations**: Apply to development database first, verify data integrity

5. **Version Control**: Commit migrations with your code changes

6. **Document Schema Changes**: Update documentation when adding new tables or significant changes

7. **Keep Models in Sync**: If you manually modify the database, update GORM models to match

## Files and Directories

| Path | Purpose |
|------|---------|
| `internal/db/entity/` | GORM model definitions (source of truth) |
| `internal/db/entity/entities.go` | List of all models for migration generation |
| `migrations/` | SQL migration files (versioned, auto-generated) |
| `migrations/atlas.sum` | Checksum file for migration integrity |
| `atlas.hcl` | Atlas configuration |
| `scripts/generate-migration.sh` | Helper script for migration generation |
| `cmd/migrate/main.go` | Entry point for schema loading with build tag `migration` |

## Configuration

### atlas.hcl

The main Atlas configuration file:

```hcl
data "external_schema" "gorm" {
  program = [
    "go",
    "run",
    "-tags", "migration",
    "./cmd/migrate",
  ]
}

env "local" {
  src = data.external_schema.gorm.url
  url = "postgres://postgres:postgres@localhost/rbrband_dev?sslmode=disable"
  migration {
    dir = "file://migrations"
  }
}
```

- `data.external_schema.gorm`: Loads schema from GORM models via `cmd/migrate`
- `env "local"`: Development environment configuration
- `src`: Source schema (from GORM models)
- `url`: Target database URL
- `migration.dir`: Where to store migrations

## See Also

- [Atlas Documentation](https://atlasgo.io/)
- [GORM Documentation](https://gorm.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
