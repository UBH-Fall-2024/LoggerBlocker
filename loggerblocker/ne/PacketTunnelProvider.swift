import NetworkExtension
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {
    private let logger = Logger(subsystem: "com.loggerblocker.loggerblocker", category: "PacketTunnelProvider")
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Configure with broader network settings
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.0.0.1")
        
        // Configure IPv4 with broader route coverage
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        ipv4Settings.excludedRoutes = [] // Allow all routes
        settings.ipv4Settings = ipv4Settings
        
        // DNS settings
        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4"])
        settings.dnsSettings?.matchDomains = [""] // Match all domains
        
        // MTU settings to ensure proper packet sizes
        settings.mtu = NSNumber(value: 1400)
        
        setTunnelNetworkSettings(settings) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to set tunnel settings: \(error.localizedDescription)")
                completionHandler(error)
                return
            }
            
            // Start capturing packets
            self?.startPacketCapture()
            completionHandler(nil)
        }
    }
    
    func startPacketCapture() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            
            // Log packet information
            self.logger.debug("Received \(packets.count) packets")
            
            // Process and forward packets
            self.packetFlow.writePackets(packets, withProtocols: protocols)
            
            // Continue reading packets
            self.startPacketCapture()
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.info("Stopping tunnel with reason: ")
        completionHandler()
    }
}
