# Certificate Trust Checker

A Docker-based tool for checking SSL certificate trust for domains using custom trusted certificates.

## Features

- Docker container with OpenSSL and certificate tools
- Support for custom trusted certificates
- Script to check certificate trust for any domain
- Easy-to-use CLI interface

## Quick Start

1. **Place your certificates** in the `certs/` folder (`.crt` or `.pem` files)

2. **Build and run the container:**
   ```bash
   docker-compose up --build -d
   ```

3. **Enter the container:**
   ```bash
   docker-compose exec cert-checker bash
   ```

4. **Check certificate trust:**
   ```bash
   ./check_cert.sh google.com
   ./check_cert.sh example.com 443
   ```

## Alternative Usage

For one-time usage without keeping container running:
```bash
docker-compose run --rm cert-checker /bin/bash
```

## Script Usage

```bash
./check_cert.sh <domain> [port]
```

**Examples:**
- `./check_cert.sh google.com` (uses port 443 by default)
- `./check_cert.sh example.com 443`
- `./check_cert.sh internal-server.local 8443`

## Output

The script provides:
- ✅ **CERTIFICATE TRUSTED** - Certificate is trusted by the system
- ❌ **CERTIFICATE NOT TRUSTED** - Certificate failed trust verification
- Detailed certificate information
- Error details if connection fails

## File Structure

```
├── Dockerfile              # Container configuration
├── docker-compose.yml      # Docker Compose setup
├── check_cert.sh          # Certificate checking script
├── certs/                 # Folder for trusted certificates
│   └── README.md          # Instructions for certificates
└── README.md              # This file
```

## Adding Trusted Certificates

1. Place your certificate files (`.crt` or `.pem`) in the `certs/` folder
2. Rebuild the container: `docker-compose up --build -d`
3. All certificates will be automatically added as trusted

## Requirements

- Docker
- Docker Compose
- Internet connection for testing external domains
