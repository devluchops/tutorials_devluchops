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

# Set the working directory
WORKDIR /app

# Copy your application files to the container
COPY . /app

# Specify the command to run your application
CMD ["<your-command>"]
