#!/bin/bash

# Простой скрипт для извлечения сертификатов

echo "=== Извлечение сертификатов Directum ==="

# Создаем директорию
mkdir -p ./certs

# Извлекаем все сертификаты
echo "Извлекаем сертификаты с directum.uktmp.kz..."
openssl s_client -connect directum.uktmp.kz:443 -showcerts < /dev/null 2>/dev/null > ./certs/full_chain.pem

# Разделяем сертификаты
echo "Разделяем сертификаты..."

# Первый сертификат (серверный)
awk '/-----BEGIN CERTIFICATE-----/{flag=1} flag; /-----END CERTIFICATE-----/{if(flag) {print; exit}}' ./certs/full_chain.pem > ./certs/directum.crt

# Второй сертификат (промежуточный CA)
awk '/-----BEGIN CERTIFICATE-----/{count++; if(count==2) flag=1} flag; /-----END CERTIFICATE-----/{if(flag && count==2) {print; exit}}' ./certs/full_chain.pem > ./certs/intermediate.crt

# Третий сертификат (корневой CA)
awk '/-----BEGIN CERTIFICATE-----/{count++; if(count==3) flag=1} flag; /-----END CERTIFICATE-----/{if(flag && count==3) {print; exit}}' ./certs/full_chain.pem > ./certs/root-ca.crt

# Проверяем что получилось
echo ""
echo "=== Проверка извлеченных сертификатов ==="
echo "Directum сертификат:"
openssl x509 -in ./certs/directum.crt -noout -subject -issuer 2>/dev/null || echo "Ошибка чтения directum.crt"

echo ""
echo "Промежуточный CA:"
openssl x509 -in ./certs/intermediate.crt -noout -subject -issuer 2>/dev/null || echo "Ошибка чтения intermediate.crt"

echo ""
echo "Корневой CA:"
openssl x509 -in ./certs/root-ca.crt -noout -subject -issuer 2>/dev/null || echo "Ошибка чтения root-ca.crt"

echo ""
echo "=== Создание символических ссылок ==="
cd ./certs

# Создаем ссылки для корневого CA
if [ -s root-ca.crt ]; then
    ROOT_HASH=$(openssl x509 -in root-ca.crt -noout -hash)
    ln -sf root-ca.crt ${ROOT_HASH}.0
    echo "Создана ссылка: ${ROOT_HASH}.0 -> root-ca.crt"
fi

# Создаем ссылки для промежуточного CA
if [ -s intermediate.crt ]; then
    INTER_HASH=$(openssl x509 -in intermediate.crt -noout -hash)
    ln -sf intermediate.crt ${INTER_HASH}.0
    echo "Создана ссылка: ${INTER_HASH}.0 -> intermediate.crt"
fi

cd ..

echo ""
echo "=== Готово! ==="
echo "Сертификаты сохранены в ./certs/"
echo "Теперь запустите: docker-compose up --build"
