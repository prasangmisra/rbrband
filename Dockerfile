# Dockerfile for rbrband services
FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /usr/local/bin/service ./cmd/login

FROM gcr.io/distroless/base-debian10
COPY --from=build /usr/local/bin/service /usr/local/bin/service
ENTRYPOINT ["/usr/local/bin/service"]
