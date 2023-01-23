## centos imageをビルド

centosコンテナを生成する

```dockerfile
FROM centos:centos7.9.2009
```

```sh
[host]$ docker build -t mycentos .
[host]$ docker run --rm -dit -t --name mycentos_cont mycentos
```

## centosコンテナでhttpdサーバを起動する

`docker exec -it`でコンテナを操作する

`docker attach`でコンテナにアクセスすると、`exit`で抜けた時にコンテナも終了してしまう。(メインプロセスにアクセスしいるから)

```sh
[host]$ docker exec -it mycentos_cont /bin/bash

--- 以下コンテナ内 ---
[container]$ yum -y update
[container]$ yum -y install httpd
[container]$ httpd -v
Server version: Apache/2.4.6 (CentOS)
Server built:   Mar 24 2022 14:57:57
[container]$ systemctl start httpd
Failed to get D-Bus connection: Operation not permitted
```

> Failed to get D-Bus connection: Operation not permitted
失敗しました 
centosのdocker imageではsystemdが無効にされている。
有効化するためにdockerfileと起動方法を修正します。(公式より)
ついでにイメージbuild時にhttpdをinstallさせます。

```dockerfile
FROM centos:7
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
  systemd-tmpfiles-setup.service ] || rm -f $i; done); \
  rm -f /lib/systemd/system/multi-user.target.wants/*;\
  rm -f /etc/systemd/system/*.wants/*;\
  rm -f /lib/systemd/system/local-fs.target.wants/*; \
  rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
  rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
  rm -f /lib/systemd/system/basic.target.wants/*;\
  rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN yum update -y; \
  yum install -y httpd

VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]
```
docker buildしてコンテナ生成
`--rm`によってコンテナ終了時に自動的にコンテナがクリーンナップされる
`--privileged`によってDockerはホスト上の全てのデバイスに対して接続可能になります。


```sh
[host]$ docker build -t mycentos_httpd .
[host]$ docker run --rm --privileged -dit -t --name mycentos_cont mycentos_sys_httpd
[host]$ docker exec -it mycentos_cont /bin/bash
[container]$ systemctl start httpd
[container]$  systemctl status httpd
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; disabled; vendor preset: disabled)
   Active: active (running) since Sat 2023-01-21 08:10:31 UTC; 5s ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 176 (httpd)
   Status: "Processing requests..."
   CGroup: /docker/c9d511802aa279da38e7047bc076832f273641f0f4e0f95e819ec793f8a11513/system.slice/httpd.service
           ├─176 /usr/sbin/httpd -DFOREGROUND
           ├─177 /usr/sbin/httpd -DFOREGROUND
           ├─178 /usr/sbin/httpd -DFOREGROUND
           ├─179 /usr/sbin/httpd -DFOREGROUND
           ├─180 /usr/sbin/httpd -DFOREGROUND
           └─181 /usr/sbin/httpd -DFOREGROUND

Jan 21 08:10:31 c9d511802aa2 systemd[1]: Starting The Apache HTTP Server...
Jan 21 08:10:31 c9d511802aa2 httpd[176]: AH00558: httpd: Could not reliably determine...ge
Jan 21 08:10:31 c9d511802aa2 systemd[1]: Started The Apache HTTP Server.
Hint: Some lines were ellipsized, use -l to show in full.
```
httpdが起動できました

## containerのhttpdサーバーへホストから接続する

pagesフォルダを作成し、htmlファイルを配置する

```dockerfile
--- 省略 ---
RUN yum update -y; \
  yum install -y httpd

COPY pages /var/www/html

EXPOSE 80
--- 省略 ---
```

```sh
[host]$ docker build -t mycentos_sys_httpd .
[host]$ docker run --rm --privileged -dit -p 80:80  --name mycentos_cont mycentos_sys_httpd
[host]$ docker exec -it mycentos_cont /bin/bash
[container]$ systemctl start httpd
```

ブラウザでhttp://localhost:80にアクセス

## 編集後記
centosもうすぐでサポート終了やん