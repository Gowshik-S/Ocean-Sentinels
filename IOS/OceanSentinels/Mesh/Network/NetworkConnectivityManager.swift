import Foundation
import Network
import Combine
import os

/// Centralized network connectivity monitor for the entire app.
///
/// Design: Internet-first with automatic BLE mesh fallback.
/// This class provides the "internet available?" signal that enables
/// instant routing decisions:
///
///   User submits hazard report
///     ↓
///   isOnline == true  → API upload
///   isOnline == false → MeshMessageRepository.forwardToMesh()
///     ↓
///   BLE peers available? → broadcast
///   No peers → queue locally (SwiftData)
///     ↓
///   Background service: relayProcessor (15s), queueProcessor (30s)
///   onPathUpdate(satisfied) → processQueue()
///
/// Replaces Android NetworkConnectivityManager (ConnectivityManager callbacks).
/// Uses NWPathMonitor (Network framework) — iOS's native connectivity API.
final class NetworkConnectivityManager: ObservableObject {
    
    static let shared = NetworkConnectivityManager()
    
    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "NetConnectivity")
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.oceansentinels.connectivity")
    
    /// Reactive connectivity state for SwiftUI observation
    @Published private(set) var isOnline: Bool = false
    
    /// Thread-safe callback listeners
    private var listeners: [(Bool) -> Void] = []
    private let listenersLock = NSLock()
    
    private var isMonitoring = false
    
    private init() {
        // Set initial state
        let path = monitor.currentPath
        isOnline = path.status == .satisfied
        logger.info("Initial connectivity state: \(self.isOnline)")
    }
    
    // MARK: - Monitoring
    
    /// Start monitoring network connectivity changes.
    /// Safe to call multiple times — only starts once.
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let online = path.status == .satisfied
            
            DispatchQueue.main.async {
                if self.isOnline != online {
                    self.logger.info("Internet \(online ? "AVAILABLE" : "LOST") — switching to \(online ? "internet-upload" : "mesh-relay") mode")
                    self.isOnline = online
                    self.notifyListeners(online)
                }
            }
        }
        
        monitor.start(queue: monitorQueue)
        isMonitoring = true
        logger.info("Network monitoring started")
    }
    
    /// Stop monitoring. Call when mesh service is stopped.
    func stopMonitoring() {
        guard isMonitoring else { return }
        monitor.cancel()
        isMonitoring = false
        logger.info("Network monitoring stopped")
    }
    
    // MARK: - Synchronous Check
    
    /// Fast-path synchronous internet check using cached state.
    func isInternetAvailable() -> Bool {
        isOnline
    }
    
    // MARK: - Listeners
    
    /// Add a connectivity change listener.
    func addConnectivityListener(_ listener: @escaping (Bool) -> Void) {
        listenersLock.lock()
        listeners.append(listener)
        listenersLock.unlock()
    }
    
    private func notifyListeners(_ online: Bool) {
        listenersLock.lock()
        let snapshot = listeners
        listenersLock.unlock()
        
        for listener in snapshot {
            listener(online)
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
