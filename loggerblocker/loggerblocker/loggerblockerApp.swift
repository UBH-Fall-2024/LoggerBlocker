import SwiftUI
import NetworkExtension

class VPNManager: ObservableObject {
    @Published var status: NEVPNStatus = .invalid
    private var manager: NETunnelProviderManager?
    
    func setupVPN() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, _) in
            self?.manager = managers?.first ?? NETunnelProviderManager()
            
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = "com.loggerblocker.loggerblocker.ne"
            proto.serverAddress = "127.0.0.1"
            
            self?.manager?.protocolConfiguration = proto
            self?.manager?.isEnabled = true
            
            self?.manager?.saveToPreferences { _ in
                try? self?.manager?.connection.startVPNTunnel()
            }
        }
    }
    
    func stopVPN() {
        manager?.connection.stopVPNTunnel()
    }
}

struct MainView: View {
    @StateObject private var vpnManager = VPNManager()
    
    var body: some View {
        Button(action: {
            vpnManager.setupVPN()
        }) {
            Text("Start VPN")
        }
        
        Button(action: {
            vpnManager.stopVPN()
        }) {
            Text("Stop VPN")
        }
    }
}

@main
struct MainApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

