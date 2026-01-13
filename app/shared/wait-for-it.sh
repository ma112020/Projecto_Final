#!/bin/sh

# wait-for-it.sh: Versão Universal (Compatível com Makefile e Docker)
# Espera que um host:porta esteja acessível antes de executar o comando.

# Lógica de Deteção de Argumentos
if echo "$1" | grep -q ":"; then
    # Caso Docker: host:porto num único argumento
    HOST=$(echo "$1" | cut -d: -f1)
    PORT=$(echo "$1" | cut -d: -f2)
    shift 1
else
    # Caso Local/Makefile: argumentos separados
    HOST=$1
    PORT=$2
    shift 2
fi

# O resto dos argumentos é o comando (ex: gunicorn...)
if [ "$1" = "--" ]; then
    shift
fi
CMD="$@"

echo "Aguardando $HOST:$PORT..."

# Verificação de segurança
if [ -z "$PORT" ]; then
    echo "Erro: Porto não detetado. Formato esperado: 'host:port' ou 'host port'"
    exit 1
fi

# Loop de verificação usando netcat
while ! nc -z "$HOST" "$PORT"; do
  sleep 1
done

echo "$HOST:$PORT disponível. A iniciar: $CMD"

# Executa o comando original (Gunicorn/Python)
exec $CMD