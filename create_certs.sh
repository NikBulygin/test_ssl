#!/bin/bash

echo "=== Создание сертификатов Directum ==="

# Очищаем папку
rm -rf ./certs/*
mkdir -p ./certs

# Извлекаем сертификат из certs.txt
echo "Извлекаем сертификат из certs.txt..."
sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' certs.txt > ./certs/directum.crt

# Проверяем что сертификат создан
if [ -s ./certs/directum.crt ]; then
    echo "✓ Сертификат Directum создан"
    
    # Создаем копию для корневого CA (так как в цепочке только один сертификат)
    cp ./certs/directum.crt ./certs/root-ca.crt
    echo "✓ Корневой CA создан (копия сертификата Directum)"
    
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
    echo "=== Проверка результата ==="
    ls -la ./certs/
    
    echo ""
    echo "=== Готово! ==="
    echo "Сертификаты созданы. Запустите: docker-compose up --build"
else
    echo "✗ ОШИБКА: Не удалось создать сертификат"
    exit 1
fi
