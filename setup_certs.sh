#!/bin/bash

echo "=== Настройка сертификатов Directum ==="

# Очищаем и создаем папку
rm -rf ./certs/*
mkdir -p ./certs

# Извлекаем сертификат из certs.txt
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
    echo "✓ Сертификат Directum извлечен"
    echo "Subject: $(openssl x509 -in ./certs/directum.crt -noout -subject 2>/dev/null | sed 's/subject=//')"
    echo "Issuer:  $(openssl x509 -in ./certs/directum.crt -noout -issuer 2>/dev/null | sed 's/issuer=//')"
    
    # Пробуем получить корневой CA сертификат
    echo ""
    echo "Пытаемся получить корневой CA сертификат..."
    
    # Скачиваем полную цепочку
    openssl s_client -connect directum.uktmp.kz:443 -showcerts < /dev/null 2>/dev/null > ./certs/full_chain.pem
    
    # Извлекаем все сертификаты
    awk '/-----BEGIN CERTIFICATE-----/{cert=""; flag=1} flag{cert=cert"\n"$0} /-----END CERTIFICATE-----/{if(flag) print cert; flag=0}' ./certs/full_chain.pem > ./certs/all_certs.pem
    
    # Считаем количество сертификатов
    CERT_COUNT=$(grep -c "BEGIN CERTIFICATE" ./certs/all_certs.pem)
    echo "Найдено сертификатов в цепочке: $CERT_COUNT"
    
    if [ $CERT_COUNT -gt 1 ]; then
        # Извлекаем последний сертификат (корневой CA)
        awk -v cert_num=$CERT_COUNT '
        /-----BEGIN CERTIFICATE-----/ { 
            count++; 
            if(count == cert_num) { 
                flag = 1; 
            } 
        } 
        flag; 
        /-----END CERTIFICATE-----/ { 
            if(flag && count == cert_num) { 
                print; 
                exit; 
            } 
        }' ./certs/all_certs.pem > ./certs/root-ca.crt
        
        echo "✓ Корневой CA извлечен"
        echo "Subject: $(openssl x509 -in ./certs/root-ca.crt -noout -subject 2>/dev/null | sed 's/subject=//')"
    else
        echo "⚠ В цепочке только один сертификат, используем его как корневой CA"
        cp ./certs/directum.crt ./certs/root-ca.crt
    fi
    
    # Создаем символические ссылки
    cd ./certs
    DIRECTUM_HASH=$(openssl x509 -in directum.crt -noout -hash 2>/dev/null)
    ROOT_HASH=$(openssl x509 -in root-ca.crt -noout -hash 2>/dev/null)
    
    ln -sf directum.crt ${DIRECTUM_HASH}.0
    ln -sf root-ca.crt ${ROOT_HASH}.0
    
    echo ""
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
