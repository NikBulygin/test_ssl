#!/bin/bash

echo "=== Настройка сертификатов Directum ==="

# Очищаем и создаем папку
rm -rf ./certs/*
mkdir -p ./certs

# Извлекаем сертификат из certs.txt (если есть) или скачиваем с сервера
if [ -f "certs.txt" ]; then
    echo "Извлекаем сертификат из certs.txt..."
    sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' certs.txt > ./certs/directum.crt
else
    echo "Скачиваем сертификат с сервера..."
    openssl s_client -connect directum.uktmp.kz:443 -showcerts < /dev/null 2>/dev/null | \
        sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > ./certs/directum.crt
fi

# Проверяем что сертификат извлечен
if [ -s ./certs/directum.crt ]; then
    echo "✓ Сертификат извлечен успешно"
    echo "Subject: $(openssl x509 -in ./certs/directum.crt -noout -subject 2>/dev/null | sed 's/subject=//')"
    echo "Issuer:  $(openssl x509 -in ./certs/directum.crt -noout -issuer 2>/dev/null | sed 's/issuer=//')"
    
    # Создаем копию для корневого CA
    cp ./certs/directum.crt ./certs/root-ca.crt
    
    # Создаем символические ссылки
    cd ./certs
    DIRECTUM_HASH=$(openssl x509 -in directum.crt -noout -hash 2>/dev/null)
    ROOT_HASH=$(openssl x509 -in root-ca.crt -noout -hash 2>/dev/null)
    
    ln -sf directum.crt ${DIRECTUM_HASH}.0
    ln -sf root-ca.crt ${ROOT_HASH}.0
    
    echo "✓ Созданы символические ссылки:"
    echo "  ${DIRECTUM_HASH}.0 -> directum.crt"
    echo "  ${ROOT_HASH}.0 -> root-ca.crt"
    
    cd ..
    echo ""
    echo "=== Готово! ==="
    echo "Сертификаты настроены. Запустите: docker-compose up --build"
else
    echo "✗ ОШИБКА: Не удалось извлечь сертификат"
    exit 1
fi
