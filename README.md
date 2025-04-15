# Hadoop & HBase Docker 环境

此项目提供基于 Podman 的 Hadoop 和 HBase 环境，用于完成厦门大学林子雨编著《大数据技术原理与应用（第 4 版）》中的实验内容。

## 环境组件

- JDK 1.8.0_201
- Hadoop 3.3.6
- HBase 2.5.11
- Podman 5.4.2
- Podman-compose 1.3.0

## 使用方法

### 1. 下载必要的安装包

```bash
mkdir -p packages
cd packages

# 下载Java 1.8 JDK
wget https://repo.huaweicloud.com/java/jdk/8u201-b09/jdk-8u201-linux-x64.tar.gz

# 下载Hadoop 3.3.6
wget https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz

# 下载HBase 2.5.11
wget https://mirrors.tuna.tsinghua.edu.cn/apache/hbase/2.5.11/hbase-2.5.11-hadoop3-bin.tar.gz

cd ..
```

### 2. 构建并启动容器

使用 Podman:

```bash
podman-compose up -d
```

或使用 Docker（未测试）:

```bash
docker-compose up -d
```

### 3. 访问服务

构建完成后，可通过以下地址访问各服务：

- HDFS Web UI: http://localhost:9870
- YARN Web UI: http://localhost:8088
- HBase Web UI: http://localhost:16010

### 4. 进入容器

```bash
podman exec -it hadoop-hbase bash
# 或
docker exec -it hadoop-hbase bash
```

## 数据持久化

数据通过 Docker volumes 进行持久化：

- hadoop-data: /usr/local/hadoop/tmp
- hbase-data: /usr/local/hbase/data

## 用户信息

容器默认使用 hadoop 用户，密码为空