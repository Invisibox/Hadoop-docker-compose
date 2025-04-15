#!/bin/bash

# 启动SSH服务
sudo service ssh start

# 加载环境变量
source /etc/profile
source ~/.bashrc

# 预先连接localhost以接受指纹
ssh-keyscan -H localhost >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -H 127.0.0.1 >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -H 0.0.0.0 >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -H $(hostname) >> ~/.ssh/known_hosts 2>/dev/null

# 格式化namenode（仅首次运行时需要）
if [ ! -d "/usr/local/hadoop/tmp/dfs/name/current" ]; then
  echo "==== 正在格式化 NameNode ===="
  $HADOOP_HOME/bin/hdfs namenode -format
fi

# 启动 HDFS
echo "==== 启动 HDFS ===="
$HADOOP_HOME/sbin/start-dfs.sh

# 等待HDFS完全启动
echo "==== 等待HDFS启动 ===="
sleep 10

# 启动 YARN
echo "==== 启动 YARN ===="
$HADOOP_HOME/sbin/start-yarn.sh

# 创建HBase在HDFS上需要的目录
echo "==== 创建 HBase 目录 ===="
$HADOOP_HOME/bin/hadoop fs -mkdir -p /hbase
$HADOOP_HOME/bin/hadoop fs -chmod 777 /hbase

# 创建HBase本地目录
mkdir -p $HBASE_HOME/tmp
mkdir -p $HBASE_HOME/zookeeper
mkdir -p $HBASE_HOME/logs
mkdir -p $HBASE_HOME/pids

# 清理可能存在的旧日志和PID文件
rm -rf $HBASE_HOME/logs/*
rm -f /tmp/hbase-*.pid

# 启动 HBase
echo "==== 启动 HBase ===="
$HBASE_HOME/bin/stop-hbase.sh > /dev/null 2>&1 || true
sleep 2
$HBASE_HOME/bin/start-hbase.sh

# 等待HBase完全启动
echo "==== 等待HBase启动(30秒) ===="
sleep 30

# 验证HBase状态
echo "==== HBase 状态 ===="
jps
$HBASE_HOME/bin/hbase shell -n "status 'simple'" || {
  echo "HBase未正常启动，尝试重启..."
  $HBASE_HOME/bin/stop-hbase.sh
  sleep 5
  $HBASE_HOME/bin/start-hbase.sh
  sleep 20
  echo "重启后状态："
  jps
}

echo "==== 所有服务启动完成 ===="
echo "HDFS Web UI: http://localhost:9870"
echo "YARN Web UI: http://localhost:8088"
echo "HBase Web UI: http://localhost:16010"

# 保持容器运行
tail -f /dev/null