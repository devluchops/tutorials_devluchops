# Use Alpine 3.18 as the base image
FROM alpine:3.18

# Update package repositories and install necessary packages
RUN apk update && \
    apk upgrade && \
    apk add --no-cache <your-package-names>

# Set the working directory
WORKDIR /app

# Copy your application files to the container
COPY . /app

# Specify the command to run your application
CMD ["<your-command>"]