
### 配置超级管理员账号密码
```bash
docker exec -t svn htpasswd -b /etc/subversion/passwd libz libz
```

### 验证登录
http://localhost/svn/
		http://localhost/svnadmin

### 修改权限文件

```ini
# PWD/svn/config/subversion-access-contro
[groups]

[/]

* = r
```

### 配置后台参数

```shell
/etc/subversion/subversion-access-contro
/etc/subversion/passwd
/home/svn
/usr/bin/svn
/usr/bin/svnadmin
```
