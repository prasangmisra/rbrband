MAKEFLAGS    += --always-make --warn-undefined-variables
SHELL        := /usr/bin/env bash
.SHELLFLAGS  := -e -o pipefail -c
.NOTPARALLEL :

PROJECT_ROOT ?= $(shell git rev-parse --show-toplevel)
PROJECT_NAME ?= rbrband

.PHONY: all fmt lint test generate build clean mod update help db.start db.stop db.reset db.logs db.shell

all: fmt test ## Run format and tests

fmt: ## Run Go code formatter
	gofmt -s -w .

lint: ## Run linters (requires golangci-lint)
	golangci-lint run ./...

test: ## Run all tests
	go test ./... -v

generate: ## Run go generate
	go generate ./...

build: ## Build all binaries
	mkdir -p bin/
	go build -o bin/login ./cmd/login
	go build -o bin/gigworker ./cmd/gigworker
	go build -tags migration -o bin/migrate ./cmd/migrate

clean: ## Clean build artifacts
	go clean
	rm -rf bin/

mod: ## Run go mod tidy
	go mod tidy

update: ## Update all Go dependencies
	go get -u ./...
	go mod tidy

help: ## Display this help screen
	@grep -h -E '^[a-zA-Z_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort

db.start: ## Start PostgreSQL development database via Docker Compose
	@if ! docker info > /dev/null 2>&1; then \
		echo "❌ Docker is not running. Please start Docker Desktop and try again."; \
		echo "   Open: /Applications/Docker.app"; \
		exit 1; \
	fi
	@echo "Starting PostgreSQL via docker-compose..."
	docker compose -f docker-compose.dev.yml up -d
	@echo "Waiting for PostgreSQL to be ready..."
	@sleep 5
	@docker compose -f docker-compose.dev.yml exec postgres pg_isready -U postgres || sleep 5
	@echo "Setting up admin user and database..."
	@docker compose -f docker-compose.dev.yml exec postgres psql -U postgres -tc "SELECT 1 FROM pg_user WHERE usename = 'admin'" | grep -q 1 || \
		docker compose -f docker-compose.dev.yml exec postgres psql -U postgres -c "CREATE USER admin WITH PASSWORD 'rbrband123' CREATEDB SUPERUSER;" || true
	@docker compose -f docker-compose.dev.yml exec postgres psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'rbrband'" | grep -q 1 || \
		docker compose -f docker-compose.dev.yml exec postgres psql -U postgres -c "CREATE DATABASE rbrband OWNER admin;" || true
	@docker compose -f docker-compose.dev.yml exec postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE rbrband TO admin;" || true
	@echo "✓ PostgreSQL started on localhost:5432"
	@echo "✓ Admin user configured (admin/rbrband123)"
	@echo "✓ Database created (rbrband)"

db.stop: ## Stop PostgreSQL development database
	docker compose -f docker-compose.dev.yml down 2>/dev/null || true
	@echo "✓ PostgreSQL stopped"

db.reset: ## Reset PostgreSQL development database (deletes all data)
	docker compose -f docker-compose.dev.yml down -v 2>/dev/null || true
	docker compose -f docker-compose.dev.yml up -d
	@echo "Waiting for PostgreSQL..."
	@sleep 5
	@echo "✓ PostgreSQL reset and running"

db.logs: ## Show PostgreSQL logs
	docker compose -f docker-compose.dev.yml logs -f postgres

db.shell: ## Connect to PostgreSQL shell
	docker compose -f docker-compose.dev.yml exec postgres psql -U admin -d rbrband

# Include migration Makefile
-include .makefiles/Makefile.migration
