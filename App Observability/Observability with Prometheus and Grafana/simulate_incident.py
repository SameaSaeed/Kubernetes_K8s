#!/usr/bin/env python3

import json
import time
import requests
import threading
from datetime import datetime

def simulate_brute_force_attack():
    """Simulate a brute force attack"""
    print("Simulating brute force attack...")
    
    target_ip = "192.168.1.100"
    
    # Generate multiple failed login attempts
    for i in range(15):
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "event_type": "login_attempt",
            "severity": "warning",
            "success": False,
            "user": f"admin",
            "ip_address": target_ip,
            "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        }
        
        with open("logs/security.log", "a") as f:
            f.write(json.dumps(log_entry) + "\n")
        
        time.sleep(0.5)
    
    print(f"Brute force simulation complete - {target_ip}")

def simulate_api_abuse():
    """Simulate API abuse/DDoS"""
    print("Simulating API abuse")