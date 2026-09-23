最小工作流你需要做的几步：

1. 进 Gitea http://localhost:3000 初始化，建 repo（放 Jenkinsfile）。
2. 进 Jenkins http://localhost:8080 初始化，装插件：
- Gitea（或 Generic Webhook Trigger）
- Pipeline、Git、Credentials
3. 在 Jenkins 建 Multibranch Pipeline 或 Pipeline job，配置仓库地址（http://gitea:3000/... 走内网）。
4. 在 Gitea 配 webhook 指向 Jenkins：http://jenkins:8080/...（容器内网络可通；如果你从浏览器配，注意 URL 用 jenkins 还是 localhost，取决于 webhook 发起方在谁的网络里）。

Web 和 SSH 端口默认只绑定本机，可通过 `HOST_BIND_ADDRESS` 覆盖宿主机监听地址。远程访问时还需设置 `GITEA_ROOT_URL`。
Jenkins 默认不挂载宿主机 Docker socket；需要构建镜像时请配置专用构建代理。
