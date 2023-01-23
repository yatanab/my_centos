FROM centos:7
ENV container docker

# --- systemd 有効化 ---
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
  systemd-tmpfiles-setup.service ] || rm -f $i; done); \
  rm -f /lib/systemd/system/multi-user.target.wants/*;\
  rm -f /etc/systemd/system/*.wants/*;\
  rm -f /lib/systemd/system/local-fs.target.wants/*; \
  rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
  rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
  rm -f /lib/systemd/system/basic.target.wants/*;\
  rm -f /lib/systemd/system/anaconda.target.wants/*;

# --- httpd install ---
RUN yum install -y httpd;

# --- jdk 17 ---
RUN cd /opt; \
  curl -OL https://download.java.net/java/GA/jdk17.0.1/2a2082e5a09d4267845be086888add4f/12/GPL/openjdk-17.0.1_linux-x64_bin.tar.gz; \
  tar xvzf ./openjdk-17.0.1_linux-x64_bin.tar.gz; \
  rm -f openjdk-17.0.1_linux-x64_bin.tar.gz; \
  alternatives --install /usr/bin/java java /opt/jdk-17.0.1//bin/java 1

# --- tomcat 10 ---
RUN cd /opt; \
  curl -OL https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.5/bin/apache-tomcat-10.1.5.tar.gz; \
  tar xvzf apache-tomcat-10.1.5.tar.gz; \
  rm -f apache-tomcat-10.1.5.tar.gz

COPY pages /var/www/html
COPY tomcat.service /etc/systemd/system

EXPOSE 80 8080
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]