### 安装

##### 系统版本 CentOS/Rocky
```bash
yum update -y

# 基础包
yum install centos-release-scl centos-release-scl-rh scl-utils scl-utils-build -y

# 扩展包
yum install -y epel-release epel-rpm-macros bash-completion

# 关闭防火墙
systemctl stop firewalld

# docker 会接管 iptables 做网络映射
yum install -y iptables iptables-services
systemctl enable iptables
systemctl start iptables

# 获取安装脚本
curl -fsSL https://get.docker.com/ -o /tmp/get-docker.sh

# 安装docker
sudo sh /tmp/get-docker.sh

# 设置开机启动
systemctl enable docker --now

# 启动服务
systemctl start docker

# 查看状态
docker info

# 创建 docker 容器数据存储目录
mkdir -p /mnt/docker/{consul,mongo,mysql,redis}
```

### dockerd 后台进程:
启动参数
```bash
-d # 后台运行
--dns=[] # 设置容器使用DNS服务器
-g # 设置Docker运行时根目录
--exec-driver="native" # 设置容器使用指定的运行时驱动
-H # 设置后台模式下指定socket绑定 //docker -H tcp://0.0.0.0:2375
--ip="0.0.0.0" # 设置容器绑定IP时使用的默认IP地址
--ip-forward=true # 设置启动容器的 net.ipv4.ip_forward ；也可以开启整个系统的转发 sysctl -w net.ipv4.ip_forward=1
```

### 日志
```bash
# 显示最后 20 条日志，并 watch 后续输出
docker logs -f --tail 20 mongo
```

### 资源限制
```bash
#### 限制已启动的容器的内存大小
# 已经运行的容器
docker stop containerId
docker update containerId -m 2g  --memory-swap -1
docker start containerId

# 动态更新容器参数
docker update --restart=always

##### 清理 docker 占用 资源
# 清理镜像
docker image prune -a -f
# 清理终止的容器
docker container prune -f
# 清理存储卷
docker volume prune -f
# 清理所有(适合定期运行)，包含存储卷、镜像和终止的容器
docker system prune -a --volumes -f
```

### 网络环境
Docker容器运行的时候有 host、bridge、none 三种网络可供配置。
- bridge(默认)，以桥接模式连接到宿主机。容器可以访问宿主机的网络端口，但不能访问宿主机所在局域网的其它宿主机
- host 宿主网络，即与宿主机共用网络。 可以让宿主机局域网内的其它宿主机和 docke 容器互通。在容器中访问宿主机网络，那么容器的localhost就是宿主机的localhost
- none 无网络，容器将无法联网。

在docker中使用 --network host 来为容器配置 host 网络：
```bash
# 没必要使用-p 80:80 -p 443:443来映射端口
# 因为容器本身与宿主机共用了网络，容器中暴露端口等同于宿主机暴露端口
docker run -d --name nginx --network host nginx
```
