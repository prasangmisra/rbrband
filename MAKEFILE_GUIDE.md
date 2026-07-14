# Make Commands Guide for rbrband

## Overview

The project uses a professional Makefile structure with modular targets organized in the `.makefiles/` directory. The main `Makefile` includes migration-specific targets from `.makefiles/Makefile.migration`.

## Quick Reference

### Display All Available Commands
```bash
make help
```

Output:
```
all                            Run format and tests
build                          Build all binaries
clean                          Clean build artifacts
fmt                            Run Go code formatter
generate                       Run go generate
help                           Display this help screen
lint                           Run linters (requires golangci-lint)
migration                      Generate a new migration from the entities
mod                            Run go mod tidy
test                           Run all tests
update                         Update all Go dependencies
```

## Core Build Commands

### Build All Binaries
```bash
make build
```

Builds three binaries into `bin/`:
- `bin/login` - Login service
- `bin/gigworker` - Gig post-processing worker
- `bin/migrate` - Atlas migration runner (with migration build tag)

### Format Code
```bash
make fmt
```

Runs `gofmt` recursively to format all Go code in the repository.

### Lint Code
```bash
make lint
```

Runs `golangci-lint` to check for code quality issues. Requires `golangci-lint` to be installed:
```bash
brew install golangci-lint
```

### Run Tests
```bash
make test
```

Runs all tests with verbose output: `go test ./... -v`

### Clean Build Artifacts
```bash
make clean
```

Removes:
- Go build cache: `go clean`
- Binary directory: `rm -rf bin/`

## Dependency Management

### Update Dependencies
```bash
make update
```

Updates all Go dependencies to the latest versions:
- `go get -u ./...` - Update all packages
- `go mod tidy` - Clean up go.mod and go.sum

### Tidy Module Files
```bash
make mod
```

Runs `go mod tidy` to ensure `go.mod` and `go.sum` are consistent.

## Database Migrations (Atlas)

### Generate Migration from Models
```bash
make migration desc="create_users_table"
```

Or without the `desc` argument (interactive):
```bash
make migration
# Then enter the migration description when prompted
```

This command:
1. Takes your description (e.g., "create_users_table")
2. Converts it to snake_case (lowercases and replaces spaces with underscores)
3. Runs: `atlas migrate diff --env local <description>`
4. Generates a new SQL migration file in `migrations/`

**Example:**
```bash
$ make migration desc="Add LastLoginAt to Users"
# Generates: migrations/20260713_add_last_login_at_to_users.sql
```

### Create Empty Migration
```bash
make migration.new desc="custom_migration"
```

Creates an empty migration file without comparing against the database. Useful for custom SQL.

### Apply Migrations to Database
```bash
make migration.apply
```

Applies all pending migrations:
```bash
atlas migrate apply --env local
```

**Requires:**
- PostgreSQL running
- `DATABASE_URL` environment variable set
- Example: `export DATABASE_URL="postgres://user:pass@localhost:5432/rbrband?sslmode=disable"`

### Check Migration Status
```bash
make migration.status
```

Shows which migrations are applied and which are pending.

### Recreate Latest Migration
```bash
make migration.recreate desc="new_description"
```

Deletes the latest migration file and generates a new one with the specified description. Useful for fixing mistakes before applying migrations.

### Rollback Latest Migration
```bash
make migration.rollback
```

**⚠️ Caution: This is destructive!**

Rolls back the latest applied migration from the database. Prompts for confirmation before proceeding.

## Composite Commands

### Run All Checks (Recommended Before Commit)
```bash
make all
```

Runs:
1. `make fmt` - Format code
2. `make test` - Run all tests

## Code Generation

### Generate Code (Go Generate)
```bash
make generate
```

Runs `go generate ./...` to generate any code marked with `//go:generate` directives.

## Development Workflow Example

### Making a Schema Change

1. **Update your GORM model:**
   ```go
   // internal/db/entity/user.go
   type User struct {
       // ... existing fields ...
       LastLoginAt *time.Time `gorm:"index"`
   }
   ```

2. **Register the model in entities.go** (if new):
   ```go
   var AllEntities = []interface{}{
       &User{},
       // ... other models ...
   }
   ```

3. **Generate migration:**
   ```bash
   make migration desc="add_last_login_at_to_users"
   ```

4. **Review the generated SQL:**
   ```bash
   cat migrations/20260713_add_last_login_at_to_users.sql
   ```

5. **Apply the migration:**
   ```bash
   export DATABASE_URL="postgres://user:pass@localhost:5432/rbrband?sslmode=disable"
   make migration.apply
   ```

6. **Format and test:**
   ```bash
   make all
   ```

7. **Build and verify:**
   ```bash
   make build
   ./bin/login   # Test login service
   ./bin/gigworker  # Test gig worker
   ```

## Environment Variables

Key variables used by make commands:

```bash
# Required for database migrations
export DATABASE_URL="postgres://user:password@localhost:5432/rbrband?sslmode=disable"

# Optional: Connection timeout (default: 5 seconds)
export TIMEOUT_SEC=10
```

## File Structure

```
Makefile                       - Main Makefile with core targets
.makefiles/
  ├── Makefile.help           - Help display utility
  └── Makefile.migration      - Atlas migration targets
```

## Troubleshooting

### "No rule to make target `migration`"
Ensure `.makefiles/Makefile.migration` exists and is not empty.

### Migration fails with "database connection error"
Check that PostgreSQL is running and `DATABASE_URL` is correct:
```bash
psql "$DATABASE_URL" -c "SELECT 1;"
```

### "golangci-lint: command not found"
Install golangci-lint:
```bash
brew install golangci-lint
```

### Build produces empty bin/ directory
Ensure Go is 1.26+:
```bash
go version
```

## Best Practices

1. **Always run `make fmt` before committing:**
   ```bash
   make fmt
   ```

2. **Review generated migrations before applying:**
   ```bash
   cat migrations/*.sql
   make migration.apply  # After review
   ```

3. **Use `make all` to verify before pushing:**
   ```bash
   make all  # Formats and tests
   ```

4. **Keep the `.makefiles/` directory in version control:**
   ```bash
   git add .makefiles/
   ```

5. **Never manually edit generated migration files** — let Atlas create them.
