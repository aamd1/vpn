FROM ubuntu:22.04

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install WireGuard, iptables, and IP tools
RUN apt-get update && apt-get install -y \
    wireguard \
    iptables \
    iproute2 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set up the WireGuard configuration directory
WORKDIR /etc/wireguard

# Copy the start script
COPY start-vpn.sh /usr/local/bin/start-vpn.sh
RUN chmod +x /usr/local/bin/start-vpn.sh

# Expose the default WireGuard port
EXPOSE 51820/udp

# Healthcheck to verify WireGuard is running
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD wg show | grep -q interface || exit 1

ENTRYPOINT ["/usr/local/bin/start-vpn.sh"]
