FROM golang:1.22.0 as build

# set environment variables
ENV GOPROXY https://goproxy.cn,direct
ENV GO111MODULE on

# install dependency
WORKDIR /go/cache
ADD go.mod .
ADD go.sum .
RUN go mod download

# build code
WORKDIR /go/release
ADD . .
RUN GOOS=linux CGO_ENABLED=0 go build -ldflags="-s -w" -installsuffix cgo -o tms cmd/tms/main.go

# 使用空镜像打包，减小空间占用; alpine也挺小的; busybox:glibc含有基础库
FROM scratch as prod

WORKDIR /opt/game/tms

COPY --from=build /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY --from=build /go/release/tms ./bin/
COPY --from=build /go/release/configs ./configs
COPY --from=build /go/release/scripts/control.sh ./

EXPOSE 8086
ENTRYPOINT ["/opt/game/tms/bin/tms","web","-c", "./configs/config.toml", "-m", "./configs/model.conf","--menu", "./configs/menu.yaml"]
