# SSL Certificate Monitor with Uptime Kuma

A simple setup using Uptime Kuma to monitor SSL certificates and their expiration dates.

## Features

- Web-based interface for monitoring SSL certificates
- Automatic SSL certificate expiration monitoring
- Real-time status updates
- Email/notification alerts
- Multiple monitoring types (HTTP, HTTPS, TCP, etc.)

## Quick Start

1. **Add custom certificates (optional):**
   - Place your `.crt` or `.pem` files in the `certs/` folder
   - These will be automatically trusted by Uptime Kuma

2. **Start Uptime Kuma:**
   ```bash
   docker-compose up -d
   ```

3. **Access the web interface:**
   Open http://localhost:3001 in your browser

4. **Initial setup:**
   - Create admin account
   - Add your first monitor

## Adding SSL Certificate Monitoring

1. **Go to "Add Monitor"**
2. **Select "HTTPS" type**
3. **Configure:**
   - **Friendly Name**: Your domain name
   - **URL**: https://yourdomain.com
   - **Heartbeat Interval**: 60 seconds (or as needed)
   - **Retries**: 2
   - **Timeout**: 10 seconds

4. **Advanced SSL Options:**
   - **Ignore TLS/SSL errors**: Uncheck (to verify certificates)
   - **Certificate expiry days**: Set warning threshold (e.g., 30 days)

## Monitor Types Available

- **HTTP(s)**: Web server monitoring with SSL certificate checks
- **TCP**: Port connectivity testing
- **Ping**: ICMP ping monitoring
- **DNS**: DNS resolution monitoring
- **Steam Game Server**: Game server monitoring
- **Docker Container**: Container health monitoring

## SSL Certificate Features

- **Expiration Monitoring**: Automatic alerts before certificate expires
- **Certificate Chain Validation**: Full certificate chain verification
- **Custom CA Support**: Add custom certificates to trusted store via `certs/` folder
- **Detailed Certificate Info**: View certificate details in web interface
- **Trusted Certificate Management**: All certificates in `certs/` folder are automatically trusted

## Configuration

### Environment Variables
- `UPTIME_KUMA_PORT`: Port for web interface (default: 3001)

### Data Persistence
- All data is stored in Docker volume `uptime-kuma-data`
- Includes monitor configurations, user accounts, and settings

## Usage Examples

### Monitor External Website
```
Type: HTTPS
URL: https://google.com
Heartbeat: 60s
```

### Monitor Internal Server
```
Type: HTTPS
URL: https://internal.company.com
Heartbeat: 300s
Ignore SSL errors: false
```

### Monitor with Custom Port
```
Type: HTTPS
URL: https://example.com:8443
Heartbeat: 120s
```

## Stopping the Service

```bash
docker-compose down
```

## Data Backup

To backup your configuration:
```bash
docker run --rm -v uptime-kuma-data:/data -v $(pwd):/backup ubuntu tar czf /backup/uptime-kuma-backup.tar.gz -C /data .
```

To restore:
```bash
docker run --rm -v uptime-kuma-data:/data -v $(pwd):/backup ubuntu tar xzf /backup/uptime-kuma-backup.tar.gz -C /data
```
