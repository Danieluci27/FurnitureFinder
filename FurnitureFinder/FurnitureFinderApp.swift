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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
