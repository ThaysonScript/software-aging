# Use a imagem base do Debian com a tag bookworm-20231218
FROM debian:bookworm-20240311

# Atualize os pacotes e instale o servidor nginx e o procps
RUN apt-get update && \
    apt-get install -y nginx procps

# Expor a porta 80
EXPOSE 80

# Copiar o script entrypoint.sh para a pasta /root/ e definir permissões de execução
COPY ../entrypoint.sh /root/
RUN chmod a+wrx /root/entrypoint.sh

# Comando para iniciar o entrypoint.sh
CMD ["/root/entrypoint.sh"]
