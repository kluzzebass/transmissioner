import AppKit
import SwiftUI
import OSLog

final class AppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState?
    private let logger = Logger(subsystem: "org.radical.Transmissioner", category: "AppDelegate")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        // Check if we're running from Applications folder (installed version)
        // If so, this is likely not the dev build
        let bundlePath = Bundle.main.bundlePath
        if bundlePath.hasPrefix("/Applications/") {
            logger.warning("⚠️ Running from Applications folder - this might be the installed version")
        } else {
            logger.info("✅ Running dev build from: \(bundlePath)")
        }
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        logger.info("🔧 applicationWillBecomeActive called")
        // Ensure we stay in accessory mode to prevent window auto-opening
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        logger.info("🔧 applicationDidBecomeActive called")
        // Ensure we stay in accessory mode to prevent window auto-opening
        NSApp.setActivationPolicy(.accessory)
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        logger.info("🔗 AppDelegate received URLs: \(urls.map { $0.absoluteString }.joined(separator: ", "))")
        
        // Keep activation policy as accessory to prevent window auto-opening
        // Don't change to .regular which would cause windows to appear
        NSApp.setActivationPolicy(.accessory)
        
        for url in urls {
            if url.scheme == "magnet" {
                // Extract the magnet link (the full URL string)
                let magnetLink = url.absoluteString
                logger.info("🔗 Processing magnet link: \(magnetLink.prefix(50))...")
                
                // Store in UserDefaults as a fallback if AppState isn't ready
                UserDefaults.standard.set(magnetLink, forKey: "pendingMagnetLink")
                logger.info("🔗 Stored magnet link in UserDefaults as fallback")
                
                
                // Always post notification - SwiftUI onOpenURL will also catch it
                // This ensures we handle it even if AppState isn't ready yet
                NotificationCenter.default.post(
                    name: .addMagnetLink,
                    object: nil,
                    userInfo: [Notification.magnetLinkKey: magnetLink]
                )
                logger.info("🔗 Posted addMagnetLink notification")
                
                // Also store directly in AppState if available
                if let appState = appState {
                    logger.info("🔗 Also storing magnet link in AppState")
                    appState.pendingMagnetLink = magnetLink
                } else {
                    logger.warning("⚠️ AppState not available yet - will be picked up when view loads")
                }
            } else {
                logger.warning("⚠️ Received non-magnet URL: \(url.absoluteString)")
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Prevent reopening when already running
        return false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't terminate - we're a menu bar app
        return false
    }
}
