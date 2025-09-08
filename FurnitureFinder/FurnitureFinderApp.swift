//
//  FurnitureFinderApp.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 6/23/25.
//

import SwiftUI
import FirebaseCore

struct MaskedImagePageData: Hashable {}

class AppDelegate : NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct FurnitureFinderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var vm: ImageAnalysis
    @StateObject private var storage = DeviceStorageModel()
    let provider: DetectorProvider
    
    init() {
        let p = DetectorProvider()
        self.provider = p
        self._vm = StateObject(wrappedValue: ImageAnalysis(provider: p))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .environmentObject(storage)
                .task {
                    print("App preload using provider:", ObjectIdentifier(provider))
                    await provider.preload() }
        }
    }
}
