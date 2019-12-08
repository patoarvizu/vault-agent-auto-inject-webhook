FROM golang:1.12 as builder

ARG GIT_COMMIT="unspecified"
LABEL GIT_COMMIT=$GIT_COMMIT

ARG GIT_TAG=""
LABEL GIT_TAG=$GIT_TAG

ARG COMMIT_TIMESTAMP="unspecified"
LABEL COMMIT_TIMESTAMP=$COMMIT_TIMESTAMP

ARG AUTHOR_EMAIL="unspecified"
LABEL AUTHOR_EMAIL=$AUTHOR_EMAIL

ARG SIGNATURE_KEY="undefined"
LABEL SIGNATURE_KEY=$SIGNATURE_KEY

COPY . /go/src/github.com/patoarvizu/vault-agent-auto-inject-webhook/

WORKDIR /go/src/github.com/patoarvizu/vault-agent-auto-inject-webhook/

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /vault-agent-auto-inject-webhook /go/src/github.com/patoarvizu/vault-agent-auto-inject-webhook/cmd/webhook.go

FROM alpine:3.9

RUN apk update && apk add ca-certificates

COPY --from=builder /vault-agent-auto-inject-webhook /

CMD /vault-agent-auto-inject-webhook