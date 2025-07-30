#!/usr/bin/env python3

import json
import sys
from collections import defaultdict, Counter
from datetime import datetime, timedelta

def analyze_security_logs(log_file):
    """Analyze security logs for potential threats"""
    
    print("=== Security Log Analysis Report ===\n")
    
    # Counters for analysis
    event_counts = Counter()
    failed_logins = defaultdict(list)
    api_errors = defaultdict(list)
    security_alerts = []
    
    try:
        with open(log_file, 'r') as f:
            for line in f:
                try:
                    log_entry = json.loads(line.strip())
                    event_type = log_entry.get('event_type', 'unknown')
                    event_counts[event_type] += 1
                    
                    # Analyze login attempts
                    if event_type == 'login_attempt' and not log_entry.get('success', True):
                        ip = log_entry.get('ip_address', 'unknown')
                        failed_logins[ip].append(log_entry)
                    
                    # Analyze API access
                    elif event_type == 'api_access' and log_entry.get('status_code', 200) >= 400:
                        ip = log_entry.get('ip_address', 'unknown')
                        api_errors[ip].append(log_entry)
                    
                    # Collect security alerts
                    elif event_type == 'security_alert':
                        security_alerts.append(log_entry)
                        
                except json.JSONDecodeError:
                    continue
                    
    except FileNotFoundError:
        print(f"Log file {log_file} not found!")
        return
    
    # Print analysis results
    print("1. Event Summary:")
    for event_type, count in event_counts.most_common():
        print(f"   {event_type}: {count}")
    
    print("\n2. Failed Login Analysis:")
    suspicious_ips = []
    for ip, attempts in failed_logins.items():
        if len(attempts) >= 3:  # 3 or more failed attempts
            print(f"   SUSPICIOUS: {ip} - {len(attempts)} failed login attempts")
            suspicious_ips.append(ip)
        else:
            print(f"   {ip} - {len(attempts)} failed login attempts")
    
    print("\n3. API Error Analysis:")
    for ip, errors in api_errors.items():
        error_codes = Counter(e.get('status_code') for e in errors)
        print(f"   {ip}: {dict(error_codes)}")
    
    print("\n4. Security Alerts:")
    if security_alerts:
        for alert in security_alerts[-5:]:  # Show last 5 alerts
            print(f"   [{alert['timestamp']}] {alert['severity'].upper()}: {alert['alert_type']}")
    else:
        print("   No security alerts found")
    
    print("\n5. Recommendations:")
    if suspicious_ips:
        print("   - Consider blocking or monitoring these IPs:", ", ".join(suspicious_ips))
    if len(api_errors) > 5:
        print("   - High number of API errors detected - investigate application issues")
    if any(alert['severity'] == 'critical' for alert in security_alerts):
        print("   - CRITICAL alerts detected - immediate investigation required")
    
    print("\n=== End of Analysis ===")

if __name__ == "__main__":
    log_file = sys.argv[1] if len(sys.argv) > 1 else "logs/security.log"
    analyze_security_logs(log_file)