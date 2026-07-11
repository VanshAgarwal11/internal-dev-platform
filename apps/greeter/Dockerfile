# ---- Build stage ----
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY src/go.mod ./
COPY src/main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o greeter main.go

# ---- Final stage ----
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/greeter /greeter
EXPOSE 8080
ENTRYPOINT ["/greeter"]
