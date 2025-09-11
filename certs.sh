#!/bin/bash

echo "=== Настройка сертификатов Directum ==="

# Очищаем папку
rm -rf ./certs/*
mkdir -p ./certs

# Извлекаем сертификат Directum из certs.txt
echo "Извлекаем сертификат Directum из certs.txt..."
sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' certs.txt > ./certs/directum.crt

# Проверяем что сертификат создан
if [ -s ./certs/directum.crt ]; then
    echo "✓ Сертификат Directum извлечен"
    
    # Ищем корневой CA сертификат
    if [ -f "uktmp-root-ca.cer" ]; then
        cp uktmp-root-ca.cer ./certs/uktmp-root-ca.crt
        echo "✓ Корневой CA скопирован из uktmp-root-ca.cer"
        ROOT_CERT="./certs/uktmp-root-ca.crt"
    else
        echo "⚠ uktmp-root-ca.cer не найден, используем копию Directum как корневой CA"
        cp ./certs/directum.crt ./certs/root-ca.crt
        ROOT_CERT="./certs/root-ca.crt"
    fi
    
    # Проверяем связь между сертификатами
    echo ""
    echo "=== Информация о сертификатах ==="
    echo "Directum Subject: $(openssl x509 -in ./certs/directum.crt -noout -subject 2>/dev/null | sed 's/subject=//')"
    echo "Directum Issuer:  $(openssl x509 -in ./certs/directum.crt -noout -issuer 2>/dev/null | sed 's/issuer=//')"
    echo "Root CA Subject:  $(openssl x509 -in $ROOT_CERT -noout -subject 2>/dev/null | sed 's/subject=//')"
    
    # Создаем символические ссылки
    cd ./certs
    DIRECTUM_HASH=$(openssl x509 -in directum.crt -noout -hash 2>/dev/null)
    ROOT_HASH=$(openssl x509 -in $(basename $ROOT_CERT) -noout -hash 2>/dev/null)
    
    ln -sf directum.crt ${DIRECTUM_HASH}.0
    ln -sf $(basename $ROOT_CERT) ${ROOT_HASH}.0
    
    echo ""
    echo "✓ Созданы символические ссылки:"
    echo "  ${DIRECTUM_HASH}.0 -> directum.crt"
    echo "  ${ROOT_HASH}.0 -> $(basename $ROOT_CERT)"
    
    cd ..
    
    echo ""
    echo "=== Готово! ==="
    echo "Сертификаты настроены. Запустите: docker-compose up --build"
else
    echo "✗ ОШИБКА: Не удалось извлечь сертификат Directum"
    exit 1
fi
