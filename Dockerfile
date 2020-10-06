# Multi-build Dockerfile. This image will not be included into our final image. 
# We just need a reference to it. I will use that to extract IRIS jar files from it.
# Think of it as a parallel universe we just entered and it is called now "universe 0".
FROM intersystemsdc/iris-community:2020.3.0.200.0-zpm

# Based on Getty Images "https://github.com/gettyimages"
# Here is our real image. This is the universe we are going to stay on. 
FROM bitnami/spark:2.4.4
LABEL maintainer="Amir Samary <amir.samary@intersystems.com>"

USER root

# Now we can extract those jar files from universe 0, and bring them into our universe... ;)
COPY --from=0 /usr/irissys/dev/java/lib/JDK18/*.jar /custom/lib/

EXPOSE 7001-7005 7077 6066

ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# JPMML
RUN cd /custom/lib && \
    curl -sLO --retry 3 https://github.com/jpmml/jpmml-sparkml/releases/download/1.5.9/jpmml-sparkml-executable-1.5.9.jar

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
CMD [ "/custom/sbin/startservices.sh", "Master"]
