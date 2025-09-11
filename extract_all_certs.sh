#!/bin/bash

# Скрипт для извлечения ВСЕХ сертификатов из цепочки

echo "=== Извлечение ВСЕХ сертификатов из цепочки Directum ==="

# Создаем директорию
mkdir -p ./certs

# Извлекаем полную цепочку сертификатов
echo "Извлекаем полную цепочку сертификатов с directum.uktmp.kz..."
openssl s_client -connect directum.uktmp.kz:443 -showcerts < /dev/null 2>/dev/null > ./certs/full_chain.pem

# Считаем количество сертификатов
CERT_COUNT=$(grep -c "BEGIN CERTIFICATE" ./certs/full_chain.pem)
echo "Найдено сертификатов в цепочке: $CERT_COUNT"

# Извлекаем каждый сертификат отдельно
echo "Извлекаем каждый сертификат..."
for i in $(seq 1 $CERT_COUNT); do
    echo "Извлекаем сертификат #$i..."
    
    # Извлекаем i-й сертификат
    awk -v cert_num=$i '
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
    }' ./certs/full_chain.pem > ./certs/cert_${i}.crt
    
    # Проверяем что сертификат не пустой
    if [ -s ./certs/cert_${i}.crt ]; then
        echo "  Сертификат #$i извлечен успешно"
        # Показываем информацию о сертификате
        echo "  Subject: $(openssl x509 -in ./certs/cert_${i}.crt -noout -subject 2>/dev/null | sed 's/subject=//')"
        echo "  Issuer:  $(openssl x509 -in ./certs/cert_${i}.crt -noout -issuer 2>/dev/null | sed 's/issuer=//')"
        echo ""
    else
        echo "  ОШИБКА: Сертификат #$i пустой!"
    fi
done

# Создаем символические ссылки для всех сертификатов
echo "=== Создание символических ссылок ==="
cd ./certs

for i in $(seq 1 $CERT_COUNT); do
    if [ -s cert_${i}.crt ]; then
        # Генерируем хеш для сертификата
        HASH=$(openssl x509 -in cert_${i}.crt -noout -hash 2>/dev/null)
        if [ ! -z "$HASH" ]; then
            ln -sf cert_${i}.crt ${HASH}.0
            echo "Создана ссылка: ${HASH}.0 -> cert_${i}.crt"
        fi
    fi
done

cd ..

echo ""
echo "=== Создание объединенного файла всех сертификатов ==="
cat ./certs/cert_*.crt > ./certs/all_certs.crt
echo "Все сертификаты объединены в ./certs/all_certs.crt"

echo ""
echo "=== Готово! ==="
echo "Извлечено сертификатов: $CERT_COUNT"
echo "Файлы:"
ls -la ./certs/
echo ""
echo "Теперь запустите: docker-compose up --build"
