# Use Alpine 3.18 as the base image
FROM alpine:3.18

# Install OpenJDK 8
RUN apk update && \
    apk upgrade && \
    apk add --no-cache openjdk8

# Set the JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk

# Add Java binaries to the system PATH
ENV PATH="$JAVA_HOME/bin:${PATH}"

# Install Liquibase
ENV LIQUIBASE_VERSION=4.6.3
ENV LIQUIBASE_HOME=/opt/liquibase

RUN apk add --no-cache curl && \
    curl -L -o ${LIQUIBASE_HOME}/liquibase-${LIQUIBASE_VERSION}.tar.gz "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" && \
    tar -xzf ${LIQUIBASE_HOME}/liquibase-${LIQUIBASE_VERSION}.tar.gz -C ${LIQUIBASE_HOME} && \
    rm ${LIQUIBASE_HOME}/liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    chmod +x ${LIQUIBASE_HOME}/liquibase && \
    ln -s ${LIQUIBASE_HOME}/liquibase /usr/local/bin/
