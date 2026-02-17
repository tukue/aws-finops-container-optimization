import requests
import time
import random

# Sample prompts
prompts = [
    "Explain cloud cost optimization",
    "What are Kubernetes best practices?",
    "How to reduce AI costs?",
]

models = ["gpt-4", "gpt-3.5-turbo", "claude-haiku"]

print("Generating load to populate Grafana metrics...")
print("Sending 30 requests (10 per model)...\n")

for i in range(30):
    model = models[i % 3]
    prompt = prompts[i % 3]
    
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 100,
        "temperature": 0.7,
        "enable_cache": True if i > 15 else False
    }
    
    try:
        response = requests.post(
            "http://localhost:8080/v1/chat/completions",
            json=payload,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            cached = "✓ CACHED" if data.get("cached") else ""
            print(f"{i+1}. {model:20} Cost: ${data.get('estimated_cost', 0):.6f} {cached}")
        else:
            print(f"{i+1}. Error: {response.status_code}")
    except Exception as e:
        print(f"{i+1}. Exception: {e}")
    
    time.sleep(0.5)

print("\n✓ Load generation complete!")
print("Check Grafana at http://localhost:3000")
print("Default credentials: admin/admin")
