import pika

# Conecte-se ao RabbitMQ
connection = pika.BlockingConnection(
    pika.ConnectionParameters(host='localhost', port=5672)
)

# Crie um canal
channel = connection.channel()

# Declare uma fila
channel.queue_declare(queue='teste')

# Publique uma mensagem
channel.basic_publish(exchange='', routing_key='teste', body='Mensagem de teste')


# Consuma a mensagem
def callback(ch, method, properties, body):
    print(f"Mensagem recebida: {body}")


channel.basic_consume(queue='teste', on_message_callback=callback)

# Aguarde a recepção da mensagem
channel.start_consuming()

# Feche a conexão
connection.close()
