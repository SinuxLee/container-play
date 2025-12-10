FROM golang:1.24 AS build

# set building environment variables
ENV GO111MODULE=on \
    GOPROXY=https://goproxy.cn,direct \
    GOPRIVATE=gitlab.dd.io \
    GONOPROXY=gitlab.dd.io \
    CGO_ENABLED=0

# add Gitlab SSH known_hosts
RUN mkdir -p -m 0700 ~/.ssh && \
    ssh-keyscan gitlab.dd.io >> ~/.ssh/known_hosts

# rediect git
RUN git config --global url."git@gitlab.dd.io:".insteadOf "https://gitlab.dd.io/"

# install dependency and cache
WORKDIR /go/cache
COPY go.mod go.sum ./
RUN --mount=type=ssh go mod download

# build code
WORKDIR /go/release
ADD . .
RUN chmod +x *.sh && ./linux_build.sh

# build release image
FROM alpine:3.22 AS release
RUN apk add --no-cache tzdata

WORKDIR /ffgo
COPY --from=build /go/release/entrypoint.sh ./
COPY --from=build /tmp/deploy/ffgo/* ./
RUN mkdir -p -m 0777 /ffgo/tga_log

RUN ln -s /ffgo/ffb /ffgo/asset && \
    ln -s /ffgo/ffb /ffgo/center && \
    ln -s /ffgo/ffb /ffgo/game && \
    ln -s /ffgo/ffb /ffgo/dashboard && \
    ln -s /ffgo/ffb /ffgo/gateway && \
    ln -s /ffgo/ffb /ffgo/social && \
    ln -s /ffgo/ffb /ffgo/ranking && \
    adduser -D -u 10001 ffgo

USER ffgo
EXPOSE 80 8000 8010 8020 8030 8040 8050 9010

# must use entrypoint as startup program
ENTRYPOINT ["sh","/ffgo/entrypoint.sh"] 
