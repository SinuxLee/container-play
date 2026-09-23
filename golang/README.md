
这两个 Dockerfile 是供其他 Go 项目复制改造的模板；当前仓库不含对应的 `go.mod`、源码、`linux_build.sh` 等文件，不能直接在此目录构建。

### 构建（在具备源码的目标项目中）
```bash
docker build -t sinux/tms:v0.0.1 -f ./Dockerfile .
```

### 运行
```bash
docker run -d -p 127.0.0.1:8086:8086 sinux/tms:v0.0.1
```
