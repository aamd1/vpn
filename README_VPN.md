### Setup Instructions

To get your WireGuard server up and running, follow these steps:

1. **Configuration (Optional)**:
   - You can pre-configure `config/wg0.conf` by copying `config/wg0.conf.example`.
   - If you leave it as `<INSERT_SERVER_PRIVATE_KEY>`, or if `config/wg0.conf` doesn't exist, the server will automatically generate keys and a default configuration on its first run.

2. **Build and Start**:
   ```bash
   docker compose up -d --build
   ```

3. **Retrieve Public Key**:
   Check the container logs to find your server's public key (needed for client configuration):
   ```bash
   docker logs wireguard-server | grep "Server Public Key"
   ```
   Or look at the file:
   ```bash
   cat config/publickey
   ```

4. **Verify**:
   Check if the server is running correctly:
   ```bash
   docker logs wireguard-server
   ```
   Or check the interface inside the container:
   ```bash
   docker exec -it wireguard-server wg show
   ```

5. **Client Configuration**:
   For each client (peer), generate another pair of keys and add a `[Peer]` section to the `config/wg0.conf` on the server.
   On the client side, use a configuration like:
   ```ini
   [Interface]
   PrivateKey = <CLIENT_PRIVATE_KEY>
   Address = 10.0.0.2/32
   DNS = 1.1.1.1

   [Peer]
   PublicKey = <SERVER_PUBLIC_KEY>
   Endpoint = <SERVER_PUBLIC_IP>:51820
   AllowedIPs = 0.0.0.0/0
   PersistentKeepalive = 25
   ```

### Notes
- Ensure your host's firewall allows traffic on port `51820/UDP`.
- The container needs `NET_ADMIN` and `SYS_MODULE` capabilities to manage network interfaces and potentially interact with the kernel module.
- `PostUp` and `PostDown` rules in `wg0.conf` are configured to allow NAT (MASQUERADE) through `eth0`. Ensure `eth0` is the correct external interface name inside the container.
