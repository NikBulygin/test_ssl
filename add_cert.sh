#!/bin/bash

# Скрипт для добавления сертификата Directum в доверенные

echo "=== Добавление сертификата Directum в доверенные ==="

# Создаем директорию для сертификатов если её нет
mkdir -p ./certs

# Скачиваем сертификат с сервера Directum
echo "Скачиваем сертификат с сервера Directum..."
openssl s_client -connect directum.uktmp.kz:443 -showcerts < /dev/null 2>/dev/null | \
    sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > ./certs/directum.crt

# Скачиваем корневой CA сертификат
echo "Скачиваем корневой CA сертификат..."
openssl s_client -connect directum.uktmp.kz:443 -showcerts < /dev/null 2>/dev/null | \
    awk '/-----BEGIN CERTIFICATE-----/{flag=1} flag; /-----END CERTIFICATE-----/{flag=0}' | \
    tail -n +2 | \
    awk '/-----BEGIN CERTIFICATE-----/{flag=1} flag; /-----END CERTIFICATE-----/{flag=0}' > ./certs/root-ca.crt

# Создаем символические ссылки для Linux
echo "Создаем символические ссылки..."
cd ./certs

# Генерируем хеш для корневого CA
ROOT_HASH=$(openssl x509 -in root-ca.crt -noout -hash)
ln -sf root-ca.crt ${ROOT_HASH}.0

# Генерируем хеш для сертификата Directum
DIRECTUM_HASH=$(openssl x509 -in directum.crt -noout -hash)
ln -sf directum.crt ${DIRECTUM_HASH}.0

cd ..

echo "=== Сертификаты добавлены в ./certs/ ==="
echo "Корневой CA: ./certs/root-ca.crt"
echo "Directum: ./certs/directum.crt"
echo ""
echo "Теперь запустите: docker-compose up --build"
