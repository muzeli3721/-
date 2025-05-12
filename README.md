# <center>**电商平台离线数据仓库系统**</center>

## 1. 项目总体结构

总体的目录结构如下：

```bash
    offline-data-warehouse
     ├── deploy                                            # 各个部署模块
     │     ├── file-kafka                                  # 使用 flume 监控【用户行为日志】，并同步到 kafka
     │     ├── hdfs-mysql                                  # 使用 datax 将 ads 层的数据同步到 mysql
     │     ├── kafka-hdfs                                  # 使用 flume 将 kafka 中的业务数据，同步到 hdfs
     │     ├── mock-db                                     # 模仿【业务数据】生成模块
     │     ├── mock-log                                    # 模仿【用户行为】日志生成模块
     │     ├── mysql-hdfs                                  # 使用 datax 将 MySQL 的全量数据，同步到 hdfs
     │     ├── mysql-kafka                                 # 使用 maxwell 监控 MySQL 增量数据，并同步到 kafka
     │     ├── shell                                       # 项目的部署、组件启停、模块启停脚本
     │     ├── sql                                         # 整个离线数仓使用到的 mysql-sql，hive-sql
     │     └── warehouse                                   # 数仓各层之间的调用脚本
     ├── deploy.sh                                         # 一键打包脚本
     ├── doc                                               # 相关文档
     ├── flume                                             # 自定义 flume 拦截器源码，用于拦截不规则的数据
     └── ReadMe.md                                         # 项目说明文档                                                                
```

<br/>

## 2. 项目架构图

**<center>项目架构图</center>**

![项目架构图](doc/5-%E9%87%87%E9%9B%865.0%E6%9E%B6%E6%9E%84.png)

## 3. deploy 打包后的项目模块说明

### 3.1 mock-log 模块

```bash
    # 模拟 生成用户行为日志
    mock-log
     ├── logs                                              # 运行产生的日志目录
     ├── application.yml                                   # mock-log 的配置文件                                       
     ├── cycle.sh                                          # 该脚本调用 mock-log.sh，进行循环生成，默认 10 次
     ├── logback.xml                                       # 日志配置文件
     ├── mock-log.jar                                      # 执行的 jar
     ├── mock-log.sh                                       # mock-log 模块的启停脚本
     └── path.json                                         # 与生成的数据相关 
```

### 3.2 file-kafka 模块

```bash
    # 将生成的 用户行为日志 同步到 kafka
    file-kafka
     ├── file-kafka.conf                                   # flume 监控本地日志文件的配置文件
     ├── file-kafka.sh                                     # 启停脚本
     ├── flume-1.0.jar                                     # 执行 offline-data-warehouse/flume/build.sh 生成的 jar，用于拦截不规则数据
     └── position.json                                     # flume 监控本地文件产生的记录
```

### 3.3 mock-db 模块

```bash
    # 模拟 生成业务数据
    mock-db
     ├── logs                                              # 运行产生的日志目录
     ├── application.properties                            # mock-db 的配置文件
     ├── cycle.sh                                          # 该脚本调用 mock-db.sh，进行循环生成，默认 10 次
     ├── data.sql                                          # 模拟 mysql 数据库原始的数据
     ├── mock-db.jar                                       # 执行的 jar，修改过尚硅谷原始的 jar，已经支持 mysql 8.0.x
     ├── mock-db.sh                                        # mock-db 模块的启停脚本
     └── table.sql                                         # 电商业务数据 建表语句 
```

### 3.4 mysql-hdfs 模块

```bash
    # 使用 DataX 将生成的 业务数据全量同步到 HDFS，仅在项目部署完成后，初始化的的时候使用一次，后续无需再次操作
    mysql-hdfs
     ├── conf                                              # DataX 将数据库中维度表全量同步到 HDFS 的配置文件
     │     ├── activity_info.json                          # 活动信息表
     │     ├── activity_rule.json                          # 活动规则表
     │     ├── base_category1.json                         # 一级分类表
     │     ├── base_category2.json                         # 二级分类表
     │     ├── base_category3.json                         # 三级分类表
     │     ├── base_dic.json                               # 字典表
     │     ├── base_province.json                          # 省份表
     │     ├── base_region.json                            # 地区表
     │     ├── base_trademark.json                         # 品牌表
     │     ├── cart_info.json                              # 购物车表
     │     ├── coupon_info.json                            # 优惠券信息
     │     ├── sku_attr_value.json                         # SKU 平台属性值表
     │     ├── sku_info.json                               # SKU 信息表
     │     ├── sku_sale_attr_value.json                    # SKU 销售属性表
     │     └── spu_info.json                               # SPU 信息表
     ├── GenerateMysqlHdfsJob.py                           # 使用 python 生成 DataX 的 mysql --> hdfs 的配置文件
     └── mysql-hdfs.sh                                     # 该脚本调用 DataX  mysql 数据同步到 hdfs
```

### 3.5 mysql-kafka 模块

```bash
    # 使用 MaxWell 监控 Mysql，用于将产生的 增量业务数据 同步到 kafka
    mysql-kafka 
     ├── config.properties                                 # MaxWell 监控 Mysql 的配置文件
     ├── meta.sql                                          # MaxWell 监控时，在数据库创建的表
     ├── mysql-kafka.sh                                    # 监控数据库启停脚本 
     └── mysql-kafka-init.sh                               # 初始化所有的增量表，只需安装时执行一次
```

### 3.6 kafka-hdfs 模块

```bash
    # 将模拟生成的 用户行为日志 和 增量业务数据，通过 flume 同步到 hdfs
    kafka-hdfs
     ├── data-db                                           # flume 同步过程中产生的数据存储目录
     ├── check-point                                       # 检查点数据
     │     ├── db                                          # 保存的 增量业务数据 检查点数据 
     │     └── log                                         # 保存的 用户行为日志 检查点数据
     ├── data                                              # flume 同步过程中产生的数据存储目录
     │     ├── db                                          # 增量业务数据  
     │     └── log                                         # 用户行为日志
     ├── flume-1.0.jar                                     # 执行 offline-data-warehouse/flume/build.sh 生成的 jar，用于拦截不规则数据
     ├── kafka-hdfs-db.conf                                # 增量业务数据 同步到 hdfs 的配置文件
     ├── kafka-hdfs-db.sh                                  # 增量业务数据 同步启停脚本
     ├── kafka-hdfs-log.conf                               # 用户行为日志 同步到 hdfs 的配置文件
     └── kafka-hdfs-log.sh                                 # 用户行为日志 同步启停脚本
```

### 3.7 hdfs-mysql 模块

```bash
    # 将 ADS 层数据导出到 Mysql
    hdfs-mysql
     ├── conf                                              # DataX 将 HDFS 全量同步到 Mysql 的配置文件
     │     ├── ads_activity_stats.json                     # 最近30天发布的活动的补贴率
     │     ├── ads_coupon_stats.json                       # 最近30天发布的优惠券的补贴率
     │     ├── ads_new_buyer_stats.json                    # 新增交易用户统计
     │     ├── ads_order_by_province.json                  # 各省份交易统计
     │     ├── ads_page_path.json                          # 路径分析(页面单跳)
     │     ├── ads_repeat_purchase_by_tm.json              # 最近7/30日各品牌复购率
     │     ├── ads_sku_cart_num_top3_by_cate.json          # 各分类商品购物车存量Top3
     │     ├── ads_trade_stats_by_cate.json                # 各品类商品交易统计
     │     ├── ads_trade_stats_by_tm.json                  # 各品牌商品交易统计
     │     ├── ads_trade_stats.json                        # 交易综合统计
     │     ├── ads_traffic_stats_by_channel.json           # 各渠道流量统计
     │     ├── ads_user_action.json                        # 用户行为漏斗分析
     │     ├── ads_user_change.json                        # 用户变动统计
     │     ├── ads_user_retention.json                     # 用户留存率
     │     ├── ads_user_stats.json                         # 用户新增活跃统计
     ├── GenerateHdfsMysql.py                              # 使用 python 生成 DataX 的 hdfs --> mysql 的配置文件
     └── hdfs-mysql.sh                                     # 该脚本调用 DataX 将 hdfs 数据同步到 mysql
```

### 3.8 sql 模块

```bash
    # 数仓中各层之间的流转
    sql
     ├── ads.sql                                           # ADS 建表和插入数据用到的 hive-sql
     ├── dim.sql                                           # DIM 建表和插入数据用到的 hive-sql
     ├── dwd.sql                                           # DWD 建表和插入数据用到的 hive-sql
     ├── dws.sql                                           # DWS 建表和插入数据用到的 hive-sql
     ├── export.sql                                        # ADS 层导出到 mysql 的建表语句
     ├── hive.sql                                          # 整个数仓中所有表的建表语句（初始化时使用一次）
     └── ods.sql                                           # ODS 建表和插入数据用到的 hive-sql
```

### 3.9 shell 模块

```bash
    # 部署包的部署、初始化、组件启停，各模块启停脚本
    shell
     ├── component.sh                                      # 各个大数据组件的启停脚本
     ├── data-sync.sh                                      # 将模拟数据同步到 hdfs 的启停脚本
     ├── init.sh                                           # 部署完成后，一键初始化
     ├── range.sh                                          # range 认证脚本：暂时不需要
     ├── warehouse.sh                                      # 数仓中每层之间的计算
     ├── xcall.sh                                          # 在多台服务器执行命令，并查看结果
     └── xync.sh                                           # 文件同步脚本 
```

### 3.10 warehouse 模块

```bash
 # *._init.sh 仅在数仓初始化的时候使用，用于同步历史数据
    warehouse
     ├── dwd-dws-init.sh                                   # DWS 层 初始化 数据装载
     ├── dwd-dws.sh                                        # DWS 层  每日  数据装载
     ├── dws-ads.sh                                        # ADS 层  每日  数据装载
     ├── hdfs-ods-init.sh                                  # ODS 层 初始化 数据装载
     ├── hdfs-ods.sh                                       # ODS 层  每日  数据装载
     ├── ods-dim-init.sh                                   # DIM 层 初始化 数据装载
     ├── ods-dim.sh                                        # DIM 层  每日  数据装载
     ├── ods-dwd_init.sh                                   # DWD 层 初始化 数据装载
     └── ods-dwd.sh                                        # DWD 层  每日  数据装载
```

<br/>

## 4. 基础组件的集群部署

### 4.1 大数据组件及版本说明

**<center>服务器基本信息</center>**

|      |     master      |     slaver1     |     slaver2     |
| :--: | :-------------: | :-------------: | :-------------: |
| CPU  |       4核       |       4核       |       4核       |
| 内存 |       8G        |       8G        |       8G        |
| 硬盘 |    SSD 50GB     |    SSD 50GB     |    SSD 50GB     |
| 网卡 |    1000Mbps     |    1000Mbps     |    1000Mbps     |
|  IP  | 192.168.100.102 | 192.168.100.103 | 192.168.100.104 |
| 系统 |   Centos 7.5    |   Centos 7.5    |   Centos 7.5    |

<br/>

**<center>组件规划</center>**

|     组件名称     |  版本号  |      子服务       | master | slaver1 | slaver2 | slaver3 |                              说明                              |
|:----------------:|:--------:|:-----------------:|:------:|:-------:|:-------:|:-------:|:--------------------------------------------------------------:|
|       java       | 1.8.321  |       Java        |   √   |   √    |   √    |   √    |                                                                |
|      scala       | 2.12.17  |       Scala       |   √   |   √    |   √    |   √    |                                                                |
|      mysql       |  8.0.28  |       Mysql       |   √   |         |         |         |                                                                |
|                  |          |      NameNode     |   √   |         |         |         |                                                                |
|                  |  3.2.4   | SecondaryNameNode |   √   |         |         |         |                                                                |
|      hadoop      |          |     DataNode      |   √   |   √     |   √    |   √    |                                                                |
|                  |          |  ResourceManager  |   √   |         |         |         |                                                                |
|                  |          |    NodeManager    |        |   √    |   √    |   √    |                                                                |
|      spark       |  3.2.3   |   Spark on Yarn   |   √   |   √    |   √    |   √    |          需要编译源码，解决与 hadoop-3.2.4 的兼容问题          |
|      hbase       |  2.4.16  |      HMaster      |   √   |         |         |         |                                                                |
|                  |          |   HRegionServer   |        |   √    |   √    |   √    |                                                                |
|       hive       |  3.1.3   |   Hive on Spark   |   √   |         |         |         |  需要编译源码，解决与 hadoop-3.2.4 和 Spark-3.2.4 的兼容问题   |
|    zookeeper     |  3.6.4   |     Zookeeper     |        |   √    |   √    |   √    |                                                                |
|      kafka       |  3.2.3   |       Kafka       |        |   √    |   √    |   √    |                                                                |
|      flume       |  1.11.0  |       Flume       |        |   √    |   √    |   √    |               master 消费 Kafka，slaver 采集日志               |
|     maxwell      |  1.29.2  |      Maxwell      |        |   √    |   √    |   √    |                           同步 Mysql                           |
| DolphinScheduler |  3.1.3   |   MasterServer    |   √   |   √    |         |         |                                                                |
|                  |          |   WorkerServer    |        |   √    |   √    |   √    |                                                                |
|      datax       |  2022.9  |       DataX       |   √    |       |         |         |            需要替换 Mysql 的驱动 jar，以支持 8.0.x             |

### 4.2 项目服务规划

<center>项目服务规划</center>

|     服务名称     | 版本号  | master | slaver1 | slaver2 | slaver3 |            说明            |
|:----------------:|:------:|:------:|:-------:|:-------:|:-------:|:--------------------------:|
|     mock-log     |  1.0   |        |   √    |   √    |   √    |         生成用户日志         |
|    file-kafka    |  1.0   |        |   √    |   √    |   √    |         监控生成日志         |
|     mock-db      |  1.0   |        |   √    |   √    |   √    |         生成业务数据         |
|    mysql-hdfs    |  1.0   |   √   |       |         |         |      同步历史数据到 HDFS      |
|    hdfs-mysql    |  1.0   |   √   |       |         |         |     同步 ADS 数据到 Mysql     |
|    mysql-kafka   |  1.0   |        |   √   |         |         |         监控业务数据         |
|  kafka-hdfs-db   |  1.0   |        |        |   √    |         |    将用户日志同步到 HDFS     |
|  kafka-hdfs-log  |  1.0   |        |        |        |    √    |    将业务数据同步到 HDFS     |

## 

## 5. HDFS 路径说明

```bash
    /warehouse
      ├── ads                                              # ADS 层表数据存储路径
      ├── conf                                             # 配置文件   存储路径
      ├── data                                             # 第三方文件 存储路径
      ├── db                                               # 同步的 业务数据 路径
      ├── dim                                              # DIM 层表数据存储路径
      ├── dwd                                              # DWD 层表数据存储路径
      ├── dws                                              # DWS 层表数据存储路径
      ├── jars                                             # 自定义 udf、udaf、udtf 函数 jar
      ├── log                                              # 同步的 行为日志 路径
      ├── ods                                              # ODS 层表数据存储路径
      └── tmp                                              # TMP 临时数据存储路径
```

<br/>
