import NetworkExtension
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {
    private let logger = Logger(subsystem: "com.loggerblocker.loggerblocker", category: "PacketTunnelProvider")
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Configure tunnel settings with both IPv4 and IPv6
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.0.0.1")
        
        // IPv4 Configuration
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        // IPv6 Configuration
        let ipv6Settings = NEIPv6Settings(addresses: ["fd00::1"], networkPrefixLengths: [64])
        ipv6Settings.includedRoutes = [NEIPv6Route.default()]
        settings.ipv6Settings = ipv6Settings
        
        // DNS Configuration
        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4"])
        settings.dnsSettings?.matchDomains = [""] // Match all domains
        
        // Optimize MTU
        settings.mtu = NSNumber(value: 1500)
        
        setTunnelNetworkSettings(settings) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to set tunnel settings: \(error.localizedDescription)")
                completionHandler(error)
                return
            }
            
            self?.startPacketCapture()
            completionHandler(nil)
        }
    }
    
    func startPacketCapture() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            
            // Log packet information
            self.logger.debug("Received \(packets.count) packets")
            
            // Process packets before forwarding
            for (index, packet) in packets.enumerated() {
                // Add your packet inspection logic here
                self.logger.debug("Processing packet \(index) with protocol \(protocols[index])")
            }
            
            // Forward packets with minimal delay
            DispatchQueue.global(qos: .userInteractive).async {
                self.packetFlow.writePackets(packets, withProtocols: protocols)
                // Continue reading packets
                self.startPacketCapture()
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.info("Stopping tunnel with reason: \(reason)")
        completionHandler()
    }
}
