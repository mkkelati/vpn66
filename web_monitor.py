#!/usr/bin/env python3

import json
import os
import time
import subprocess
import threading
from datetime import datetime
from flask import Flask, render_template, jsonify, request
import psutil

app = Flask(__name__)

# Configuration
CONFIG_FILE = "/etc/vpn_manager/config.json"
CLIENTS_FILE = "/etc/vpn_manager/clients.json"
LOG_FILE = "/var/log/vpn_manager.log"
XRAY_LOG = "/var/log/xray/access.log"

class VPNMonitor:
    def __init__(self):
        self.connections = []
        self.clients = []
        self.stats = {}
        
    def load_config(self):
        try:
            if os.path.exists(CONFIG_FILE):
                with open(CONFIG_FILE, 'r') as f:
                    return json.load(f)
        except Exception as e:
            print(f"Error loading config: {e}")
        return {}
    
    def load_clients(self):
        try:
            if os.path.exists(CLIENTS_FILE):
                with open(CLIENTS_FILE, 'r') as f:
                    data = json.load(f)
                    return data.get('clients', [])
        except Exception as e:
            print(f"Error loading clients: {e}")
        return []
    
    def get_system_stats(self):
        stats = {
            'cpu_percent': psutil.cpu_percent(interval=1),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_percent': psutil.disk_usage('/').percent,
            'uptime': self.get_uptime(),
            'xray_status': self.get_xray_status()
        }
        return stats
    
    def get_uptime(self):
        try:
            with open('/proc/uptime', 'r') as f:
                uptime_seconds = float(f.readline().split()[0])
                return str(datetime.timedelta(seconds=uptime_seconds))
        except:
            return "Unknown"
    
    def get_xray_status(self):
        try:
            result = subprocess.run(['systemctl', 'is-active', 'xray'], 
                                 capture_output=True, text=True)
            return result.stdout.strip()
        except:
            return "Unknown"
    
    def get_recent_connections(self):
        connections = []
        try:
            if os.path.exists(XRAY_LOG):
                with open(XRAY_LOG, 'r') as f:
                    lines = f.readlines()
                    for line in lines[-50:]:  # Last 50 lines
                        if 'accepted' in line:
                            connections.append({
                                'timestamp': line.split()[0] + ' ' + line.split()[1],
                                'message': line.strip()
                            })
        except Exception as e:
            print(f"Error reading Xray log: {e}")
        return connections
    
    def get_network_stats(self):
        try:
            # Get network interface stats
            net_io = psutil.net_io_counters()
            return {
                'bytes_sent': net_io.bytes_sent,
                'bytes_recv': net_io.bytes_recv,
                'packets_sent': net_io.packets_sent,
                'packets_recv': net_io.packets_recv
            }
        except:
            return {}
    
    def get_active_connections(self):
        try:
            connections = []
            for conn in psutil.net_connections():
                if conn.status == 'ESTABLISHED' and conn.raddr:
                    if conn.raddr.port in [80, 443, 8080, 8443]:
                        connections.append({
                            'local_addr': f"{conn.laddr.ip}:{conn.laddr.port}",
                            'remote_addr': f"{conn.raddr.ip}:{conn.raddr.port}",
                            'status': conn.status,
                            'pid': conn.pid
                        })
            return connections
        except:
            return []

monitor = VPNMonitor()

@app.route('/')
def index():
    return render_template('dashboard.html')

@app.route('/api/stats')
def get_stats():
    config = monitor.load_config()
    clients = monitor.load_clients()
    system_stats = monitor.get_system_stats()
    network_stats = monitor.get_network_stats()
    active_connections = monitor.get_active_connections()
    recent_connections = monitor.get_recent_connections()
    
    return jsonify({
        'config': config,
        'clients': clients,
        'system': system_stats,
        'network': network_stats,
        'active_connections': active_connections,
        'recent_connections': recent_connections,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/clients')
def get_clients():
    clients = monitor.load_clients()
    return jsonify(clients)

@app.route('/api/connections')
def get_connections():
    active_connections = monitor.get_active_connections()
    recent_connections = monitor.get_recent_connections()
    
    return jsonify({
        'active': active_connections,
        'recent': recent_connections
    })

@app.route('/api/system')
def get_system():
    system_stats = monitor.get_system_stats()
    network_stats = monitor.get_network_stats()
    
    return jsonify({
        'system': system_stats,
        'network': network_stats
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False) 