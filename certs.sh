#!/bin/bash

echo "=== Настройка сертификатов Directum ==="

# Очищаем папку
rm -rf ./certs/*
mkdir -p ./certs

# Извлекаем сертификат Directum из certs.txt
echo "Извлекаем сертификат Directum из certs.txt..."
sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' certs.txt > ./certs/directum.crt

# Конвертируем все существующие сертификаты в .crt
echo "Конвертируем все сертификаты в формат .crt..."

# Конвертируем .cer файлы
for cer_file in *.cer; do
    if [ -f "$cer_file" ]; then
        crt_name=$(basename "$cer_file" .cer).crt
        cp "$cer_file" "./certs/$crt_name"
        echo "✓ Конвертирован $cer_file -> $crt_name"
    fi
done

# Конвертируем .pem файлы
for pem_file in *.pem; do
    if [ -f "$pem_file" ]; then
        crt_name=$(basename "$pem_file" .pem).crt
        cp "$pem_file" "./certs/$crt_name"
        echo "✓ Конвертирован $pem_file -> $crt_name"
    fi
done

# Проверяем что сертификат создан
if [ -s ./certs/directum.crt ]; then
    echo "✓ Сертификат Directum извлечен"
    
    # Ищем корневой CA сертификат среди всех .crt файлов
    ROOT_CERT=""
    for crt_file in ./certs/*.crt; do
        if [ -f "$crt_file" ] && [ "$(basename "$crt_file")" != "directum.crt" ]; then
            # Проверяем является ли это корневым CA
            SUBJECT=$(openssl x509 -in "$crt_file" -noout -subject 2>/dev/null | sed 's/subject=//')
            if echo "$SUBJECT" | grep -q "uktmp.*CA\|SERVERCA\|Root.*CA"; then
                ROOT_CERT="$crt_file"
                echo "✓ Найден корневой CA: $(basename "$crt_file")"
                break
            fi
        fi
    done
    
    if [ -z "$ROOT_CERT" ]; then
        echo "⚠ Корневой CA не найден среди .crt файлов"
        echo "Проблема: Directum выдан uktmp-SERVERCA-CA, но этого CA нет в доверенных"
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
    
    # Создаем символические ссылки для всех сертификатов
    echo ""
    echo "=== Регистрация всех сертификатов ==="
    cd ./certs
    
    # Регистрируем все .crt файлы
    for crt_file in *.crt; do
        if [ -f "$crt_file" ]; then
            HASH=$(openssl x509 -in "$crt_file" -noout -hash 2>/dev/null)
            if [ ! -z "$HASH" ]; then
                ln -sf "$crt_file" ${HASH}.0
                echo "✓ Зарегистрирован: ${HASH}.0 -> $crt_file"
            fi
        fi
    done
    
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
