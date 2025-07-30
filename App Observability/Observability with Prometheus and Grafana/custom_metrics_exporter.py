#!/usr/bin/env python3

from prometheus_client import start_http_server, Counter, Histogram, Gauge
import time
import random
import threading

# Define custom metrics
login_attempts = Counter('security_login_attempts_total', 'Total login attempts', ['status'])
api_response_time = Histogram('security_api_response_seconds', 'API response time')
active_sessions = Gauge('security_active_sessions', 'Number of active user sessions')
failed_logins_per_ip = Counter('security_failed_logins_per_ip_total', 'Failed logins per IP', ['ip_address'])

def simulate_security_events():
    """Simulate various security events for monitoring"""
    while True:
        # Simulate login attempts
        if random.random() < 0.3:  # 30% chance of failed login
            login_attempts.labels(status='failed').inc()
            # Simulate failed login from random IP
            fake_ip = f"192.168.1.{random.randint(1, 254)}"
            failed_logins_per_ip.labels(ip_address=fake_ip).inc()
        else:
            login_attempts.labels(status='success').inc()
        
        # Simulate API response times
        response_time = random.uniform(0.1, 2.0)
        api_response_time.observe(response_time)
        
        # Simulate active sessions
        active_sessions.set(random.randint(10, 100))
        
        time.sleep(random.uniform(1, 5))

if __name__ == '__main__':
    # Start metrics server on port 8000
    start_http_server(8000)
    print("Custom security metrics exporter started on port 8000")
    
    # Start background thread for simulating events
    event_thread = threading.Thread(target=simulate_security_events)
    event_thread.daemon = True
    event_thread.start()
    
    # Keep the main thread alive
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Shutting down...")