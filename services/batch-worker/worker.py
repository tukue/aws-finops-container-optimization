import os
import time
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BatchWorker:
    def __init__(self):
        self.worker_id = os.getenv('WORKER_ID', 'worker-1')
        self.batch_size = int(os.getenv('BATCH_SIZE', '32'))
        self.max_iterations = int(os.getenv('MAX_ITERATIONS', '100'))
        
    def process_batch(self, batch_id: int):
        """Simulate AI model training batch processing"""
        logger.info(f"Worker {self.worker_id} processing batch {batch_id}")
        
        # Simulate training work
        processing_time = 2 + (batch_id % 3)  # Variable processing time
        time.sleep(processing_time)
        
        metrics = {
            'batch_id': batch_id,
            'worker_id': self.worker_id,
            'processing_time': processing_time,
            'timestamp': datetime.now().isoformat(),
            'loss': 0.5 - (batch_id * 0.001),  # Simulated decreasing loss
            'accuracy': 0.7 + (batch_id * 0.002)  # Simulated increasing accuracy
        }
        
        logger.info(f"Batch {batch_id} completed: {metrics}")
        return metrics
    
    def run(self):
        """Main worker loop"""
        logger.info(f"Starting batch worker {self.worker_id}")
        
        for iteration in range(self.max_iterations):
            try:
                metrics = self.process_batch(iteration)
                
                # Simulate saving metrics to monitoring system
                if iteration % 10 == 0:
                    logger.info(f"Progress: {iteration}/{self.max_iterations} batches completed")
                    
            except Exception as e:
                logger.error(f"Error processing batch {iteration}: {e}")
                continue
        
        logger.info(f"Worker {self.worker_id} completed all {self.max_iterations} batches")

if __name__ == "__main__":
    worker = BatchWorker()
    worker.run()