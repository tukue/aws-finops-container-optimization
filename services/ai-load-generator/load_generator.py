import asyncio
import json
import random
import time
from datetime import datetime
from typing import List

import httpx

# Configuration
AI_GATEWAY_URL = "http://ai-gateway-service/v1/chat/completions"
LOAD_PATTERNS = {
    "unoptimized": {
        "requests_per_minute": 60,
        "cache_enabled": False,
        "model_distribution": {"gpt-4": 1.0},
        "duplicate_rate": 0.7  # 70% of requests are duplicates
    },
    "optimized": {
        "requests_per_minute": 60,
        "cache_enabled": True,
        "model_distribution": {"gpt-4": 0.3, "gpt-3.5-turbo": 0.5, "claude-haiku": 0.2},
        "duplicate_rate": 0.7  # Same duplicates, but cached
    }
}

# Sample prompts for simulation
SAMPLE_PROMPTS = [
    "Explain the benefits of cloud cost optimization",
    "What are the best practices for Kubernetes resource management?",
    "How can we reduce AI inference costs?",
    "Describe the principles of FinOps",
    "What is the difference between spot and on-demand instances?",
    "How do we implement auto-scaling for AI workloads?",
    "Explain container rightsizing strategies",
    "What are the cost implications of different AI models?",
    "How can caching reduce API costs?",
    "Describe multi-cloud cost optimization approaches"
]

class LoadGenerator:
    def __init__(self, pattern_name: str = "unoptimized"):
        self.pattern = LOAD_PATTERNS[pattern_name]
        self.client = httpx.AsyncClient(timeout=30.0)
        self.stats = {
            "requests_sent": 0,
            "responses_received": 0,
            "cache_hits": 0,
            "total_cost": 0.0,
            "errors": 0
        }
        
    async def generate_request(self) -> dict:
        """Generate a request based on the current pattern"""
        # Select model based on distribution
        models = list(self.pattern["model_distribution"].keys())
        weights = list(self.pattern["model_distribution"].values())
        model = random.choices(models, weights=weights)[0]
        
        # Select prompt (with duplicate rate)
        if random.random() < self.pattern["duplicate_rate"]:
            # Use one of the first 3 prompts for duplicates
            prompt = random.choice(SAMPLE_PROMPTS[:3])
        else:
            prompt = random.choice(SAMPLE_PROMPTS)
        
        return {
            "model": model,
            "messages": [
                {"role": "user", "content": prompt}
            ],
            "max_tokens": random.randint(50, 200),
            "temperature": 0.7,
            "enable_cache": self.pattern["cache_enabled"]
        }
    
    async def send_request(self, request_data: dict):
        """Send a single request to the AI gateway"""
        try:
            self.stats["requests_sent"] += 1
            
            response = await self.client.post(
                AI_GATEWAY_URL,
                json=request_data,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                data = response.json()
                self.stats["responses_received"] += 1
                self.stats["total_cost"] += data.get("estimated_cost", 0)
                
                if data.get("cached", False):
                    self.stats["cache_hits"] += 1
                    
                print(f"✓ {data['model']} - Cost: ${data['estimated_cost']:.6f} - Cached: {data['cached']}")
            else:
                self.stats["errors"] += 1
                print(f"✗ Error {response.status_code}: {response.text}")
                
        except Exception as e:
            self.stats["errors"] += 1
            print(f"✗ Exception: {str(e)}")
    
    async def run_load_pattern(self, duration_minutes: int = 60):
        """Run the load pattern for specified duration"""
        print(f"Starting load generation with pattern: {self.pattern}")
        print(f"Duration: {duration_minutes} minutes")
        
        start_time = time.time()
        end_time = start_time + (duration_minutes * 60)
        
        requests_per_second = self.pattern["requests_per_minute"] / 60
        interval = 1.0 / requests_per_second if requests_per_second > 0 else 1.0
        
        while time.time() < end_time:
            request_data = await self.generate_request()
            
            # Send request asynchronously
            asyncio.create_task(self.send_request(request_data))
            
            # Wait for next request
            await asyncio.sleep(interval)
            
            # Print stats every minute
            if self.stats["requests_sent"] % 60 == 0:
                await self.print_stats()
        
        # Final stats
        await self.print_stats()
        await self.client.aclose()
    
    async def print_stats(self):
        """Print current statistics"""
        cache_hit_rate = (self.stats["cache_hits"] / max(self.stats["responses_received"], 1)) * 100
        error_rate = (self.stats["errors"] / max(self.stats["requests_sent"], 1)) * 100
        
        print(f"\n--- Stats at {datetime.now().strftime('%H:%M:%S')} ---")
        print(f"Requests sent: {self.stats['requests_sent']}")
        print(f"Responses received: {self.stats['responses_received']}")
        print(f"Cache hit rate: {cache_hit_rate:.1f}%")
        print(f"Total estimated cost: ${self.stats['total_cost']:.4f}")
        print(f"Error rate: {error_rate:.1f}%")
        print("-" * 40)

async def main():
    import os
    import sys
    
    # Get pattern from environment or command line
    pattern = os.getenv("LOAD_PATTERN", "unoptimized")
    duration = int(os.getenv("DURATION_MINUTES", "60"))
    
    if len(sys.argv) > 1:
        pattern = sys.argv[1]
    if len(sys.argv) > 2:
        duration = int(sys.argv[2])
    
    if pattern not in LOAD_PATTERNS:
        print(f"Invalid pattern. Choose from: {list(LOAD_PATTERNS.keys())}")
        return
    
    generator = LoadGenerator(pattern)
    await generator.run_load_pattern(duration)

if __name__ == "__main__":
    asyncio.run(main())