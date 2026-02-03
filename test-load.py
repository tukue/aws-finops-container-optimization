import requests
import time
import concurrent.futures
import statistics

def test_inference_api(base_url="http://localhost:8000"):
    """Load test the inference API"""
    
    def make_request():
        try:
            start = time.time()
            response = requests.post(
                f"{base_url}/predict",
                json={"text": "Test input for AI model"},
                timeout=5
            )
            end = time.time()
            return response.status_code == 200, end - start
        except:
            return False, 0
    
    print("Load testing inference API...")
    
    # Test with 10 concurrent requests
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(make_request) for _ in range(100)]
        results = [future.result() for future in futures]
    
    success_count = sum(1 for success, _ in results if success)
    response_times = [rt for success, rt in results if success]
    
    print(f"Success rate: {success_count}/100 ({success_count}%)")
    if response_times:
        print(f"Avg response time: {statistics.mean(response_times):.3f}s")
        print(f"95th percentile: {statistics.quantiles(response_times, n=20)[18]:.3f}s")
    
    return success_count >= 95  # 95% success rate required

def test_health_endpoints():
    """Test health endpoints"""
    try:
        response = requests.get("http://localhost:8000/health", timeout=5)
        return response.status_code == 200
    except:
        return False

if __name__ == "__main__":
    print("Starting service load tests...")
    
    if not test_health_endpoints():
        print("Health check failed!")
        exit(1)
    
    if not test_inference_api():
        print("Load test failed!")
        exit(1)
    
    print("All load tests passed!")