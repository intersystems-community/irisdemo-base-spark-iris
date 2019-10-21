#!/bin/bash
#
# Amir Samary - 2018
#

# This script expects to receive as environment variables:
# - IRIS_MASTER_HOST        : This will set a default configuration for where the IRIS server is so that 
#                             our spark connector can connect to it. This can be replaced when creating a
#                             spark session. But having a default makes creating the session more straightforward.
# - IRIS_MASTER_PORT        : The same as above for the iris port. This should be the super server port.
# - IRIS_MASTER_USERNAME    : The same as above for the iris username.
# - IRIS_MASTER_PASSWORD    : The same as above for the iris password.
# - IRIS_MASTER_NAMESPACE   : The same as above for the iris namespace.
# - MASTER                  : Spark Master URL

export MASTER="spark://sparkmaster:7077"

if [ "$SPARK_NODE_TYPE" == "Worker" ]
then
    if [ -f $SPARK_HOME/conf/spark-defaults.conf.worker ]
    then
        rm -f $SPARK_HOME/conf/spark-defaults.conf
        mv $SPARK_HOME/conf/spark-defaults.conf.worker $SPARK_HOME/conf/spark-defaults.conf
    fi
else
    if [ -f $SPARK_HOME/conf/spark-defaults.conf.master ]
    then
        rm -f $SPARK_HOME/conf/spark-defaults.conf
        mv $SPARK_HOME/conf/spark-defaults.conf.master $SPARK_HOME/conf/spark-defaults.conf
    fi
fi

for variable in MASTER SPARK_MASTER_PORT IRIS_MASTER_HOST IRIS_MASTER_PORT IRIS_MASTER_NAMESPACE IRIS_MASTER_USERNAME IRIS_MASTER_PASSWORD;
do
    value=$(eval echo "\$$variable")
    if [ ! -z "$value" ]
    then
        printf "\n\nConfiguring $SPARK_HOME/conf/spark-defaults.conf with $variable=$value..."
        sed -i.bak "s/$variable/$value/g" $SPARK_HOME/conf/spark-defaults.conf
    fi
done

printf "\n\n"

if [ "$SPARK_NODE_TYPE" == "Worker" ]
then
    $SPARK_HOME/bin/spark-class org.apache.spark.deploy.worker.Worker $MASTER
else
    $SPARK_HOME/bin/spark-class org.apache.spark.deploy.master.Master -h sparkmaster
fi