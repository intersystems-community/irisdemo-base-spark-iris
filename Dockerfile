# Multi-build Dockerfile. This image will not be included into our final image. 
# We just need a reference to it. I will use that to extract IRIS jar files from it.
# Think of it as a parallel universe we just entered and it is called now "universe 0".
FROM intersystemsdc/iris-community:2020.3.0.200.0-zpm

# Based on Getty Images "https://github.com/gettyimages"
# Here is our real image. This is the universe we are going to stay on. 
#FROM debian:stretch
FROM ubuntu:20.04
LABEL maintainer="Amir Samary <amir.samary@intersystems.com>"

# Now we can extract those jar files from universe 0, and bring them into our universe... ;)
COPY --from=0 /usr/irissys/dev/java/lib/JDK18/*.jar /custom/lib/

EXPOSE 7001-7005 7077 6066

# LOCALES: Only when using FROM debian:stretch
# RUN apt-get update \
#  && apt-get install -y locales \
#  && dpkg-reconfigure -f noninteractive locales \
#  && locale-gen C.UTF-8 \
#  && /usr/sbin/update-locale LANG=C.UTF-8 \
#  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
#  && locale-gen \
#  && apt-get clean \
#  && rm -rf /var/lib/apt/lists/*
# Users with other locales should set this in their derivative image
# ENV LANG en_US.UTF-8
# ENV LANGUAGE en_US:en
# ENV LC_ALL en_US.UTF-8

RUN apt-get update \
 && apt-get install -y tini curl unzip \
    python3 python3-setuptools \
    apt-transport-https \
 && ln -s /usr/bin/python3 /usr/bin/python \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# JAVA ORACLE
# ARG JAVA_MAJOR_VERSION=8
# ARG JAVA_UPDATE_VERSION=171
# ARG JAVA_BUILD_NUMBER=11
# ENV JAVA_HOME /usr/jdk1.${JAVA_MAJOR_VERSION}.0_${JAVA_UPDATE_VERSION}

# ENV PATH $PATH:$JAVA_HOME/bin
# RUN curl -sL --retry 3 --insecure \
#   --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
#   "http://download.oracle.com/otn-pub/java/jdk/${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-b${JAVA_BUILD_NUMBER}/512cd62ec5174c3487ac17c61aaa89e8/server-jre-${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-linux-x64.tar.gz" \
#   | gunzip \
#   | tar x -C /usr/ \
#   && ln -s $JAVA_HOME /usr/java \
#   && rm -rf $JAVA_HOME/man

# JAVA OpenJDK
RUN apt-get -y update && \
    apt-get install --no-install-recommends -y openjdk-8-jre-headless ca-certificates-java && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV HADOOP_VERSION 2.7

# SPARK Version 2.1.3
# This is the same version that the zeppelin image uses and that InterSystems currently supports
# ENV SPARK_VERSION 2.1.3
# ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
# ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
# ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
# ENV PATH $PATH:${SPARK_HOME}/bin
# ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info
# RUN curl -sL --retry 3 \
#   "https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
#   | gunzip \
#   | tar x -C /usr/ \
#  && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
#  && chown -R root:root $SPARK_HOME

# SPARK Version 2.4.4
# This is the same version that the zeppelin image uses and that InterSystems currently supports
ENV SPARK_VERSION 2.4.4
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV PATH $PATH:${SPARK_HOME}/bin
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info
RUN echo "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" && \
  curl -sL --retry 3 \
  "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | tar -xz -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME \
 && chown -R root:root /custom/lib/ \
 && chmod +x $SPARK_HOME/bin/load-spark-env.sh

COPY --from=0 /usr/irissys/dev/java/lib/JDK18/*.jar /usr/spark-2.4.4/jars/

# JPMML
RUN cd /custom/lib && \
    curl -sLO --retry 3 https://github.com/jpmml/jpmml-sparkml/releases/download/1.5.9/jpmml-sparkml-executable-1.5.9.jar && \
    cd $SPARK_HOME

# This file has many strings to be replaced:
# - SPARK_MASTER_HOST       : This is used by spark CLI such as pyspark to determine where spark master is.
# - SPARK_MASTER_PORT       : The same as above for the spark master port.
# - IRIS_MASTER_HOST        : This will set a default configuration for where the IRIS server is so that 
#                             our spark connector can connect to it. This can be replaced when creating a
#                             spark session. But having a default makes creating the session more straightforward.
# - IRIS_MASTER_PORT        : The same as above for the iris port. This should be the super server port.
# - IRIS_MASTER_USERNAME    : The same as above for the iris username.
# - IRIS_MASTER_PASSWORD    : The same as above for the iris password.
# - IRIS_MASTER_NAMESPACE   : The same as above for the iris namespace.
ADD ./conf/master/spark-defaults.conf $SPARK_HOME/conf/spark-defaults.conf.master
ADD ./conf/worker/spark-defaults.conf $SPARK_HOME/conf/spark-defaults.conf.worker

ADD ./conf/startservices.sh /custom/sbin/
RUN chmod +x /custom/sbin/startservices.sh && \
    chmod +x /custom/lib/*

WORKDIR $SPARK_HOME

ENTRYPOINT [ "/usr/bin/tini", "-s", "--", "/bin/bash", "-c", "/custom/sbin/startservices.sh", "Master" ]
#ENTRYPOINT [ "/usr/bin/tini", "-s", "--", "sleep", "100000" ]

#CMD [ "sh", "-c", "source", "/custom/sbin/startservices.sh", "Master"]
