FROM ubuntu:20.04

# 防止安装过程中的交互提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要的软件包
RUN apt-get update && apt-get install -y \
    sudo \
    openssh-server \
    vim \
    net-tools \
    iputils-ping \
    python3 \
    rsync \
    && apt-get clean

# 创建hadoop用户并授予sudo权限
RUN useradd -m -s /bin/bash hadoop && \
    echo "hadoop:hadoop" | chpasswd && \
    adduser hadoop sudo && \
    echo "hadoop ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 设置环境变量（作为root用户）
RUN echo '# JAVA_HOME' >> /etc/profile && \
    echo 'export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_201' >> /etc/profile && \
    echo 'export JRE_HOME=${JAVA_HOME}/jre' >> /etc/profile && \
    echo 'export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib' >> /etc/profile && \
    echo 'export PATH=${JAVA_HOME}/bin:$PATH' >> /etc/profile && \
    echo '# HADOOP_HOME' >> /etc/profile && \
    echo 'export HADOOP_HOME=/usr/local/hadoop' >> /etc/profile && \
    echo 'export PATH=$PATH:${HADOOP_HOME}/bin' >> /etc/profile && \
    echo 'export PATH=$PATH:${HADOOP_HOME}/sbin' >> /etc/profile && \
    echo '# HBASE_HOME' >> /etc/profile && \
    echo 'export HBASE_HOME=/usr/local/hbase' >> /etc/profile && \
    echo 'export PATH=$PATH:${HBASE_HOME}/bin' >> /etc/profile

# 创建必要的目录
RUN mkdir -p /usr/lib/jvm

# 切换到hadoop用户
USER hadoop
WORKDIR /home/hadoop

# 配置SSH免密登录
RUN mkdir -p ~/.ssh && \
    ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys

# 将环境变量添加到 .bashrc
RUN echo '# JAVA_HOME' >> ~/.bashrc && \
    echo 'export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_201' >> ~/.bashrc && \
    echo 'export JRE_HOME=${JAVA_HOME}/jre' >> ~/.bashrc && \
    echo 'export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib' >> ~/.bashrc && \
    echo 'export PATH=${JAVA_HOME}/bin:$PATH' >> ~/.bashrc && \
    echo '# HADOOP_HOME' >> ~/.bashrc && \
    echo 'export HADOOP_HOME=/usr/local/hadoop' >> ~/.bashrc && \
    echo 'export PATH=$PATH:${HADOOP_HOME}/bin' >> ~/.bashrc && \
    echo 'export PATH=$PATH:${HADOOP_HOME}/sbin' >> ~/.bashrc && \
    echo '# HBASE_HOME' >> ~/.bashrc && \
    echo 'export HBASE_HOME=/usr/local/hbase' >> ~/.bashrc && \
    echo 'export PATH=$PATH:${HBASE_HOME}/bin' >> ~/.bashrc

# 切回 root 用户进行安装
USER root

# 复制本地的安装包到容器
COPY packages/jdk-8u201-linux-x64.tar.gz /tmp/
COPY packages/hadoop-3.3.6.tar.gz /tmp/
COPY packages/hbase-2.5.11-hadoop3-bin.tar.gz /tmp/

# 安装 Java
RUN tar -zxf /tmp/jdk-8u201-linux-x64.tar.gz -C /usr/lib/jvm && \
    rm /tmp/jdk-8u201-linux-x64.tar.gz

# 安装 Hadoop
RUN tar -zxf /tmp/hadoop-3.3.6.tar.gz -C /usr/local/ && \
    mv /usr/local/hadoop-3.3.6 /usr/local/hadoop && \
    rm /tmp/hadoop-3.3.6.tar.gz

# 安装 HBase
RUN tar -zxf /tmp/hbase-2.5.11-hadoop3-bin.tar.gz -C /usr/local/ && \
    mv /usr/local/hbase-2.5.11-hadoop3 /usr/local/hbase && \
    rm /tmp/hbase-2.5.11-hadoop3-bin.tar.gz

# 创建必要的目录
RUN mkdir -p /usr/local/hadoop/tmp/dfs/name && \
    mkdir -p /usr/local/hadoop/tmp/dfs/data

# 设置权限
RUN chown -R hadoop:hadoop /usr/local/hadoop && \
    chown -R hadoop:hadoop /usr/local/hbase

# 复制配置文件
COPY config/hadoop/core-site.xml /usr/local/hadoop/etc/hadoop/
COPY config/hadoop/hdfs-site.xml /usr/local/hadoop/etc/hadoop/
COPY config/hadoop/hadoop-env.sh /usr/local/hadoop/etc/hadoop/
COPY config/hadoop/workers /usr/local/hadoop/etc/hadoop/
COPY config/hbase/hbase-env.sh /usr/local/hbase/conf/
COPY config/hbase/hbase-site.xml /usr/local/hbase/conf/

# # 删除多余的 slf4j 以避免冲突
# RUN mv /usr/local/hbase/lib/client-facing-thirdparty/log4j-slf4j-impl-2.17.2.jar /usr/local/hbase/lib/client-facing-thirdparty/log4j-slf4j-impl-2.17.2.jar.bak || true

# 复制并设置启动脚本
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chown hadoop:hadoop /entrypoint.sh

# 配置 start-dfs.sh 和 start-yarn.sh
RUN echo 'HDFS_DATANODE_USER=hadoop' >> /usr/local/hadoop/sbin/start-dfs.sh && \
    echo 'HDFS_DATANODE_SECURE_USER=hdfs' >> /usr/local/hadoop/sbin/start-dfs.sh && \
    echo 'HDFS_NAMENODE_USER=hadoop' >> /usr/local/hadoop/sbin/start-dfs.sh && \
    echo 'HDFS_SECONDARYNAMENODE_USER=hadoop' >> /usr/local/hadoop/sbin/start-dfs.sh && \
    echo 'YARN_RESOURCEMANAGER_USER=hadoop' >> /usr/local/hadoop/sbin/start-yarn.sh && \
    echo 'HADOOP_SECURE_DN_USER=yarn' >> /usr/local/hadoop/sbin/start-yarn.sh && \
    echo 'YARN_NODEMANAGER_USER=hadoop' >> /usr/local/hadoop/sbin/start-yarn.sh

# 暴露Hadoop和HBase相关端口
EXPOSE 22 9000 9870 8088 16010

# 切回hadoop用户
USER hadoop
WORKDIR /home/hadoop

# 容器启动命令
ENTRYPOINT ["/entrypoint.sh"]