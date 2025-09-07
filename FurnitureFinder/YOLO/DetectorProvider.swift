//
//  DetectorProvider.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 9/6/25.
//

actor DetectorProvider {
    private var detector: FurnitureDetector?
    private var loadingTask: Task<FurnitureDetector, Error>?
    
    func get() async throws -> FurnitureDetector {
        if let d = detector { return d }
        if let t = loadingTask { return try await t.value }
        
        let t = Task(priority: .userInitiated) { try FurnitureDetector() }
        loadingTask = t
        let d = try await t.value
        detector = d
        loadingTask = nil
        return d
    }
    
    func preload() {
        if detector != nil || loadingTask != nil { return }
        loadingTask = Task(priority: .background) { try FurnitureDetector() }
    }
}
