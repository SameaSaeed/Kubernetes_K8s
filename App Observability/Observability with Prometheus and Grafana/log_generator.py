#!/usr/bin/env python3

import json
import time
import random
import datetime
from pathlib import Path

# Ensure logs directory exists
Path("logs").mkdir(exist_ok=True)

def generate_security_log():
    """Generate realistic security log entries"""
    
    log_types = [
        {
            "event_type": "login_attempt",
            "severity": "info",
            "success": random.choice([True, False]),
            "user": f"user{random.randint(1, 100)}",
            "ip_address": f"192.168.1.{random.randint(1, 254)}"
        },
        {
            "event_type": "api_access",
            "severity": "info",
            "endpoint": random.choice(["/api/v1/users", "/api/v1/data", "/api/v1/admin"]),
            "method": random.choice(["GET", "POST", "PUT", "DELETE"]),
            "status_code": random.choice([200, 401, 403, 404, 500]),
            "ip_address": f"10.0.0.{random.randint(1, 254)}"
        },
        {
            "event_type": "security_alert",
            "severity": random.choice(["warning", "critical"]),
            "alert_type": random.choice(["brute_force", "suspicious_activity", "privilege_escalation"]),
            "details": "Automated security alert triggered"
        }
    ]
    
    log_entry = random.choice(log_types)
    log_entry.update({
        "timestamp": datetime.datetime.now().isoformat(),
        "hostname": "security-lab-host",
        "service": "security-monitor"
    })
    
    return log_entry

def main():
    print("Starting security log generator...")
    
    while True:
        # Generate log entry
        log_entry = generate_security_log()
        
        # Write to log file
        with open("logs/security.log", "a") as f:
            f.write(json.dumps(log_entry) + "\n")
        
        # Print to console for immediate feedback
        print(f"[{log_entry['timestamp']}] {log_entry['event_type']}: {log_entry.get('severity', 'info')}")
        
        # Wait before next log entry
        time.sleep(random.uniform(1, 3))

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nLog generator stopped.")