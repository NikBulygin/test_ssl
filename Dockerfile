FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    openssl \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /app

# Copy certificates folder
COPY certs/ /usr/local/share/ca-certificates/

# Update trusted certificates
RUN update-ca-certificates

# Copy check script
COPY check_cert.sh /app/check_cert.sh
RUN chmod +x /app/check_cert.sh && \
    sed -i 's/\r$//' /app/check_cert.sh

# Set entry point
ENTRYPOINT ["/bin/bash"]
