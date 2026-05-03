#!/bin/bash

# Ensure IP forwarding is enabled
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

# Ensure keys exist or generate them
if [[ ! -f /etc/wireguard/privatekey ]]; then
    echo "No private key found. Generating keys..."
    wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
    chmod 600 /etc/wireguard/privatekey
fi

PRIVATE_KEY=$(cat /etc/wireguard/privatekey)
PUBLIC_KEY=$(cat /etc/wireguard/publickey)

echo "Server Public Key: $PUBLIC_KEY"

# Load or generate WireGuard configuration (wg0.conf)
if [[ ! -f /etc/wireguard/wg0.conf ]]; then
    echo "No wg0.conf found. Generating a default one with the private key."
    cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.1/24
SaveConfig = true
ListenPort = 51820
PrivateKey = $PRIVATE_KEY
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
    chmod 600 /etc/wireguard/wg0.conf
else
    # Check if PrivateKey needs to be updated in existing wg0.conf
    if grep -q "<INSERT_SERVER_PRIVATE_KEY>" /etc/wireguard/wg0.conf; then
        echo "Updating PrivateKey in wg0.conf..."
        sed -i "s|<INSERT_SERVER_PRIVATE_KEY>|$PRIVATE_KEY|g" /etc/wireguard/wg0.conf
    fi
fi

echo "Starting WireGuard with wg0.conf"
# Bring up the interface
wg-quick up wg0

# Ensure cleanup on exit
trap "wg-quick down wg0; exit" SIGINT SIGTERM

# Keep the container running and logs streaming
tail -f /dev/null
