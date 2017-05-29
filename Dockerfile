FROM fno2010/hadoop:2.7
MAINTAINER Jensen Zhang

# Version
ENV SPARK_VERSION=2.1.1

# Set home
ENV SPARK_HOME=/usr/local/spark-$SPARK_VERSION

# Install dependencies
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install \
    -yq --no-install-recommends  \
      python python3 iputils-ping net-tools \
      openssh-client openssh-server \
  && apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Install Spark
RUN mkdir -p "${SPARK_HOME}" \
  && export ARCHIVE=spark-$SPARK_VERSION-bin-without-hadoop.tgz \
  && export DOWNLOAD_PATH=apache/spark/spark-$SPARK_VERSION/$ARCHIVE \
  && curl -sSL https://mirrors.ocf.berkeley.edu/$DOWNLOAD_PATH | \
    tar -xz -C $SPARK_HOME --strip-components 1 \
  && rm -rf $ARCHIVE
COPY spark-env.sh $SPARK_HOME/conf/spark-env.sh
ENV PATH=$PATH:$SPARK_HOME/bin

# Ports
EXPOSE 6066 7077 8080 8081

# Copy start script
COPY start-spark /opt/util/bin/start-spark

# Modify start script
RUN sed -i 's/(hostname)/2/' /opt/util/bin/start-spark \
  && sed -i 's/namenode daemon/namenode daemon $2/' /opt/util/bin/start-spark \
  && sed -i 's/namenode \$2/namenode $2 $3/' /opt/util/bin/start-hadoop \
  && sed -i 's/(hostname)/{2}/' /opt/util/bin/start-hadoop-namenode

# Fix environment for other users
RUN echo "export SPARK_HOME=$SPARK_HOME" >> /etc/bash.bashrc \
  && echo 'export PATH=$PATH:$SPARK_HOME/bin'>> /etc/bash.bashrc

# Add deprecated commands
RUN echo '#!/usr/bin/env bash' > /usr/bin/master \
  && echo 'start-spark master $@' >> /usr/bin/master \
  && chmod +x /usr/bin/master \
  && echo '#!/usr/bin/env bash' > /usr/bin/worker \
  && echo 'start-spark worker $@' >> /usr/bin/worker \
  && chmod +x /usr/bin/worker
