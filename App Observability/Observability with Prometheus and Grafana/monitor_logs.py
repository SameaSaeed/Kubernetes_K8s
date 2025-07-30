#!/usr/bin/env python3

import json
import time
import subprocess
from collections import defaultdict

class SecurityLogMonitor:
    def __init__(self, log_file):
        self.log_file = log_file
        self.failed_login_count = defaultdict(int)
        self.alert_threshold = 5  # Alert after 5 failed attempts
        
    def process_log_line(self, line):
        """Process a single log line and check for security issues"""
        try:
            log_entry = json.loads(line.strip())
            
            # Monitor failed logins
            if (log_entry.get('event_type') == 'login_attempt' and 
                not log_entry.get('success', True)):
                
                ip = log_entry.get('ip_address', 'unknown')
                self.failed_login_count[ip] += 1
                
                print(f"[MONITOR] Failed login from {ip} (count: {self.failed_login_count[ip]})")
                
                if self.failed_login_count[ip] >= self.alert_threshold:
                    self.trigger_alert(f"BRUTE FORCE DETECTED: {ip} has {self.failed_login_count[ip]} failed attempts")
            
            # Monitor critical security alerts
            elif (log_entry.get('event_type') == 'security_alert' and 
                  log_entry.get('severity') == 'critical'):
                
                self.trigger_alert(f"CRITICAL SECURITY ALERT: {log_entry.get('alert_type', 'unknown')}")
            
            # Monitor suspicious API access
            elif (log_entry.get('event_type') == 'api_access' and 
                  log_entry.get('status_code') == 403):
                
                ip = log_entry.get('ip_address', 'unknown')
                endpoint = log_entry.get('endpoint', 'unknown')
                print(f"[MONITOR] Forbidden access attempt: {ip} -> {endpoint}")
                
        except json.JSONDecodeError:
            pass
    
    def trigger_alert(self, message):
        """Trigger a security alert"""
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        alert_msg = f"[{timestamp}] SECURITY ALERT: {message}"
        print(f"\033[91m{alert_msg}\033[0m")  # Red color for alerts
        
        # Log alert to separate file
        with open("logs/security_alerts.log", "a") as f:
            f.write(alert_msg + "\n")
    
    def start_monitoring(self):
        """Start real-time log monitoring"""
        print(f"Starting real-time monitoring of {self.log_file}")
        print("Press Ctrl+C to stop monitoring\n")
        
        try:
            # Use tail -f to follow log file
            process = subprocess.Popen(['tail', '-f', self.log_file], 
                                     stdout=subprocess.PIPE, 
                                     stderr=subprocess.PIPE,
                                     universal_newlines=True)
            
            for line in iter(process.stdout.readline, ''):
                if line:
                    self.process_log_line(line)
                    
        except KeyboardInterrupt:
            print("\nMonitoring stopped.")
            process.terminate()
        except FileNotFoundError:
            print(f"Log file {self.log_file} not found. Make sure log generator is running.")

if __name__ == "__main__":
    monitor = SecurityLogMonitor("logs/security.log")
    monitor.start_monitoring()