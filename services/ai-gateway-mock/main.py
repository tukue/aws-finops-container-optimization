import asyncio
import hashlib
import json
import time
from typing import Dict, Optional
from datetime import datetime, timedelta

import redis
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response

app = FastAPI(title="AI Gateway Mock", version="1.0.0")

# Redis for caching (optional, falls back to in-memory)
try:
    redis_client = redis.Redis(host='redis', port=6379, decode_responses=True)
    redis_client.ping()
    CACHE_ENABLED = True
except (redis.ConnectionError, redis.TimeoutError) as e:
    redis_client = None
    CACHE_ENABLED = False
    print(f"Redis not available, using in-memory cache: {e}")

# In-memory cache fallback
memory_cache = {}

# Prometheus metrics
token_counter = Counter('ai_tokens_total', 'Total tokens processed', ['type', 'model'])
cost_counter = Counter('ai_cost_total', 'Total estimated cost in USD', ['model'])
request_duration = Histogram('ai_request_duration_seconds', 'Request duration', ['model'])
cache_hits = Counter('ai_cache_hits_total', 'Cache hits')
cache_misses = Counter('ai_cache_misses_total', 'Cache misses')
active_requests = Gauge('ai_active_requests', 'Currently active requests')

# Model configurations
MODEL_CONFIGS = {
    "gpt-4": {
        "input_cost_per_1k": 0.03,
        "output_cost_per_1k": 0.06,
        "latency_base": 2.0,
        "tokens_per_second": 50
    },
    "gpt-3.5-turbo": {
        "input_cost_per_1k": 0.001,
        "output_cost_per_1k": 0.002,
        "latency_base": 0.5,
        "tokens_per_second": 100
    },
    "claude-haiku": {
        "input_cost_per_1k": 0.00025,
        "output_cost_per_1k": 0.00125,
        "latency_base": 0.3,
        "tokens_per_second": 120
    }
}

class ChatRequest(BaseModel):
    model: str = "gpt-4"
    messages: list
    max_tokens: Optional[int] = 150
    temperature: Optional[float] = 0.7
    enable_cache: Optional[bool] = True

class ChatResponse(BaseModel):
    id: str
    model: str
    usage: Dict[str, int]
    estimated_cost: float
    cached: bool
    response_text: str

def estimate_tokens(text: str) -> int:
    """Simple token estimation (roughly 4 chars per token)"""
    return max(1, len(text) // 4)

def generate_cache_key(request: ChatRequest) -> str:
    """Generate cache key from request"""
    content = json.dumps({
        "model": request.model,
        "messages": request.messages,
        "max_tokens": request.max_tokens,
        "temperature": request.temperature
    }, sort_keys=True)
    return hashlib.sha256(content.encode()).hexdigest()

def get_from_cache(key: str) -> Optional[dict]:
    """Get response from cache"""
    if CACHE_ENABLED and redis_client:
        try:
            cached = redis_client.get(key)
            return json.loads(cached) if cached else None
        except (redis.RedisError, json.JSONDecodeError) as e:
            print(f"Cache retrieval error: {e}")
    return memory_cache.get(key)

def set_cache(key: str, value: dict, ttl: int = 3600):
    """Set response in cache"""
    if CACHE_ENABLED and redis_client:
        try:
            redis_client.setex(key, ttl, json.dumps(value))
            return
        except (redis.RedisError, json.JSONEncodeError) as e:
            print(f"Cache storage error: {e}")
    memory_cache[key] = value

def simulate_ai_response(request: ChatRequest) -> str:
    """Generate a mock AI response"""
    responses = [
        "This is a simulated AI response for cost optimization demonstration.",
        "The AI gateway is successfully processing your request with token tracking.",
        "Cost optimization strategies include caching, model routing, and rate limiting.",
        "This mock response helps demonstrate FinOps principles for AI workloads.",
        "Kubernetes and AI cost optimization working together in this simulation."
    ]
    return responses[hash(str(request.messages)) % len(responses)]

@app.post("/v1/chat/completions", response_model=ChatResponse)
async def chat_completions(request: ChatRequest):
    active_requests.inc()
    start_time = time.time()
    
    try:
        # Validate model
        if request.model not in MODEL_CONFIGS:
            raise HTTPException(status_code=400, detail=f"Model {request.model} not supported")
        
        config = MODEL_CONFIGS[request.model]
        
        # Check cache if enabled
        cached_response = None
        if request.enable_cache:
            cache_key = generate_cache_key(request)
            cached_response = get_from_cache(cache_key)
            
            if cached_response:
                cache_hits.inc()
                return ChatResponse(**cached_response)
        
        cache_misses.inc()
        
        # Calculate input tokens
        input_text = " ".join([msg.get("content", "") for msg in request.messages])
        input_tokens = estimate_tokens(input_text)
        
        # Simulate processing time based on model
        processing_time = config["latency_base"] + (request.max_tokens / config["tokens_per_second"])
        await asyncio.sleep(min(processing_time, 5.0))  # Cap at 5 seconds for demo
        
        # Generate response
        response_text = simulate_ai_response(request)
        output_tokens = min(estimate_tokens(response_text), request.max_tokens)
        
        # Calculate costs
        input_cost = (input_tokens / 1000) * config["input_cost_per_1k"]
        output_cost = (output_tokens / 1000) * config["output_cost_per_1k"]
        total_cost = input_cost + output_cost
        
        # Update metrics
        token_counter.labels(type="input", model=request.model).inc(input_tokens)
        token_counter.labels(type="output", model=request.model).inc(output_tokens)
        cost_counter.labels(model=request.model).inc(total_cost)
        
        response_data = {
            "id": f"chatcmpl-{int(time.time())}",
            "model": request.model,
            "usage": {
                "prompt_tokens": input_tokens,
                "completion_tokens": output_tokens,
                "total_tokens": input_tokens + output_tokens
            },
            "estimated_cost": round(total_cost, 6),
            "cached": False,
            "response_text": response_text
        }
        
        # Cache the response
        if request.enable_cache:
            set_cache(cache_key, response_data)
        
        return ChatResponse(**response_data)
        
    finally:
        active_requests.dec()
        request_duration.labels(model=request.model).observe(time.time() - start_time)

@app.get("/health")
async def health_check():
    return {"status": "healthy", "cache_enabled": CACHE_ENABLED}

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.get("/stats")
async def get_stats():
    """Get current statistics"""
    return {
        "cache_enabled": CACHE_ENABLED,
        "supported_models": list(MODEL_CONFIGS.keys()),
        "cache_size": len(memory_cache) if not CACHE_ENABLED else "redis"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)