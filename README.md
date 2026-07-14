# rbrband

Go monorepo for musicians. Manage bands, gigs, ratings, users.

## Setup

**Prereq**: Go 1.26+, Docker, Atlas (`brew install ariga/cli/atlas`)

```bash
make up                 # Start all services
make logs               # View logs
make migration.apply    # Apply migrations
make db.shell          # Connect to postgres
make down              # Stop all
```

Services: **login** (8080), **gigworker** (8081), **postgres** (5432)

### Health & Readiness

```bash
# Login service
curl http://localhost:8080/health       # Returns 200 if running
curl http://localhost:8080/ready        # Returns 200 if DB connected

# Gigworker service
curl http://localhost:8081/health       # Returns 200 if running
curl http://localhost:8081/ready        # Returns 200 if DB connected
```

## Development

```bash
make build             # Build all binaries
make fmt               # Format code
make test              # Run tests
make help              # All targets
```

## Database

```bash
make db.start          # Start postgres only
make db.stop           # Stop
make db.reset          # Reset data
make db.logs           # View logs
make migration.status  # Check migrations
```

## Migrations

Edit GORM models in `internal/db/entity/`, register in `entity.go`, then:

```bash
make migration.gen desc="your_change"     # Generate from models (no DB needed)
make migration.apply                       # Apply to database
make migration.status                      # Check status
```

## Local Dev (without Docker)

```bash
make db.start
make build
make migration.apply

# Terminal 1
export DATABASE_URL="postgres://admin:rbrband123@localhost:5432/rbrband?sslmode=disable"
./bin/login

# Terminal 2
export DATABASE_URL="postgres://admin:rbrband123@localhost:5432/rbrband?sslmode=disable"
./bin/gigworker
```

## Entities

- **User**: Email, password, ratings
- **Band**: Name, owner, members
- **BandMembership**: User-band link
- **Gig**: Event, ratings, aggregates
- **Rating**: 1-5 score

## Architecture

```
cmd/          - Services (login, gigworker, migrate)
internal/
  ├── db/
  │   ├── entity/     - GORM models
  │   └── repository/ - Data access
  └── service/        - App init
migrations/   - SQL (auto-generated)
```

## Env

Create `.env` from `.env.example`:

```env
DB_USER=admin
DB_PASSWORD=rbrband123
DB_NAME=rbrband
DB_HOST=postgres
DB_PORT=5432
TIMEOUT_SEC=5
```
