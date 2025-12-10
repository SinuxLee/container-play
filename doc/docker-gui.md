### 可视化管理
https://www.portainer.io/installation/

```bash
# 运行portaainer
docker run -d \
--name=portainer \
--restart=unless-stopped \
-p 8000:8000 \
-p 9000:9000 \
-v /var/run/docker.sock:/var/run/docker.sock \
-v $PWD/portainer:/data \
portainer/portainer-ce
```