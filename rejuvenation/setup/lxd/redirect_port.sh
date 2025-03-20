#!/usr/bin/env bash


# REDIRECT_PORTS()
# DESCRIPTION:
#   Redirect SSH traffic from port 2222 on the host to port 22 on the Xen domU
#   Redirect HTTP traffic from port 8080 on the host to port 80 on the Xen domU
#   Check if the redirection rules are correctly applied
REDIRECT_PORTS(){
  mkdir -p /etc/iptables

  # Flush existing rules
  iptables -t nat -F

  echo "1" > /proc/sys/net/ipv4/ip_forward

  # NOT ADD DOUBLE QUOTE
  iptables -t nat -A POSTROUTING -s 10.8.136.0/24 -o enp0s3 -j MASQUERADE
  iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 10.8.136.130:80
  iptables -t nat -A PREROUTING -p tcp --dport 2222 -j DNAT --to-destination 10.8.136.130:22

  iptables-save > /etc/iptables/rules.v4

  # Create a script to load iptables rules during startup
  cat > /etc/network/if-pre-up.d/iptables <<EOL
#!/bin/sh
/sbin/iptables-restore < /etc/iptables/rules.v4
EOL

  chmod +x /etc/network/if-pre-up.d/iptables

  apt-get install -y iptables-persistent

  if iptables -t nat -L | grep -qE "(to:$NEW_IP:22|to:$NEW_IP:80)"; then
    echo "Port redirection rules have been successfully applied."
  else
    echo "Failed to apply port redirection rules. Please check iptables configuration."
  fi
}

REDIRECT_PORTS