MAKEFLAGS    += --always-make --warn-undefined-variables
SHELL        := /usr/bin/env bash
.SHELLFLAGS  := -e -o pipefail -c
.NOTPARALLEL :

PROJECT_ROOT ?= $(shell git rev-parse --show-toplevel)
PROJECT_NAME ?= rbrband

.PHONY: all fmt lint test generate build clean mod update help db.start db.stop db.reset db.logs db.shell up down logs

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
	@if [ ! -f .env ]; then cp .env.example .env; echo "✓ Created .env from .env.example"; fi
	@echo "Starting PostgreSQL via docker-compose..."
	docker compose up -d postgres
	@echo "Waiting for PostgreSQL to be ready..."
	@sleep 5
	@echo "✓ PostgreSQL started on localhost:5432"

db.stop: ## Stop PostgreSQL development database
	docker compose down 2>/dev/null || true
	@echo "✓ PostgreSQL stopped"

db.reset: ## Reset PostgreSQL development database (deletes all data)
	docker compose down -v 2>/dev/null || true
	docker compose up -d postgres
	@echo "Waiting for PostgreSQL..."
	@sleep 5
	@echo "✓ PostgreSQL reset and running"

db.logs: ## Show PostgreSQL logs
	docker compose logs -f postgres

db.shell: ## Connect to PostgreSQL shell
	docker compose exec postgres psql -U ${DB_USER:-admin} -d ${DB_NAME:-rbrband}

up: ## Build and start all services (postgres, login, gigworker, migrate) in Docker
	@if ! docker info > /dev/null 2>&1; then \
		echo "❌ Docker is not running. Please start Docker Desktop and try again."; \
		echo "   Open: /Applications/Docker.app"; \
		exit 1; \
	fi
	@if [ ! -f .env ]; then cp .env.example .env; echo "✓ Created .env from .env.example"; fi
	@echo "🚀 Building and starting all services..."
	docker compose up -d --build
	@echo ""
	@echo "✓ Services started successfully!"
	@echo ""
	@echo "📊 Service URLs:"
	@echo "  • Login Service:     http://localhost:8080"
	@echo "  • Gigworker Service: http://localhost:8081"
	@echo "  • PostgreSQL:        localhost:5432 (admin/rbrband123)"
	@echo ""
	@echo "📋 Useful commands:"
	@echo "  • View logs:         make logs"
	@echo "  • Stop services:     make down"
	@echo "  • Apply migrations:  make migration.apply"
	@echo "  • DB shell:          make db.shell"
	@echo ""
	@docker compose ps

down: ## Stop all services
	docker compose down
	@echo "✓ All services stopped"

logs: ## View all service logs
	docker compose logs -f

# Include migration Makefile
-include .makefiles/Makefile.migration
