# rbrband

A professional Go monorepo platform for musicians. Users can manage multiple personas (musician, manager, fan), create/join bands, perform at gigs, and receive ratings from attendees.

## Prerequisites

- Go 1.26+
- PostgreSQL 12+
- Atlas CLI: `brew install ariga/cli/atlas`

## Environment Setup

```bash
export DATABASE_URL="postgres://admin:rbrband123@localhost:5432/rbrband?sslmode=disable"
export TIMEOUT_SEC=5
```

## Database Migrations with Atlas

**⚠️  IMPORTANT: Do NOT manually edit migration files. Atlas generates them automatically from your GORM models.**

### Quick Start (No Database Required)

Generate a migration from your GORM models without needing a running database:

```bash
# Generate initial migration
make migration.gen desc="create_initial_schema"

# Generate additional migrations
make migration.gen desc="add_user_preferences"
```

The migration files are created in `migrations/` with timestamps and the `atlas.sum` file is automatically updated.

### Full Workflow

#### 1. Define or Update GORM Models

Edit models in `internal/db/entity/`:

```go
// internal/db/entity/user.go
type User struct {
    ID        int64     `gorm:"primaryKey;autoIncrement"`
    Email     string    `gorm:"type:text;uniqueIndex"`
    CreatedAt time.Time `gorm:"autoCreateTime"`
}
```

Register all models in `internal/db/entity/entities.go`:

```go
var AllEntities = []interface{}{
    &User{},
    &Band{},
    &Gig{},
}
```

#### 2. Generate Migration (No DB Required)

```bash
# Simple migration generation (uses GORM models, no database needed)
make migration.gen desc="your_migration_name"
```

This generates a SQL migration file with a timestamp-based filename like `20260713225444_your_migration_name.sql`.

#### 3. Start Database & Apply Migrations

Option A: Using Docker Compose

```bash
# Start PostgreSQL
make db.start

# Apply all pending migrations
make migration.apply

# Check migration status
make migration.status
```

Option B: Using Local PostgreSQL

```bash
# Ensure PostgreSQL is running locally on port 5432
# Then apply migrations
atlas migrate apply --env local
```

#### 4. Review Generated Migrations

```bash
# View the generated migration file
cat migrations/20260713225444_your_migration_name.sql
```

### Example: Adding a New Field to User

1. Update the model:
   ```go
   type User struct {
       // ... existing fields ...
       LastLoginAt *time.Time `gorm:"index"`
   }
   ```

2. Generate migration:
   ```bash
   make migration.gen desc="add_last_login_at_to_users"
   ```

3. Review the SQL file and apply when ready:
   ```bash
   make db.start
   make migration.apply
   ```

## Building & Running Services

### Build All Binaries

```bash
make build
```

This builds three binaries into `bin/`:
- `bin/login` - Login/authentication service
- `bin/gigworker` - Post-gig rating aggregation worker
- `bin/migrate` - Atlas migration runner (build-tag: migration)

### Build Individual Services

```bash
go build -o bin/login ./cmd/login
go build -o bin/gigworker ./cmd/gigworker
go build -tags migration -o bin/migrate ./cmd/migrate
```

### Run Login Service

```bash
# Set up environment
export DATABASE_URL="postgres://admin:rbrband123@localhost:5432/rbrband?sslmode=disable"
export TIMEOUT_SEC=5

# Run service
./bin/login
```

### Run Gig Worker

```bash
export DATABASE_URL="postgres://admin:rbrband123@localhost:5432/rbrband?sslmode=disable"
export TIMEOUT_SEC=5

./bin/gigworker
```

## Database Management

```bash
# Start PostgreSQL development database
make db.start

# Check database status
make migration.status

# Connect to PostgreSQL shell
make db.shell

# View database logs
make db.logs

# Stop database
make db.stop

# Reset database (delete all data)
make db.reset
```

## Development

```bash
make fmt          # Format code
make test         # Run tests
make lint         # Lint code
make all          # Format + test
make help         # Show all available make targets
```

### Common Development Workflow

```bash
# 1. Make changes to GORM models in internal/db/entity/
# 2. Generate migration from models
make migration.gen desc="your_change_description"

# 3. Format and test
make fmt
make test

# 4. Review migration file
cat migrations/$(ls migrations/*.sql | tail -1 | grep -o '[0-9_]*' | head -1).sql

# 5. When ready to deploy/test with DB:
make db.start                 # Start PostgreSQL
make migration.apply          # Apply migrations
make db.shell                 # Test with psql
make db.stop                  # Stop when done
```

## Project Structure

```
rbrband/
├── cmd/                       # Service binaries
│   ├── login/                 - Authentication service
│   ├── gigworker/             - Rating aggregation worker
│   └── migrate/               - Atlas migration runner (build-tag: migration)
├── internal/                  # Private application code
│   ├── db/
│   │   ├── entity/            - GORM models (User, Band, Gig, Rating, BandMembership)
│   │   └── repository/        - Data access layer (UserRepository, etc.)
│   └── service/               - Service initialization (App, database connections)
├── migrations/                - Atlas-managed SQL migrations (auto-generated)
├── scripts/                   - Helper scripts (generate-migration.sh)
├── atlas.hcl                  - Atlas configuration
├── docker-compose.dev.yml     - PostgreSQL development environment
├── go.mod, go.sum             - Go dependencies
├── Makefile                   - Build, test, lint, format commands
├── .makefiles/
│   ├── Makefile.migration     - Migration-specific targets
│   └── Makefile.help          - Help target utilities
└── README.md                  - This file
```

## Key Entities

- **User**: Core account with email, ratings
- **Band**: Group with owner, members, ratings
- **BandMembership**: User-to-band relationship
- **Gig**: Performance event with ratings aggregates
- **Rating**: Individual gig rating (1-5 score)

The `cmd/gigworker` service aggregates ratings after gigs end.
