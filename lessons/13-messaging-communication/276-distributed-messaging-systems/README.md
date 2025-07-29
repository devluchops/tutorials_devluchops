# Messaging & Communication Systems

Complete guide to building scalable messaging systems, real-time communication, and distributed message processing with modern technologies like Kafka, RabbitMQ, Redis, WebSockets, and gRPC.

## What You'll Learn

- **Message Queues** - RabbitMQ, Apache Kafka, AWS SQS/SNS
- **Real-time Communication** - WebSockets, Server-Sent Events, Socket.IO
- **Pub/Sub Patterns** - Redis Pub/Sub, Event-driven architectures
- **gRPC & Protocol Buffers** - High-performance RPC communication
- **Message Processing** - Event sourcing, CQRS, stream processing
- **Monitoring & Observability** - Message tracking, performance metrics

## Apache Kafka Implementation

### **🔥 Kafka Producer & Consumer**
```python
# kafka/producer.py
from kafka import KafkaProducer
from kafka.errors import KafkaError
import json
import logging
import time
from datetime import datetime
from typing import Dict, Any, Optional

class EnhancedKafkaProducer:
    def __init__(self, bootstrap_servers: list, config: Dict[str, Any] = None):
        """
        Initialize enhanced Kafka producer with error handling and monitoring
        
        Args:
            bootstrap_servers: List of Kafka broker addresses
            config: Additional Kafka configuration
        """
        self.bootstrap_servers = bootstrap_servers
        self.config = config or {}
        
        # Default configuration
        default_config = {
            'value_serializer': lambda v: json.dumps(v).encode('utf-8'),
            'key_serializer': lambda k: str(k).encode('utf-8') if k else None,
            'acks': 'all',  # Wait for all replicas
            'retries': 5,
            'retry_backoff_ms': 100,
            'batch_size': 16384,
            'linger_ms': 5,  # Small delay for batching
            'compression_type': 'gzip',
            'max_in_flight_requests_per_connection': 5,
            'enable_idempotence': True
        }
        
        # Merge configurations
        self.config = {**default_config, **self.config}
        
        # Initialize producer
        self.producer = None
        self.connect()
        
        # Metrics
        self.metrics = {
            'messages_sent': 0,
            'messages_failed': 0,
            'total_bytes_sent': 0,
            'last_send_time': None
        }
        
        # Setup logging
        self.logger = logging.getLogger(__name__)
        logging.basicConfig(level=logging.INFO)
    
    def connect(self):
        """Connect to Kafka cluster"""
        try:
            self.producer = KafkaProducer(
                bootstrap_servers=self.bootstrap_servers,
                **self.config
            )
            self.logger.info(f"Connected to Kafka: {self.bootstrap_servers}")
        except Exception as e:
            self.logger.error(f"Failed to connect to Kafka: {e}")
            raise
    
    def send_message(self, topic: str, message: Dict[str, Any], 
                    key: Optional[str] = None, partition: Optional[int] = None) -> bool:
        """
        Send message to Kafka topic with error handling
        
        Args:
            topic: Kafka topic name
            message: Message payload (will be JSON serialized)
            key: Message key for partitioning
            partition: Specific partition (optional)
            
        Returns:
            bool: True if message was sent successfully
        """
        try:
            # Add metadata to message
            enhanced_message = {
                **message,
                'timestamp': datetime.utcnow().isoformat(),
                'producer_id': 'enhanced-producer',
                'message_id': f"{int(time.time() * 1000)}-{hash(str(message))}"
            }
            
            # Send message
            future = self.producer.send(
                topic=topic,
                value=enhanced_message,
                key=key,
                partition=partition
            )
            
            # Wait for confirmation
            record_metadata = future.get(timeout=10)
            
            # Update metrics
            self.metrics['messages_sent'] += 1
            self.metrics['total_bytes_sent'] += len(json.dumps(enhanced_message))
            self.metrics['last_send_time'] = datetime.utcnow()
            
            self.logger.info(
                f"Message sent to {topic}:{record_metadata.partition} "
                f"at offset {record_metadata.offset}"
            )
            
            return True
            
        except KafkaError as e:
            self.metrics['messages_failed'] += 1
            self.logger.error(f"Failed to send message to {topic}: {e}")
            return False
        except Exception as e:
            self.metrics['messages_failed'] += 1
            self.logger.error(f"Unexpected error sending message: {e}")
            return False
    
    def send_batch(self, topic: str, messages: list, keys: list = None) -> Dict[str, int]:
        """
        Send multiple messages in batch
        
        Args:
            topic: Kafka topic name
            messages: List of message payloads
            keys: List of keys (optional)
            
        Returns:
            Dict with success and failure counts
        """
        if keys and len(keys) != len(messages):
            raise ValueError("Keys list must have same length as messages list")
        
        results = {'success': 0, 'failed': 0}
        
        for i, message in enumerate(messages):
            key = keys[i] if keys else None
            if self.send_message(topic, message, key):
                results['success'] += 1
            else:
                results['failed'] += 1
        
        self.logger.info(f"Batch send completed: {results}")
        return results
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get producer metrics"""
        return {
            **self.metrics,
            'success_rate': (
                self.metrics['messages_sent'] / 
                (self.metrics['messages_sent'] + self.metrics['messages_failed'])
                if (self.metrics['messages_sent'] + self.metrics['messages_failed']) > 0 
                else 0
            ) * 100
        }
    
    def close(self):
        """Close producer connection"""
        if self.producer:
            self.producer.close()
            self.logger.info("Kafka producer closed")

# kafka/consumer.py
from kafka import KafkaConsumer
from kafka.errors import KafkaError
import json
import logging
import time
from typing import Dict, Any, Callable, Optional
from concurrent.futures import ThreadPoolExecutor
import threading

class EnhancedKafkaConsumer:
    def __init__(self, topics: list, bootstrap_servers: list, 
                 group_id: str, config: Dict[str, Any] = None):
        """
        Initialize enhanced Kafka consumer
        
        Args:
            topics: List of topics to subscribe to
            bootstrap_servers: List of Kafka broker addresses
            group_id: Consumer group ID
            config: Additional Kafka configuration
        """
        self.topics = topics
        self.bootstrap_servers = bootstrap_servers
        self.group_id = group_id
        self.config = config or {}
        
        # Default configuration
        default_config = {
            'value_deserializer': lambda m: json.loads(m.decode('utf-8')),
            'key_deserializer': lambda k: k.decode('utf-8') if k else None,
            'auto_offset_reset': 'latest',
            'enable_auto_commit': False,  # Manual commit for better control
            'max_poll_records': 500,
            'session_timeout_ms': 30000,
            'heartbeat_interval_ms': 3000,
            'fetch_max_wait_ms': 500
        }
        
        # Merge configurations
        self.config = {**default_config, **self.config}
        
        # Initialize consumer
        self.consumer = None
        self.message_handlers = {}
        self.running = False
        
        # Metrics
        self.metrics = {
            'messages_processed': 0,
            'messages_failed': 0,
            'total_processing_time': 0,
            'last_message_time': None
        }
        
        # Threading
        self.executor = ThreadPoolExecutor(max_workers=10)
        self.processing_lock = threading.Lock()
        
        # Setup logging
        self.logger = logging.getLogger(__name__)
        logging.basicConfig(level=logging.INFO)
    
    def connect(self):
        """Connect to Kafka cluster"""
        try:
            self.consumer = KafkaConsumer(
                *self.topics,
                bootstrap_servers=self.bootstrap_servers,
                group_id=self.group_id,
                **self.config
            )
            self.logger.info(f"Connected to Kafka: {self.bootstrap_servers}")
            self.logger.info(f"Subscribed to topics: {self.topics}")
        except Exception as e:
            self.logger.error(f"Failed to connect to Kafka: {e}")
            raise
    
    def add_handler(self, topic: str, handler: Callable[[Dict[str, Any]], bool]):
        """
        Add message handler for specific topic
        
        Args:
            topic: Topic name
            handler: Function that processes messages (should return True on success)
        """
        self.message_handlers[topic] = handler
        self.logger.info(f"Added handler for topic: {topic}")
    
    def process_message(self, message) -> bool:
        """
        Process individual message
        
        Args:
            message: Kafka message object
            
        Returns:
            bool: True if message was processed successfully
        """
        try:
            start_time = time.time()
            
            # Get handler for topic
            handler = self.message_handlers.get(message.topic)
            if not handler:
                self.logger.warning(f"No handler found for topic: {message.topic}")
                return True  # Consider it processed to avoid infinite retry
            
            # Process message
            success = handler(message.value)
            
            # Update metrics
            processing_time = time.time() - start_time
            with self.processing_lock:
                if success:
                    self.metrics['messages_processed'] += 1
                else:
                    self.metrics['messages_failed'] += 1
                
                self.metrics['total_processing_time'] += processing_time
                self.metrics['last_message_time'] = time.time()
            
            self.logger.debug(
                f"Processed message from {message.topic}:{message.partition} "
                f"offset {message.offset} in {processing_time:.3f}s"
            )
            
            return success
            
        except Exception as e:
            self.logger.error(f"Error processing message: {e}")
            with self.processing_lock:
                self.metrics['messages_failed'] += 1
            return False
    
    def start_consuming(self, async_processing: bool = True):
        """
        Start consuming messages
        
        Args:
            async_processing: Whether to process messages asynchronously
        """
        if not self.consumer:
            self.connect()
        
        self.running = True
        self.logger.info("Starting message consumption...")
        
        try:
            while self.running:
                # Poll for messages
                message_batch = self.consumer.poll(timeout_ms=1000)
                
                if not message_batch:
                    continue
                
                # Process messages
                for topic_partition, messages in message_batch.items():
                    for message in messages:
                        if async_processing:
                            # Process asynchronously
                            future = self.executor.submit(self.process_message, message)
                            # Note: In production, you'd want to handle futures properly
                        else:
                            # Process synchronously
                            self.process_message(message)
                
                # Commit offsets manually
                try:
                    self.consumer.commit()
                except Exception as e:
                    self.logger.error(f"Failed to commit offsets: {e}")
                
        except KeyboardInterrupt:
            self.logger.info("Received interrupt signal")
        except Exception as e:
            self.logger.error(f"Error in consumption loop: {e}")
        finally:
            self.stop_consuming()
    
    def stop_consuming(self):
        """Stop consuming messages"""
        self.running = False
        
        if self.consumer:
            self.consumer.close()
            self.logger.info("Kafka consumer closed")
        
        self.executor.shutdown(wait=True)
        self.logger.info("Message processing stopped")
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get consumer metrics"""
        with self.processing_lock:
            total_messages = self.metrics['messages_processed'] + self.metrics['messages_failed']
            avg_processing_time = (
                self.metrics['total_processing_time'] / self.metrics['messages_processed']
                if self.metrics['messages_processed'] > 0 else 0
            )
            
            return {
                **self.metrics,
                'success_rate': (
                    self.metrics['messages_processed'] / total_messages
                    if total_messages > 0 else 0
                ) * 100,
                'average_processing_time': avg_processing_time,
                'messages_per_second': (
                    self.metrics['messages_processed'] / 
                    (time.time() - (self.metrics['last_message_time'] or time.time()))
                    if self.metrics['last_message_time'] else 0
                )
            }

# Example usage and message handlers
def order_handler(message: Dict[str, Any]) -> bool:
    """Handle order messages"""
    try:
        order_id = message.get('order_id')
        customer_id = message.get('customer_id')
        amount = message.get('amount')
        
        # Simulate order processing
        print(f"Processing order {order_id} for customer {customer_id}: ${amount}")
        
        # Simulate some processing time
        time.sleep(0.1)
        
        # Simulate occasional failures
        import random
        if random.random() < 0.05:  # 5% failure rate
            raise Exception("Simulated processing error")
        
        print(f"Order {order_id} processed successfully")
        return True
        
    except Exception as e:
        print(f"Failed to process order: {e}")
        return False

def notification_handler(message: Dict[str, Any]) -> bool:
    """Handle notification messages"""
    try:
        user_id = message.get('user_id')
        notification_type = message.get('type')
        content = message.get('content')
        
        print(f"Sending {notification_type} notification to user {user_id}: {content}")
        
        # Simulate notification sending
        time.sleep(0.05)
        
        return True
        
    except Exception as e:
        print(f"Failed to send notification: {e}")
        return False

# Example implementation
if __name__ == "__main__":
    # Configuration
    KAFKA_SERVERS = ['localhost:9092']
    
    # Producer example
    producer = EnhancedKafkaProducer(KAFKA_SERVERS)
    
    # Send some test messages
    for i in range(10):
        order_message = {
            'order_id': f'order_{i}',
            'customer_id': f'customer_{i % 3}',
            'amount': 100.0 + i,
            'items': ['item1', 'item2']
        }
        producer.send_message('orders', order_message, key=f'customer_{i % 3}')
    
    print("Producer metrics:", producer.get_metrics())
    producer.close()
    
    # Consumer example
    consumer = EnhancedKafkaConsumer(
        topics=['orders', 'notifications'],
        bootstrap_servers=KAFKA_SERVERS,
        group_id='order-processing-group'
    )
    
    # Add handlers
    consumer.add_handler('orders', order_handler)
    consumer.add_handler('notifications', notification_handler)
    
    # Start consuming (this will run until interrupted)
    try:
        consumer.start_consuming()
    except KeyboardInterrupt:
        print("Shutting down consumer...")
        print("Final metrics:", consumer.get_metrics())
```

## RabbitMQ Implementation

### **🐰 RabbitMQ Publisher & Consumer**
```python
# rabbitmq/connection_manager.py
import pika
import json
import logging
import time
import threading
from typing import Dict, Any, Callable, Optional
from datetime import datetime
import uuid

class RabbitMQConnectionManager:
    def __init__(self, connection_params: Dict[str, Any]):
        """
        Initialize RabbitMQ connection manager
        
        Args:
            connection_params: Connection parameters for RabbitMQ
        """
        self.connection_params = connection_params
        self.connection = None
        self.channel = None
        self.is_connected = False
        self.lock = threading.Lock()
        
        # Setup logging
        self.logger = logging.getLogger(__name__)
        logging.basicConfig(level=logging.INFO)
    
    def connect(self):
        """Establish connection to RabbitMQ"""
        try:
            with self.lock:
                if self.is_connected:
                    return
                
                # Create connection
                credentials = pika.PlainCredentials(
                    self.connection_params.get('username', 'guest'),
                    self.connection_params.get('password', 'guest')
                )
                
                parameters = pika.ConnectionParameters(
                    host=self.connection_params.get('host', 'localhost'),
                    port=self.connection_params.get('port', 5672),
                    virtual_host=self.connection_params.get('virtual_host', '/'),
                    credentials=credentials,
                    heartbeat=600,
                    blocked_connection_timeout=300
                )
                
                self.connection = pika.BlockingConnection(parameters)
                self.channel = self.connection.channel()
                self.is_connected = True
                
                self.logger.info("Connected to RabbitMQ")
                
        except Exception as e:
            self.logger.error(f"Failed to connect to RabbitMQ: {e}")
            raise
    
    def disconnect(self):
        """Close connection to RabbitMQ"""
        try:
            with self.lock:
                if self.connection and not self.connection.is_closed:
                    self.connection.close()
                self.is_connected = False
                self.logger.info("Disconnected from RabbitMQ")
        except Exception as e:
            self.logger.error(f"Error disconnecting from RabbitMQ: {e}")
    
    def ensure_connection(self):
        """Ensure connection is active"""
        if not self.is_connected or self.connection.is_closed:
            self.connect()

# rabbitmq/publisher.py
class RabbitMQPublisher:
    def __init__(self, connection_manager: RabbitMQConnectionManager):
        """
        Initialize RabbitMQ publisher
        
        Args:
            connection_manager: RabbitMQ connection manager
        """
        self.connection_manager = connection_manager
        self.logger = logging.getLogger(__name__)
        
        # Metrics
        self.metrics = {
            'messages_published': 0,
            'messages_failed': 0,
            'bytes_published': 0,
            'last_publish_time': None
        }
    
    def declare_exchange(self, exchange_name: str, exchange_type: str = 'direct',
                        durable: bool = True):
        """
        Declare an exchange
        
        Args:
            exchange_name: Name of the exchange
            exchange_type: Type of exchange (direct, topic, fanout, headers)
            durable: Whether exchange survives server restart
        """
        self.connection_manager.ensure_connection()
        self.connection_manager.channel.exchange_declare(
            exchange=exchange_name,
            exchange_type=exchange_type,
            durable=durable
        )
        self.logger.info(f"Declared exchange: {exchange_name} ({exchange_type})")
    
    def declare_queue(self, queue_name: str, durable: bool = True,
                     exclusive: bool = False, auto_delete: bool = False,
                     arguments: Dict[str, Any] = None):
        """
        Declare a queue
        
        Args:
            queue_name: Name of the queue
            durable: Whether queue survives server restart
            exclusive: Whether queue is exclusive to this connection
            auto_delete: Whether queue is deleted when last consumer disconnects
            arguments: Additional queue arguments
        """
        self.connection_manager.ensure_connection()
        self.connection_manager.channel.queue_declare(
            queue=queue_name,
            durable=durable,
            exclusive=exclusive,
            auto_delete=auto_delete,
            arguments=arguments or {}
        )
        self.logger.info(f"Declared queue: {queue_name}")
    
    def bind_queue(self, queue_name: str, exchange_name: str, routing_key: str = ''):
        """
        Bind queue to exchange
        
        Args:
            queue_name: Name of the queue
            exchange_name: Name of the exchange
            routing_key: Routing key for binding
        """
        self.connection_manager.ensure_connection()
        self.connection_manager.channel.queue_bind(
            exchange=exchange_name,
            queue=queue_name,
            routing_key=routing_key
        )
        self.logger.info(f"Bound queue {queue_name} to exchange {exchange_name} with key {routing_key}")
    
    def publish_message(self, exchange: str, routing_key: str, message: Dict[str, Any],
                       properties: pika.BasicProperties = None) -> bool:
        """
        Publish message to exchange
        
        Args:
            exchange: Exchange name
            routing_key: Routing key
            message: Message payload
            properties: Message properties
            
        Returns:
            bool: True if message was published successfully
        """
        try:
            self.connection_manager.ensure_connection()
            
            # Add metadata to message
            enhanced_message = {
                **message,
                'timestamp': datetime.utcnow().isoformat(),
                'message_id': str(uuid.uuid4()),
                'publisher_id': 'enhanced-publisher'
            }
            
            # Default properties
            if not properties:
                properties = pika.BasicProperties(
                    delivery_mode=2,  # Persistent message
                    timestamp=int(time.time()),
                    message_id=enhanced_message['message_id'],
                    content_type='application/json'
                )
            
            # Serialize message
            message_body = json.dumps(enhanced_message)
            
            # Publish message
            self.connection_manager.channel.basic_publish(
                exchange=exchange,
                routing_key=routing_key,
                body=message_body,
                properties=properties
            )
            
            # Update metrics
            self.metrics['messages_published'] += 1
            self.metrics['bytes_published'] += len(message_body)
            self.metrics['last_publish_time'] = datetime.utcnow()
            
            self.logger.debug(f"Published message to {exchange}/{routing_key}")
            return True
            
        except Exception as e:
            self.metrics['messages_failed'] += 1
            self.logger.error(f"Failed to publish message: {e}")
            return False
    
    def publish_batch(self, exchange: str, messages: list) -> Dict[str, int]:
        """
        Publish multiple messages in batch
        
        Args:
            exchange: Exchange name
            messages: List of (routing_key, message) tuples
            
        Returns:
            Dict with success and failure counts
        """
        results = {'success': 0, 'failed': 0}
        
        for routing_key, message in messages:
            if self.publish_message(exchange, routing_key, message):
                results['success'] += 1
            else:
                results['failed'] += 1
        
        self.logger.info(f"Batch publish completed: {results}")
        return results
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get publisher metrics"""
        total_messages = self.metrics['messages_published'] + self.metrics['messages_failed']
        return {
            **self.metrics,
            'success_rate': (
                self.metrics['messages_published'] / total_messages
                if total_messages > 0 else 0
            ) * 100
        }

# rabbitmq/consumer.py
class RabbitMQConsumer:
    def __init__(self, connection_manager: RabbitMQConnectionManager):
        """
        Initialize RabbitMQ consumer
        
        Args:
            connection_manager: RabbitMQ connection manager
        """
        self.connection_manager = connection_manager
        self.logger = logging.getLogger(__name__)
        self.message_handlers = {}
        self.consuming = False
        
        # Metrics
        self.metrics = {
            'messages_processed': 0,
            'messages_failed': 0,
            'messages_rejected': 0,
            'total_processing_time': 0,
            'last_message_time': None
        }
    
    def add_handler(self, queue_name: str, handler: Callable[[Dict[str, Any]], bool]):
        """
        Add message handler for specific queue
        
        Args:
            queue_name: Queue name
            handler: Function that processes messages
        """
        self.message_handlers[queue_name] = handler
        self.logger.info(f"Added handler for queue: {queue_name}")
    
    def process_message(self, channel, method, properties, body) -> None:
        """
        Process individual message
        
        Args:
            channel: Channel object
            method: Method frame
            properties: Message properties
            body: Message body
        """
        start_time = time.time()
        
        try:
            # Deserialize message
            message = json.loads(body.decode('utf-8'))
            
            # Get queue name from method
            queue_name = method.routing_key
            
            # Get handler
            handler = self.message_handlers.get(queue_name)
            if not handler:
                self.logger.warning(f"No handler found for queue: {queue_name}")
                channel.basic_ack(delivery_tag=method.delivery_tag)
                return
            
            # Process message
            success = handler(message)
            
            # Update metrics
            processing_time = time.time() - start_time
            self.metrics['total_processing_time'] += processing_time
            self.metrics['last_message_time'] = time.time()
            
            if success:
                # Acknowledge message
                channel.basic_ack(delivery_tag=method.delivery_tag)
                self.metrics['messages_processed'] += 1
                self.logger.debug(f"Processed message from {queue_name} in {processing_time:.3f}s")
            else:
                # Reject message (will be requeued)
                channel.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
                self.metrics['messages_failed'] += 1
                self.logger.error(f"Failed to process message from {queue_name}")
                
        except json.JSONDecodeError as e:
            # Reject malformed messages
            channel.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
            self.metrics['messages_rejected'] += 1
            self.logger.error(f"Invalid JSON message: {e}")
            
        except Exception as e:
            # Reject message on unexpected errors
            channel.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
            self.metrics['messages_failed'] += 1
            self.logger.error(f"Error processing message: {e}")
    
    def start_consuming(self, queue_name: str, prefetch_count: int = 10):
        """
        Start consuming messages from queue
        
        Args:
            queue_name: Queue name to consume from
            prefetch_count: Number of unacknowledged messages
        """
        self.connection_manager.ensure_connection()
        
        # Set QoS
        self.connection_manager.channel.basic_qos(prefetch_count=prefetch_count)
        
        # Set up consumer
        self.connection_manager.channel.basic_consume(
            queue=queue_name,
            on_message_callback=self.process_message
        )
        
        self.consuming = True
        self.logger.info(f"Started consuming from queue: {queue_name}")
        
        try:
            self.connection_manager.channel.start_consuming()
        except KeyboardInterrupt:
            self.logger.info("Received interrupt signal")
            self.stop_consuming()
    
    def stop_consuming(self):
        """Stop consuming messages"""
        if self.consuming:
            self.connection_manager.channel.stop_consuming()
            self.consuming = False
            self.logger.info("Stopped consuming messages")
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get consumer metrics"""
        total_messages = (
            self.metrics['messages_processed'] + 
            self.metrics['messages_failed'] + 
            self.metrics['messages_rejected']
        )
        
        avg_processing_time = (
            self.metrics['total_processing_time'] / self.metrics['messages_processed']
            if self.metrics['messages_processed'] > 0 else 0
        )
        
        return {
            **self.metrics,
            'success_rate': (
                self.metrics['messages_processed'] / total_messages
                if total_messages > 0 else 0
            ) * 100,
            'average_processing_time': avg_processing_time
        }

# Example usage
if __name__ == "__main__":
    # Connection configuration
    connection_params = {
        'host': 'localhost',
        'port': 5672,
        'username': 'guest',
        'password': 'guest',
        'virtual_host': '/'
    }
    
    # Initialize connection manager
    conn_manager = RabbitMQConnectionManager(connection_params)
    
    # Publisher example
    publisher = RabbitMQPublisher(conn_manager)
    
    # Declare exchange and queue
    publisher.declare_exchange('orders_exchange', 'direct')
    publisher.declare_queue('order_processing')
    publisher.bind_queue('order_processing', 'orders_exchange', 'new_order')
    
    # Publish some messages
    for i in range(10):
        order_message = {
            'order_id': f'order_{i}',
            'customer_id': f'customer_{i % 3}',
            'amount': 100.0 + i,
            'items': ['item1', 'item2']
        }
        publisher.publish_message('orders_exchange', 'new_order', order_message)
    
    print("Publisher metrics:", publisher.get_metrics())
    
    # Consumer example
    def order_processor(message: Dict[str, Any]) -> bool:
        """Process order messages"""
        try:
            order_id = message.get('order_id')
            print(f"Processing order: {order_id}")
            
            # Simulate processing time
            time.sleep(0.1)
            
            # Simulate occasional failures
            import random
            if random.random() < 0.1:  # 10% failure rate
                raise Exception("Simulated processing error")
            
            print(f"Order {order_id} processed successfully")
            return True
            
        except Exception as e:
            print(f"Failed to process order: {e}")
            return False
    
    consumer = RabbitMQConsumer(conn_manager)
    consumer.add_handler('order_processing', order_processor)
    
    try:
        consumer.start_consuming('order_processing')
    except KeyboardInterrupt:
        print("Final metrics:", consumer.get_metrics())
        conn_manager.disconnect()
```

## WebSocket Real-time Communication

### **⚡ WebSocket Server & Client**
```javascript
// websocket/server.js
const WebSocket = require('ws');
const http = require('http');
const express = require('express');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

class WebSocketServer {
  constructor(port = 8080, options = {}) {
    this.port = port;
    this.options = options;
    this.clients = new Map();
    this.rooms = new Map();
    this.messageHandlers = new Map();
    
    // Metrics
    this.metrics = {
      totalConnections: 0,
      activeConnections: 0,
      messagesSent: 0,
      messagesReceived: 0,
      bytesTransferred: 0,
      errors: 0
    };
    
    this.setupServer();
    this.setupWebSocket();
    this.setupMessageHandlers();
  }
  
  setupServer() {
    // Create Express app for serving static files
    this.app = express();
    this.app.use(express.static(path.join(__dirname, 'public')));
    
    // Create HTTP server
    this.server = http.createServer(this.app);
    
    // Health check endpoint
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        metrics: this.getMetrics(),
        uptime: process.uptime()
      });
    });
    
    // Metrics endpoint
    this.app.get('/metrics', (req, res) => {
      res.json(this.getMetrics());
    });
  }
  
  setupWebSocket() {
    this.wss = new WebSocket.Server({ 
      server: this.server,
      ...this.options 
    });
    
    this.wss.on('connection', (ws, req) => {
      this.handleConnection(ws, req);
    });
    
    // Heartbeat to detect broken connections
    this.heartbeatInterval = setInterval(() => {
      this.wss.clients.forEach((ws) => {
        if (ws.isAlive === false) {
          this.handleDisconnection(ws);
          return ws.terminate();
        }
        
        ws.isAlive = false;
        ws.ping();
      });
    }, 30000);
  }
  
  setupMessageHandlers() {
    // Register default message handlers
    this.addMessageHandler('join_room', this.handleJoinRoom.bind(this));
    this.addMessageHandler('leave_room', this.handleLeaveRoom.bind(this));
    this.addMessageHandler('broadcast', this.handleBroadcast.bind(this));
    this.addMessageHandler('private_message', this.handlePrivateMessage.bind(this));
    this.addMessageHandler('get_room_users', this.handleGetRoomUsers.bind(this));
  }
  
  handleConnection(ws, req) {
    const clientId = uuidv4();
    const clientInfo = {
      id: clientId,
      ws: ws,
      ip: req.socket.remoteAddress,
      userAgent: req.headers['user-agent'],
      connectedAt: new Date(),
      rooms: new Set(),
      isAlive: true
    };
    
    // Store client
    this.clients.set(clientId, clientInfo);
    ws.clientId = clientId;
    ws.isAlive = true;
    
    // Update metrics
    this.metrics.totalConnections++;
    this.metrics.activeConnections++;
    
    console.log(`Client connected: ${clientId} from ${clientInfo.ip}`);
    
    // Send welcome message
    this.sendToClient(clientId, {
      type: 'connection_established',
      clientId: clientId,
      timestamp: new Date().toISOString()
    });
    
    // Set up message handler
    ws.on('message', (data) => {
      this.handleMessage(clientId, data);
    });
    
    // Set up pong handler
    ws.on('pong', () => {
      ws.isAlive = true;
    });
    
    // Set up close handler
    ws.on('close', () => {
      this.handleDisconnection(ws);
    });
    
    // Set up error handler
    ws.on('error', (error) => {
      console.error(`WebSocket error for client ${clientId}:`, error);
      this.metrics.errors++;
    });
  }
  
  handleMessage(clientId, data) {
    try {
      const message = JSON.parse(data);
      this.metrics.messagesReceived++;
      this.metrics.bytesTransferred += data.length;
      
      console.log(`Message from ${clientId}:`, message);
      
      // Get message handler
      const handler = this.messageHandlers.get(message.type);
      if (handler) {
        handler(clientId, message);
      } else {
        console.warn(`No handler found for message type: ${message.type}`);
        this.sendError(clientId, `Unknown message type: ${message.type}`);
      }
      
    } catch (error) {
      console.error(`Error parsing message from ${clientId}:`, error);
      this.sendError(clientId, 'Invalid JSON message');
      this.metrics.errors++;
    }
  }
  
  handleDisconnection(ws) {
    const clientId = ws.clientId;
    const client = this.clients.get(clientId);
    
    if (client) {
      // Remove client from all rooms
      client.rooms.forEach(roomId => {
        this.removeClientFromRoom(clientId, roomId);
      });
      
      // Remove client
      this.clients.delete(clientId);
      this.metrics.activeConnections--;
      
      console.log(`Client disconnected: ${clientId}`);
    }
  }
  
  addMessageHandler(type, handler) {
    this.messageHandlers.set(type, handler);
  }
  
  sendToClient(clientId, message) {
    const client = this.clients.get(clientId);
    if (client && client.ws.readyState === WebSocket.OPEN) {
      const messageStr = JSON.stringify({
        ...message,
        timestamp: new Date().toISOString()
      });
      
      client.ws.send(messageStr);
      this.metrics.messagesSent++;
      this.metrics.bytesTransferred += messageStr.length;
      return true;
    }
    return false;
  }
  
  sendToRoom(roomId, message, excludeClientId = null) {
    const room = this.rooms.get(roomId);
    if (!room) return 0;
    
    let sentCount = 0;
    room.clients.forEach(clientId => {
      if (clientId !== excludeClientId) {
        if (this.sendToClient(clientId, message)) {
          sentCount++;
        }
      }
    });
    
    return sentCount;
  }
  
  broadcast(message, excludeClientId = null) {
    let sentCount = 0;
    this.clients.forEach((client, clientId) => {
      if (clientId !== excludeClientId) {
        if (this.sendToClient(clientId, message)) {
          sentCount++;
        }
      }
    });
    
    return sentCount;
  }
  
  sendError(clientId, error) {
    this.sendToClient(clientId, {
      type: 'error',
      error: error
    });
  }
  
  // Room management
  createRoom(roomId, metadata = {}) {
    if (!this.rooms.has(roomId)) {
      this.rooms.set(roomId, {
        id: roomId,
        clients: new Set(),
        createdAt: new Date(),
        metadata: metadata
      });
      return true;
    }
    return false;
  }
  
  addClientToRoom(clientId, roomId) {
    const client = this.clients.get(clientId);
    if (!client) return false;
    
    // Create room if it doesn't exist
    this.createRoom(roomId);
    
    const room = this.rooms.get(roomId);
    room.clients.add(clientId);
    client.rooms.add(roomId);
    
    return true;
  }
  
  removeClientFromRoom(clientId, roomId) {
    const client = this.clients.get(clientId);
    const room = this.rooms.get(roomId);
    
    if (client && room) {
      room.clients.delete(clientId);
      client.rooms.delete(roomId);
      
      // Remove empty rooms
      if (room.clients.size === 0) {
        this.rooms.delete(roomId);
      }
      
      return true;
    }
    return false;
  }
  
  // Message handlers
  handleJoinRoom(clientId, message) {
    const { roomId, metadata = {} } = message;
    
    if (this.addClientToRoom(clientId, roomId)) {
      // Notify client
      this.sendToClient(clientId, {
        type: 'room_joined',
        roomId: roomId,
        success: true
      });
      
      // Notify other room members
      this.sendToRoom(roomId, {
        type: 'user_joined',
        clientId: clientId,
        roomId: roomId,
        metadata: metadata
      }, clientId);
      
      console.log(`Client ${clientId} joined room ${roomId}`);
    } else {
      this.sendError(clientId, 'Failed to join room');
    }
  }
  
  handleLeaveRoom(clientId, message) {
    const { roomId } = message;
    
    if (this.removeClientFromRoom(clientId, roomId)) {
      // Notify client
      this.sendToClient(clientId, {
        type: 'room_left',
        roomId: roomId,
        success: true
      });
      
      // Notify other room members
      this.sendToRoom(roomId, {
        type: 'user_left',
        clientId: clientId,
        roomId: roomId
      });
      
      console.log(`Client ${clientId} left room ${roomId}`);
    } else {
      this.sendError(clientId, 'Failed to leave room');
    }
  }
  
  handleBroadcast(clientId, message) {
    const { data } = message;
    
    const sentCount = this.broadcast({
      type: 'broadcast_message',
      fromClient: clientId,
      data: data
    }, clientId);
    
    this.sendToClient(clientId, {
      type: 'broadcast_sent',
      sentTo: sentCount
    });
  }
  
  handlePrivateMessage(clientId, message) {
    const { targetClientId, data } = message;
    
    if (this.sendToClient(targetClientId, {
      type: 'private_message',
      fromClient: clientId,
      data: data
    })) {
      this.sendToClient(clientId, {
        type: 'message_sent',
        success: true,
        targetClientId: targetClientId
      });
    } else {
      this.sendError(clientId, 'Failed to send private message');
    }
  }
  
  handleGetRoomUsers(clientId, message) {
    const { roomId } = message;
    const room = this.rooms.get(roomId);
    
    if (room) {
      const users = Array.from(room.clients).map(id => {
        const client = this.clients.get(id);
        return {
          clientId: id,
          connectedAt: client.connectedAt,
          ip: client.ip
        };
      });
      
      this.sendToClient(clientId, {
        type: 'room_users',
        roomId: roomId,
        users: users
      });
    } else {
      this.sendError(clientId, 'Room not found');
    }
  }
  
  getMetrics() {
    return {
      ...this.metrics,
      rooms: this.rooms.size,
      roomsInfo: Array.from(this.rooms.entries()).map(([id, room]) => ({
        id,
        clientCount: room.clients.size,
        createdAt: room.createdAt
      }))
    };
  }
  
  start() {
    this.server.listen(this.port, () => {
      console.log(`WebSocket server listening on port ${this.port}`);
      console.log(`Health check: http://localhost:${this.port}/health`);
      console.log(`Metrics: http://localhost:${this.port}/metrics`);
    });
  }
  
  stop() {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
    }
    
    this.wss.close(() => {
      this.server.close(() => {
        console.log('WebSocket server stopped');
      });
    });
  }
}

// Example usage
if (require.main === module) {
  const server = new WebSocketServer(8080);
  
  // Add custom message handler
  server.addMessageHandler('chat_message', (clientId, message) => {
    const { roomId, text } = message;
    
    server.sendToRoom(roomId, {
      type: 'chat_message',
      fromClient: clientId,
      text: text,
      timestamp: new Date().toISOString()
    });
  });
  
  server.start();
  
  // Graceful shutdown
  process.on('SIGINT', () => {
    console.log('Shutting down WebSocket server...');
    server.stop();
    process.exit(0);
  });
}

module.exports = WebSocketServer;
```

### **📱 WebSocket Client**
```html
<!-- public/index.html -->
<!DOCTYPE html>
<html>
<head>
    <title>WebSocket Chat Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .connected { background: #d4edda; color: #155724; }
        .disconnected { background: #f8d7da; color: #721c24; }
        .messages { border: 1px solid #ddd; height: 300px; overflow-y: auto; padding: 10px; margin: 10px 0; }
        .message { margin: 5px 0; padding: 5px; border-radius: 3px; }
        .message.own { background: #e3f2fd; text-align: right; }
        .message.other { background: #f5f5f5; }
        .controls { margin: 10px 0; }
        .controls input, .controls button { margin: 5px; padding: 8px; }
        .metrics { background: #f8f9fa; padding: 10px; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>WebSocket Chat Demo</h1>
        
        <div id="status" class="status disconnected">Disconnected</div>
        
        <div class="controls">
            <button id="connect">Connect</button>
            <button id="disconnect" disabled>Disconnect</button>
            <input type="text" id="roomId" placeholder="Room ID" value="general">
            <button id="joinRoom">Join Room</button>
            <button id="leaveRoom">Leave Room</button>
        </div>
        
        <div class="controls">
            <input type="text" id="messageInput" placeholder="Type a message..." style="width: 60%;">
            <button id="sendMessage">Send</button>
            <button id="getUsers">Get Room Users</button>
        </div>
        
        <div id="messages" class="messages"></div>
        
        <div id="metrics" class="metrics">
            <h3>Metrics</h3>
            <div id="metricsContent">Not connected</div>
        </div>
    </div>

    <script src="websocket-client.js"></script>
</body>
</html>
```

```javascript
// public/websocket-client.js
class WebSocketClient {
  constructor(url) {
    this.url = url;
    this.ws = null;
    this.clientId = null;
    this.currentRoom = null;
    this.messageHandlers = new Map();
    this.metrics = {
      messagesSent: 0,
      messagesReceived: 0,
      bytesTransferred: 0,
      reconnectAttempts: 0
    };
    
    this.setupMessageHandlers();
    this.setupUI();
  }
  
  setupMessageHandlers() {
    this.addMessageHandler('connection_established', this.handleConnectionEstablished.bind(this));
    this.addMessageHandler('room_joined', this.handleRoomJoined.bind(this));
    this.addMessageHandler('room_left', this.handleRoomLeft.bind(this));
    this.addMessageHandler('user_joined', this.handleUserJoined.bind(this));
    this.addMessageHandler('user_left', this.handleUserLeft.bind(this));
    this.addMessageHandler('chat_message', this.handleChatMessage.bind(this));
    this.addMessageHandler('room_users', this.handleRoomUsers.bind(this));
    this.addMessageHandler('error', this.handleError.bind(this));
  }
  
  setupUI() {
    // Get UI elements
    this.statusEl = document.getElementById('status');
    this.messagesEl = document.getElementById('messages');
    this.messageInput = document.getElementById('messageInput');
    this.roomIdInput = document.getElementById('roomId');
    this.metricsEl = document.getElementById('metricsContent');
    
    // Bind event listeners
    document.getElementById('connect').onclick = () => this.connect();
    document.getElementById('disconnect').onclick = () => this.disconnect();
    document.getElementById('joinRoom').onclick = () => this.joinRoom();
    document.getElementById('leaveRoom').onclick = () => this.leaveRoom();
    document.getElementById('sendMessage').onclick = () => this.sendMessage();
    document.getElementById('getUsers').onclick = () => this.getRoomUsers();
    
    // Enter key to send message
    this.messageInput.onkeypress = (e) => {
      if (e.key === 'Enter') {
        this.sendMessage();
      }
    };
    
    // Update metrics every second
    setInterval(() => this.updateMetrics(), 1000);
  }
  
  connect() {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.addMessage('Already connected', 'system');
      return;
    }
    
    try {
      this.ws = new WebSocket(this.url);
      
      this.ws.onopen = () => {
        this.updateStatus('Connected', true);
        this.addMessage('Connected to server', 'system');
        document.getElementById('connect').disabled = true;
        document.getElementById('disconnect').disabled = false;
      };
      
      this.ws.onmessage = (event) => {
        this.handleMessage(event.data);
      };
      
      this.ws.onclose = () => {
        this.updateStatus('Disconnected', false);
        this.addMessage('Disconnected from server', 'system');
        document.getElementById('connect').disabled = false;
        document.getElementById('disconnect').disabled = true;
        this.clientId = null;
        this.currentRoom = null;
      };
      
      this.ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        this.addMessage('Connection error', 'error');
      };
      
    } catch (error) {
      console.error('Failed to connect:', error);
      this.addMessage('Failed to connect: ' + error.message, 'error');
    }
  }
  
  disconnect() {
    if (this.ws) {
      this.ws.close();
    }
  }
  
  send(message) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      const messageStr = JSON.stringify(message);
      this.ws.send(messageStr);
      this.metrics.messagesSent++;
      this.metrics.bytesTransferred += messageStr.length;
      return true;
    }
    return false;
  }
  
  handleMessage(data) {
    try {
      const message = JSON.parse(data);
      this.metrics.messagesReceived++;
      this.metrics.bytesTransferred += data.length;
      
      console.log('Received message:', message);
      
      const handler = this.messageHandlers.get(message.type);
      if (handler) {
        handler(message);
      } else {
        console.warn('No handler for message type:', message.type);
      }
      
    } catch (error) {
      console.error('Error parsing message:', error);
    }
  }
  
  addMessageHandler(type, handler) {
    this.messageHandlers.set(type, handler);
  }
  
  // Message handlers
  handleConnectionEstablished(message) {
    this.clientId = message.clientId;
    this.addMessage(`Connected with ID: ${this.clientId}`, 'system');
  }
  
  handleRoomJoined(message) {
    this.currentRoom = message.roomId;
    this.addMessage(`Joined room: ${message.roomId}`, 'system');
  }
  
  handleRoomLeft(message) {
    this.addMessage(`Left room: ${message.roomId}`, 'system');
    if (this.currentRoom === message.roomId) {
      this.currentRoom = null;
    }
  }
  
  handleUserJoined(message) {
    this.addMessage(`User ${message.clientId} joined the room`, 'system');
  }
  
  handleUserLeft(message) {
    this.addMessage(`User ${message.clientId} left the room`, 'system');
  }
  
  handleChatMessage(message) {
    const isOwn = message.fromClient === this.clientId;
    const className = isOwn ? 'own' : 'other';
    const prefix = isOwn ? 'You' : message.fromClient;
    this.addMessage(`${prefix}: ${message.text}`, className);
  }
  
  handleRoomUsers(message) {
    const userList = message.users.map(u => u.clientId).join(', ');
    this.addMessage(`Users in room ${message.roomId}: ${userList}`, 'system');
  }
  
  handleError(message) {
    this.addMessage(`Error: ${message.error}`, 'error');
  }
  
  // UI actions
  joinRoom() {
    const roomId = this.roomIdInput.value.trim();
    if (!roomId) {
      this.addMessage('Please enter a room ID', 'error');
      return;
    }
    
    this.send({
      type: 'join_room',
      roomId: roomId
    });
  }
  
  leaveRoom() {
    if (!this.currentRoom) {
      this.addMessage('Not in any room', 'error');
      return;
    }
    
    this.send({
      type: 'leave_room',
      roomId: this.currentRoom
    });
  }
  
  sendMessage() {
    const text = this.messageInput.value.trim();
    if (!text) return;
    
    if (!this.currentRoom) {
      this.addMessage('Join a room first', 'error');
      return;
    }
    
    this.send({
      type: 'chat_message',
      roomId: this.currentRoom,
      text: text
    });
    
    this.messageInput.value = '';
  }
  
  getRoomUsers() {
    if (!this.currentRoom) {
      this.addMessage('Not in any room', 'error');
      return;
    }
    
    this.send({
      type: 'get_room_users',
      roomId: this.currentRoom
    });
  }
  
  // UI helpers
  updateStatus(status, connected) {
    this.statusEl.textContent = status;
    this.statusEl.className = `status ${connected ? 'connected' : 'disconnected'}`;
  }
  
  addMessage(text, type = 'message') {
    const messageEl = document.createElement('div');
    messageEl.className = `message ${type}`;
    messageEl.textContent = `[${new Date().toLocaleTimeString()}] ${text}`;
    
    this.messagesEl.appendChild(messageEl);
    this.messagesEl.scrollTop = this.messagesEl.scrollHeight;
  }
  
  updateMetrics() {
    this.metricsEl.innerHTML = `
      <strong>Client ID:</strong> ${this.clientId || 'Not connected'}<br>
      <strong>Current Room:</strong> ${this.currentRoom || 'None'}<br>
      <strong>Messages Sent:</strong> ${this.metrics.messagesSent}<br>
      <strong>Messages Received:</strong> ${this.metrics.messagesReceived}<br>
      <strong>Bytes Transferred:</strong> ${this.metrics.bytesTransferred}<br>
      <strong>Connection State:</strong> ${this.ws ? this.ws.readyState : 'Closed'}
    `;
  }
}

// Initialize WebSocket client
const wsUrl = `ws://${window.location.hostname}:${window.location.port || 8080}`;
const client = new WebSocketClient(wsUrl);

// Make client available globally for debugging
window.wsClient = client;
```

## Useful Links

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [RabbitMQ Tutorials](https://www.rabbitmq.com/getstarted.html)
- [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)
- [Redis Pub/Sub](https://redis.io/topics/pubsub)
- [gRPC Documentation](https://grpc.io/docs/)
