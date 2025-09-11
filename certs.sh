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
        echo "⚠ uktmp-root-ca.cer не найден"
        echo "Проблема: Directum выдан uktmp-SERVERCA-CA, но этого CA нет в доверенных"
        echo "Нужно получить корневой CA сертификат uktmp-SERVERCA-CA от администратора"
        echo "Используем копию Directum как временное решение (НЕ РЕКОМЕНДУЕТСЯ)"
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
    echo "=== Проверка SSL соединения ==="
    echo "Тестируем соединение с сертификатами..."
    
    # Проверяем соединение
    SSL_RESULT=$(openssl s_client -connect api.directum.uktmp.kz:443 -CAfile $ROOT_CERT < /dev/null 2>/dev/null)
    VERIFY_CODE=$(echo "$SSL_RESULT" | grep "Verify return code" | awk '{print $4}')
    
    echo "Verify return code: $VERIFY_CODE"
    
    if [ "$VERIFY_CODE" = "0" ]; then
        echo "✓ SSL соединение успешно! Сертификаты работают корректно"
    else
        echo "✗ ОШИБКА SSL: Verify return code = $VERIFY_CODE"
        echo ""
        echo "=== Детали ошибки ==="
        echo "$SSL_RESULT" | grep -E "(Verification error|unable to verify|unable to get local issuer)"
        
        echo ""
        echo "=== РЕШЕНИЕ ==="
        echo "1. Получите корневой CA сертификат uktmp-SERVERCA-CA от администратора домена"
        echo "2. Сохраните его как uktmp-root-ca.cer в корне проекта"
        echo "3. Запустите скрипт снова"
        echo ""
        echo "Или временно отключите проверку SSL в коде приложения"
    fi
    
    echo ""
    echo "=== Готово! ==="
    if [ "$VERIFY_CODE" = "0" ]; then
        echo "Сертификаты настроены корректно. Запустите: docker-compose up --build"
    else
        echo "Есть проблемы с сертификатами. Следуйте инструкциям выше."
    fi
else
    echo "✗ ОШИБКА: Не удалось извлечь сертификат Directum"
    exit 1
fi
