#!/bin/bash

# Função de monitoramento
monitor_service() {
  #Obter a data atual
  start=$(date +%s%N)

  #nginx pgrep -x "nginx"
  #redis pgrep -f "redis-server"
  #rabbitmq pgrep -f "rabbitmq-server"
  #postgres pgrep -f "/usr/lib/postgresql/15/bin/postgres -D /usr/local/pgsql/data -i"

  until pgrep -x "nginx" >/dev/null; do
    echo ""
  done

  # Calcular o tempo total e salvar no arquivo /root/log.txt
  end=$(date +%s%N)
  total=$((end - start))
  echo "$total" >/root/log.txt
}

# Chamar a função de monitoramento em segundo plano
monitor_service &

# RabbitMQ
#/usr/lib/rabbitmq/bin/rabbitmq-server

#nginx
nginx -g "daemon off;"

#Postgres
#if [ -z "$(ls -A /usr/local/pgsql/data)" ]; then
#  su - postgres -c "/usr/lib/postgresql/15/bin/initdb -D /usr/local/pgsql/data"
#  echo "host all all all trust" >> /usr/local/pgsql/data/pg_hba.conf
#  echo "listen_addresses='*'" >> /usr/local/pgsql/data/postgresql.conf
#fi
#
#su - postgres -c "/usr/lib/postgresql/15/bin/postgres -D /usr/local/pgsql/data -i"

# Redis
#redis-server --protected-mode no