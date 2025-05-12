#!/bin/bash

case $1 in
"start"){
        echo ================== 启动 集群 ==================

        #启动 Zookeeper集群
        zk.sh start

        #启动 Hadoop集群
        hdp.sh start

        #启动 Kafka采集集群
        kf.sh start

        #启动采集 Flume
        f1.sh start

#启动日志消费 Flume
        f2.sh start

#启动业务消费 Flume
        f3.sh start

#启动 maxwell
        mxw.sh start

        };;
"stop"){
        echo ================== 停止 集群 ==================

#停止 Maxwell
        mxw.sh stop

#停止 业务消费Flume
        f3.sh stop

#停止 日志消费Flume
        f2.sh stop

#停止 日志采集Flume
        f1.sh stop

        #停止 Kafka采集集群
        kf.sh stop

        #停止 Hadoop集群
        hdp.sh stop

#循环直至 Kafka 集群进程全部停止
		kafka_count=$(xcall jps | grep Kafka | wc -l)
		while [ $kafka_count -gt 0 ]
		do
			sleep 1
			kafka_count=$(jpsall | grep Kafka | wc -l)
            echo "当前未停止的 Kafka 进程数为 $kafka_count"
		done

        #停止 Zookeeper集群
        zk.sh stop

};;
esac

