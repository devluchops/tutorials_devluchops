#!/usr/bin/env python3
# kafka/examples/kafka_example.py
"""
Complete Kafka example demonstrating producer and consumer patterns
"""

import asyncio
import json
import logging
import time
from datetime import datetime
from typing import Dict, Any
from kafka import KafkaProducer, KafkaConsumer
from kafka.errors import KafkaError
import threading
from concurrent.futures import ThreadPoolExecutor

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class EventProducer:
    """Enhanced Kafka producer for event streaming"""
    
    def __init__(self, bootstrap_servers=['localhost:9092']):
        self.bootstrap_servers = bootstrap_servers
        self.producer = None
        self.metrics = {
            'events_sent': 0,
            'events_failed': 0,
            'bytes_sent': 0
        }
        self.connect()
    
    def connect(self):
        """Connect to Kafka cluster"""
        try:
            self.producer = KafkaProducer(
                bootstrap_servers=self.bootstrap_servers,
                value_serializer=lambda v: json.dumps(v).encode('utf-8'),
                key_serializer=lambda k: str(k).encode('utf-8') if k else None,
                acks='all',
                retries=5,
                compression_type='gzip',
                enable_idempotence=True
            )
            logger.info("Connected to Kafka cluster")
        except Exception as e:
            logger.error(f"Failed to connect to Kafka: {e}")
            raise
    
    def send_event(self, topic: str, event_type: str, data: Dict[str, Any], 
                   partition_key: str = None) -> bool:
        """Send event to Kafka topic"""
        try:
            event = {
                'event_id': f"{int(time.time() * 1000)}-{hash(str(data))}",
                'event_type': event_type,
                'timestamp': datetime.utcnow().isoformat(),
                'data': data,
                'producer_id': 'event-producer',
                'version': '1.0'
            }
            
            future = self.producer.send(
                topic=topic,
                value=event,
                key=partition_key
            )
            
            # Wait for confirmation
            record_metadata = future.get(timeout=10)
            
            # Update metrics
            self.metrics['events_sent'] += 1
            self.metrics['bytes_sent'] += len(json.dumps(event))
            
            logger.info(
                f"Event {event['event_id']} sent to {topic}:{record_metadata.partition} "
                f"at offset {record_metadata.offset}"
            )
            return True
            
        except Exception as e:
            self.metrics['events_failed'] += 1
            logger.error(f"Failed to send event: {e}")
            return False
    
    def send_user_event(self, user_id: str, action: str, details: Dict[str, Any]):
        """Send user activity event"""
        return self.send_event(
            topic='user-events',
            event_type='user_activity',
            data={
                'user_id': user_id,
                'action': action,
                'details': details,
                'session_id': f"session_{int(time.time())}"
            },
            partition_key=user_id
        )
    
    def send_order_event(self, order_id: str, customer_id: str, 
                        event_type: str, order_data: Dict[str, Any]):
        """Send order processing event"""
        return self.send_event(
            topic='order-events',
            event_type=event_type,
            data={
                'order_id': order_id,
                'customer_id': customer_id,
                'order_data': order_data
            },
            partition_key=customer_id
        )
    
    def close(self):
        """Close producer connection"""
        if self.producer:
            self.producer.close()
            logger.info("Producer closed")

class EventConsumer:
    """Enhanced Kafka consumer for event processing"""
    
    def __init__(self, topics, group_id, bootstrap_servers=['localhost:9092']):
        self.topics = topics
        self.group_id = group_id
        self.bootstrap_servers = bootstrap_servers
        self.consumer = None
        self.running = False
        self.event_handlers = {}
        self.metrics = {
            'events_processed': 0,
            'events_failed': 0,
            'processing_time_total': 0
        }
        self.executor = ThreadPoolExecutor(max_workers=10)
    
    def connect(self):
        """Connect to Kafka cluster"""
        try:
            self.consumer = KafkaConsumer(
                *self.topics,
                bootstrap_servers=self.bootstrap_servers,
                group_id=self.group_id,
                value_deserializer=lambda m: json.loads(m.decode('utf-8')),
                key_deserializer=lambda k: k.decode('utf-8') if k else None,
                auto_offset_reset='latest',
                enable_auto_commit=False,
                max_poll_records=100,
                session_timeout_ms=30000
            )
            logger.info(f"Connected to Kafka cluster with group_id: {self.group_id}")
        except Exception as e:
            logger.error(f"Failed to connect to Kafka: {e}")
            raise
    
    def add_event_handler(self, event_type: str, handler):
        """Add handler for specific event type"""
        self.event_handlers[event_type] = handler
        logger.info(f"Added handler for event type: {event_type}")
    
    def process_event(self, event: Dict[str, Any]) -> bool:
        """Process individual event"""
        start_time = time.time()
        
        try:
            event_type = event.get('event_type')
            handler = self.event_handlers.get(event_type)
            
            if not handler:
                logger.warning(f"No handler found for event type: {event_type}")
                return True  # Consider it processed
            
            # Process event
            success = handler(event)
            
            # Update metrics
            processing_time = time.time() - start_time
            self.metrics['processing_time_total'] += processing_time
            
            if success:
                self.metrics['events_processed'] += 1
                logger.debug(f"Processed event {event.get('event_id')} in {processing_time:.3f}s")
            else:
                self.metrics['events_failed'] += 1
                logger.error(f"Failed to process event {event.get('event_id')}")
            
            return success
            
        except Exception as e:
            self.metrics['events_failed'] += 1
            logger.error(f"Error processing event: {e}")
            return False
    
    def start_consuming(self):
        """Start consuming events"""
        if not self.consumer:
            self.connect()
        
        self.running = True
        logger.info("Starting event consumption...")
        
        try:
            while self.running:
                message_batch = self.consumer.poll(timeout_ms=1000)
                
                if not message_batch:
                    continue
                
                for topic_partition, messages in message_batch.items():
                    for message in messages:
                        # Process event asynchronously
                        self.executor.submit(self.process_event, message.value)
                
                # Commit offsets
                try:
                    self.consumer.commit()
                except Exception as e:
                    logger.error(f"Failed to commit offsets: {e}")
                    
        except KeyboardInterrupt:
            logger.info("Received interrupt signal")
        except Exception as e:
            logger.error(f"Error in consumption loop: {e}")
        finally:
            self.stop_consuming()
    
    def stop_consuming(self):
        """Stop consuming events"""
        self.running = False
        if self.consumer:
            self.consumer.close()
        self.executor.shutdown(wait=True)
        logger.info("Event consumption stopped")

# Event handlers
def user_activity_handler(event: Dict[str, Any]) -> bool:
    """Handle user activity events"""
    try:
        data = event.get('data', {})
        user_id = data.get('user_id')
        action = data.get('action')
        
        logger.info(f"User {user_id} performed action: {action}")
        
        # Simulate processing (analytics, recommendations, etc.)
        time.sleep(0.1)
        
        return True
    except Exception as e:
        logger.error(f"Error handling user activity: {e}")
        return False

def order_processing_handler(event: Dict[str, Any]) -> bool:
    """Handle order processing events"""
    try:
        data = event.get('data', {})
        order_id = data.get('order_id')
        customer_id = data.get('customer_id')
        
        logger.info(f"Processing order {order_id} for customer {customer_id}")
        
        # Simulate order processing
        time.sleep(0.2)
        
        return True
    except Exception as e:
        logger.error(f"Error handling order: {e}")
        return False

# Example usage and testing
def simulate_user_activity(producer: EventProducer):
    """Simulate user activity events"""
    users = ['user_1', 'user_2', 'user_3', 'user_4', 'user_5']
    actions = ['login', 'view_product', 'add_to_cart', 'purchase', 'logout']
    
    for i in range(50):
        user_id = f"user_{i % len(users) + 1}"
        action = actions[i % len(actions)]
        
        producer.send_user_event(
            user_id=user_id,
            action=action,
            details={
                'page': f'/page_{i % 10}',
                'timestamp': time.time(),
                'user_agent': 'Mozilla/5.0...',
                'ip_address': f'192.168.1.{i % 255 + 1}'
            }
        )
        
        time.sleep(0.1)

def simulate_order_events(producer: EventProducer):
    """Simulate order processing events"""
    for i in range(20):
        order_id = f"order_{1000 + i}"
        customer_id = f"customer_{i % 5 + 1}"
        
        # Create order event
        producer.send_order_event(
            order_id=order_id,
            customer_id=customer_id,
            event_type='order_created',
            order_data={
                'items': [
                    {'product_id': f'product_{j}', 'quantity': j + 1, 'price': (j + 1) * 10.0}
                    for j in range(3)
                ],
                'total_amount': sum((j + 1) * 10.0 for j in range(3)),
                'shipping_address': f'Address {i + 1}',
                'payment_method': 'credit_card'
            }
        )
        
        time.sleep(0.5)
        
        # Process order event
        producer.send_order_event(
            order_id=order_id,
            customer_id=customer_id,
            event_type='order_processed',
            order_data={
                'status': 'processing',
                'estimated_delivery': '2024-01-15'
            }
        )
        
        time.sleep(0.2)

def main():
    """Main function to demonstrate Kafka event streaming"""
    
    # Initialize producer
    producer = EventProducer()
    
    # Initialize consumer
    consumer = EventConsumer(
        topics=['user-events', 'order-events'],
        group_id='event-processing-group'
    )
    
    # Add event handlers
    consumer.add_event_handler('user_activity', user_activity_handler)
    consumer.add_event_handler('order_created', order_processing_handler)
    consumer.add_event_handler('order_processed', order_processing_handler)
    
    # Start consumer in separate thread
    consumer_thread = threading.Thread(target=consumer.start_consuming)
    consumer_thread.daemon = True
    consumer_thread.start()
    
    try:
        # Wait a bit for consumer to start
        time.sleep(2)
        
        # Start producer threads
        user_thread = threading.Thread(target=simulate_user_activity, args=(producer,))
        order_thread = threading.Thread(target=simulate_order_events, args=(producer,))
        
        user_thread.start()
        order_thread.start()
        
        # Wait for producers to finish
        user_thread.join()
        order_thread.join()
        
        # Let consumer process remaining messages
        time.sleep(5)
        
        # Print metrics
        print("\nProducer Metrics:")
        print(f"Events sent: {producer.metrics['events_sent']}")
        print(f"Events failed: {producer.metrics['events_failed']}")
        print(f"Bytes sent: {producer.metrics['bytes_sent']}")
        
        print("\nConsumer Metrics:")
        print(f"Events processed: {consumer.metrics['events_processed']}")
        print(f"Events failed: {consumer.metrics['events_failed']}")
        print(f"Average processing time: {consumer.metrics['processing_time_total'] / max(consumer.metrics['events_processed'], 1):.3f}s")
        
    except KeyboardInterrupt:
        logger.info("Shutting down...")
    finally:
        producer.close()
        consumer.stop_consuming()

if __name__ == "__main__":
    main()
