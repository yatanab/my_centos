
```sh
$ docker pull httpd:2.4.55-alpine

$ docker run --rm httpd:alpine cat /usr/local/apache2/conf/httpd.conf > httpd.conf

$ docker pull tomcat:10.1.5-jre17-temurin

$ docker run --rm tomcat:10.1.5-jre17-temurin cat /usr/local/tomcat/conf/server.xml > server.xml
```