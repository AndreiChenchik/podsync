FROM golang:1.18 as builder
WORKDIR /src/podsync
COPY . .
ARG PODSYNC_VERSION=latest
RUN --mount=type=cache,target=/root/.cache/go-build \
	--mount=type=cache,target=/go/pkg \
	go build \
        -ldflags "-s -w -X 'main.Version=${PODSYNC_VERSION}' -extldflags '-static'" \
        -tags osusergo,netgo,sqlite_omit_load_extension \
        -o /usr/local/bin/podsync ./cmd/podsync

FROM alpine:3.16

RUN wget -O /usr/bin/yt-dlp https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp && \
    chmod +x /usr/bin/yt-dlp && \
    ln -s /usr/bin/yt-dlp /usr/bin/youtube-dl && \
    apk --no-cache add ca-certificates python3 py3-pip ffmpeg tzdata

COPY --from=builder /usr/local/bin/podsync /usr/local/bin/podsync
COPY config.toml /etc/config.toml
ENTRYPOINT ["podsync"]
CMD ["--no-banner", "--config", "/etc/config.toml"]
