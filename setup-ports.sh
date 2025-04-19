#!/bin/bash

# This script sets up port forwarding from standard HTTP/HTTPS ports to our alternative ports
# Run this script with sudo privileges

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Forward port 80 traffic to 8080 (where Traefik is listening)
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# Forward port 443 traffic to 8443 (where Traefik is listening)
iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443

# Save iptables rules to persist after reboot
if command -v iptables-save > /dev/null; then
  if [ -d /etc/iptables ]; then
    iptables-save > /etc/iptables/rules.v4
    echo "Saved iptables rules to /etc/iptables/rules.v4"
  else
    iptables-save > /etc/iptables.rules
    echo "Saved iptables rules to /etc/iptables.rules"
    
    # Create a systemd service to load rules at boot if it doesn't exist
    if [ ! -f /etc/systemd/system/iptables-restore.service ]; then
      cat > /etc/systemd/system/iptables-restore.service << EOF
[Unit]
Description=Restore iptables rules
Before=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables.rules
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
      systemctl enable iptables-restore.service
      echo "Created and enabled iptables-restore service"
    fi
  fi
else
  echo "iptables-save not found. Rules will not persist after reboot."
  echo "Please install iptables-persistent package for your distribution."
fi

echo "Port forwarding set up successfully:"
echo "Port 80 -> 8080"
echo "Port 443 -> 8443"
