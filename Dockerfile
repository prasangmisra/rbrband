# Multi-stage Dockerfile for rbrband services
FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .

# Build login service
FROM build AS build-login
RUN CGO_ENABLED=0 GOOS=linux go build -o /usr/local/bin/login ./cmd/login

# Build gigworker service
FROM build AS build-gigworker
RUN CGO_ENABLED=0 GOOS=linux go build -o /usr/local/bin/gigworker ./cmd/gigworker

# Build migrate service (with build tag)
FROM build AS build-migrate
RUN CGO_ENABLED=0 GOOS=linux go build -tags migration -o /usr/local/bin/migrate ./cmd/migrate

# Runtime stage for login
FROM gcr.io/distroless/base-debian10 AS login
COPY --from=build-login /usr/local/bin/login /usr/local/bin/login
ENTRYPOINT ["/usr/local/bin/login"]

# Runtime stage for gigworker
FROM gcr.io/distroless/base-debian10 AS gigworker
COPY --from=build-gigworker /usr/local/bin/gigworker /usr/local/bin/gigworker
ENTRYPOINT ["/usr/local/bin/gigworker"]

# Runtime stage for migrate
FROM gcr.io/distroless/base-debian10 AS migrate
COPY --from=build-migrate /usr/local/bin/migrate /usr/local/bin/migrate
ENTRYPOINT ["/usr/local/bin/migrate"]

# Default to login service
FROM login
