import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Configure to capture all traffic locally
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        
        // IPv4 settings
        settings.ipv4Settings = NEIPv4Settings(addresses: ["192.168.1.1"], subnetMasks: ["255.255.255.0"])
        settings.ipv4Settings?.includedRoutes = [NEIPv4Route.default()]
        
        // DNS settings (can use local or public DNS)
        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8"])
        
        setTunnelNetworkSettings(settings) { error in
            if let error = error {
                completionHandler(error)
                return
            }
            
            // Start capturing packets
            self.startPacketCapture()
            completionHandler(nil)
        }
    }
    
    func startPacketCapture() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            
            // Write filtered packets back to the network
            self.packetFlow.writePackets(packets, withProtocols: protocols)
            
            // Continue reading packets
            self.startPacketCapture()
        }
    }
}
