## httpd と tomcatの連携
### httpdとは
webサーバ
http通信でhtmlファイルなどを閲覧できるのはこれのおかげ

### tomcat
webコンテナ(サーブレットコンテナ、サーブレットエンジン)
webサーバの機能も含まれるが、httpdには劣る。
javaのwebサービスを公開するのが一般的な仕事

### なぜ連携するのか
tomcatはwebサーバの機能も 含まれているが、安定しない(らしい)ので、webサーバの機能をhttpdに任せて必要に応じてtomcatにリクエストを渡す。

## まずはcentosへのtomcatをinstall

jdk install

```sh
[container]$ curl -OL https://download.java.net/java/GA/jdk17.0.1/2a2082e5a09d4267845be086888add4f/12/GPL/openjdk-17.0.1_linux-x64_bin.tar.gz
[container]$ tar xvfz openjdk-17.0.1_linux-x64_bin.tar.gz
[container]$ rm -f openjdk-17.0.1_linux-x64_bin.tar.gz
[container]$ mv jdk-17.0.1/ /opt/jdk-17.0.1/
[container]$ alternatives --install /usr/bin/java java /opt/jdk-17.0.1//bin/java 1
[container]$ java -version
openjdk version "17.0.1" 2021-10-19
OpenJDK Runtime Environment (build 17.0.1+12-39)
OpenJDK 64-Bit Server VM (build 17.0.1+12-39, mixed mode, sharing)
```
tomcat install version 10.1.x

```sh
[container]$ curl -OL https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.5/bin/apache-tomcat-10.1.5.tar.gz
[container]$ tar xvzf ./apache-tomcat-10.1.5.tar.gz
[container]$ mv apache-tomcat-10.1.5 /opt
[container]$ rm -f apache-tomcat-10.1.5.tar.gz
[container]$ vim /etc/tomcat.service
```
tomcat.serviceを下のように書く
```tomcat.service
[Unit]
Description=Apache Tomcat 10.1
After=network.target

[Service]
Type=oneshot
PIDFile=/opt/apache-tomcat-10.1.5/tomcat.pid
RemainAfterExit=yes

ExecStart=/opt/apache-tomcat-10.1.5/bin/startup.sh
ExecStop=/opt/apache-tomcat-10.1.5/bin/shutdown.sh
ExecReStart=/opt/apache-tomcat-10.1.5/bin/shutdown.sh;/opt/apache-tomcat-10.1.5/bin/startup.sh

[Install]
WantedBy=multi-user.target
```
## tomcatとhttpdの連携

AJP

### tomcatの設定

`{tomcat}/conf/server.xml`を修正する
- `port=8080`をコメントアウト

- AJP/1.3のコメントアウトを外す
  - `address="0.0.0.0"`に書き換える
  - `secretRequired="false"`を加える

```sh
[container]$ vi /opt/apache-tomcat-10.1.5/conf/server.xml
...
<!--
<Connector port="8080" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443" />
-->
<Connector protocol="AJP/1.3"
           address="0.0.0.0"
           port="8009"
           redirectPort="8443"
           secretRequired="false" />
...
```

### httpdの設定

`/etc/httpd/conf.modules.d/00-proxy.conf`を修正する
- `LoadModule proxy_ajp_module modules/mod_proxy_ajp.so`を追加する

```sh
[container]$ vi /etc/httpd/conf.modules.d/00-proxy.conf
...
LoadModule proxy_ajp_module modules/mod_proxy_ajp.so
...
```
`/etc/httpd/conf/httpd.conf`を修正する

```httpd.conf
[container]$ vi /etc/httpd/conf/httpd.conf
...
# ProxyPass
#
# proxy setting to integrate tomcat
ProxyPass /api/ ajp://localhost:8009/
ProxyPassReverse /api/ ajp://localhost:8009/
...
```

## 確認

httpdとtomcatを起動して`http://localhost:80/api`にアクセスしてtomcatの画面が表示されることを確かめる　

```sh
[container]$ systemctl start httpd
[container]$ systemctl start tomcat
```