# Trusted Certificates Folder

Place your custom certificate files here to make them trusted by Uptime Kuma.

## Supported Formats
- `.crt` files
- `.pem` files
- `.cer` files

## Usage
1. Copy your certificate files to this folder
2. Restart the container: `docker-compose restart`
3. Uptime Kuma will now trust these certificates when checking SSL connections

## Example Files
- `my-ca.crt` - Your internal CA certificate
- `internal-ca.pem` - Internal certificate authority
- `company-root.crt` - Company root certificate

## Notes
- All certificates in this folder are automatically added as trusted
- Changes require container restart to take effect
- Certificates are mounted read-only for security