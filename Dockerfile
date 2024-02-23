FROM ubuntu:20.04

RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    wget \
    openssh-server

RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz -P ~/Downloads \
    && tar zxvf ~/Downloads/hadoop-3.3.6.tar.gz  -C /usr/local \
    && mv /usr/local/hadoop-* /usr/local/hadoop \
    && mkdir /var/hadoop

ENV  JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/jre/
ENV  PATH $PATH:$JAVA_HOME/bin
ENV  HADOOP_HOME /usr/local/hadoop
ENV  PATH $PATH:$HADOOP_HOME/bin
ENV  HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop

RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

COPY conf/* /tmp/

RUN mv /tmp/ssh_config ~/.ssh/config \
    && mv /tmp/core-site.xml /usr/local/hadoop/etc/hadoop/core-site.xml \
    && mv /tmp/mapred-site.xml /usr/local/hadoop/etc/hadoop/mapred-site.xml \
    && mv /tmp/hdfs-site.xml /usr/local/hadoop/etc/hadoop/hdfs-site.xml \
    && mv /tmp/yarn-site.xml /usr/local/hadoop/etc/hadoop/yarn-site.xml \
    && mv /tmp/workers /usr/local/hadoop/etc/hadoop/workers \
    && /tmp/env.sh

CMD [ "sh", "-c", "service ssh start; bash"]
