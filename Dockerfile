FROM golang:1.12 as builder

COPY . /go/src/github.com/patoarvizu/vault-agent-auto-inject-webhook/

WORKDIR /go/src/github.com/patoarvizu/vault-agent-auto-inject-webhook/

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /vault-agent-auto-inject-webhook /go/src/github.com/patoarvizu/vault-agent-auto-inject-webhook/cmd/webhook.go

FROM alpine:3.9

RUN apk update && apk add ca-certificates

COPY --from=builder /vault-agent-auto-inject-webhook /

CMD /vault-agent-auto-inject-webhook