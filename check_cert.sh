#!/bin/bash

# Script to check SSL certificate trust for a domain
# Usage: ./check_cert.sh <domain> [port]

if [ $# -eq 0 ]; then
    echo "Usage: $0 <domain> [port]"
    echo "Example: $0 google.com"
    echo "Example: $0 example.com 443"
    exit 1
fi

DOMAIN=$1
PORT=${2:-443}

echo "Checking SSL certificate for domain: $DOMAIN:$PORT"
echo "================================================"

# Check connection and get certificate information
echo "1. Getting certificate information..."
openssl s_client -connect $DOMAIN:$PORT -servername $DOMAIN -showcerts < /dev/null 2>/dev/null | openssl x509 -noout -text -certopt no_header,no_version,no_serial,no_signame,no_validity,no_issuer,no_pubkey,no_sigdump,no_aux

if [ $? -eq 0 ]; then
    echo ""
    echo "2. Checking certificate trust..."
    
    # Check if certificate is trusted
    echo | openssl s_client -connect $DOMAIN:$PORT -servername $DOMAIN 2>/dev/null | grep -q "Verify return code: 0"
    
    if [ $? -eq 0 ]; then
        echo "✅ CERTIFICATE TRUSTED"
        echo "Certificate successfully verified and trusted by the system."
    else
        echo "❌ CERTIFICATE NOT TRUSTED"
        echo "Certificate failed trust verification."
        
        # Show error code
        echo ""
        echo "Error details:"
        echo | openssl s_client -connect $DOMAIN:$PORT -servername $DOMAIN 2>&1 | grep "Verify return code"
    fi
    
    echo ""
    echo "3. Additional information:"
    echo "Domain: $DOMAIN"
    echo "Port: $PORT"
    echo "Check date: $(date)"
    
else
    echo "❌ ERROR: Could not connect to $DOMAIN:$PORT"
    echo "Please check domain correctness and server availability."
    exit 1
fi
