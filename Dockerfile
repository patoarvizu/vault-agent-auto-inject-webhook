FROM golang:1.16 as builder
ARG TARGETARCH
ARG TARGETVARIANT

COPY . /go/src/github.com/patoarvizu/vault-agent-auto-inject-webhook/

WORKDIR /go/src/github.com/patoarvizu/vault-agent-auto-inject-webhook/

RUN CGO_ENABLED=0 GOOS=linux GOARM=$(if [ "$TARGETVARIANT" = "v7" ]; then echo "7"; fi) GOARCH=$TARGETARCH go build -o /vault-agent-auto-inject-webhook /go/src/github.com/patoarvizu/vault-agent-auto-inject-webhook/cmd/webhook.go

FROM gcr.io/distroless/static:nonroot-amd64

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

COPY --from=builder /vault-agent-auto-inject-webhook /

CMD /vault-agent-auto-inject-webhook