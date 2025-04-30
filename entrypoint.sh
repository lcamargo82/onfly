#!/bin/bash

set -e

echo "🚀 Iniciando entrypoint..."

echo "⏳ Aguardando o banco de dados estar disponível..."
until nc -z -v -w30 "$DB_HOST" "$DB_PORT"; do
    echo "⚠️  Aguardando conexão com o banco de dados..."
    sleep 1
done
echo "✅ Banco de dados disponível!"

echo "📦 Instalando dependências do Composer..."
composer install --no-interaction --no-dev --optimize-autoloader

echo "📜 Executando migrações do Laravel..."
php artisan migrate --no-interaction --force

echo "📄 Generating API documentation..."
php artisan l5-swagger:generate

echo "🚀 Iniciando o Apache..."
exec apache2-foreground
