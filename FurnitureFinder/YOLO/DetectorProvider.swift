//
//  DetectorProvider.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 9/6/25.
//

import Foundation

actor DetectorProvider {
    private var detector: FurnitureDetector?
    private var loadingTask: Task<FurnitureDetector, Error>?

    func get() async throws -> FurnitureDetector {
        if let d = detector { return d }
        if let t = loadingTask {
            print("DetectorProvider.get(): awaiting existing task \(t)")
            return try await t.value
        }

        let start = Date()
        print("DetectorProvider.get(): starting build at", start)

        let t = Task(priority: .userInitiated) { () -> FurnitureDetector in
            // If your FurnitureDetector loads Core ML models internally, this is the expensive part
            let d = try FurnitureDetector()
            return d
        }
        loadingTask = t

        do {
            let d = try await t.value
            let end = Date()
            print("DetectorProvider.get(): finished build in \(end.timeIntervalSince(start))s")
            detector = d
            loadingTask = nil
            return d
        } catch {
            print("DetectorProvider.get(): FAILED in \(Date().timeIntervalSince(start))s:", error)
            loadingTask = nil        // <- important, don’t leave a failed task “stuck”
            throw error
        }
    }

    func preload() {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            _ = try? await self.get()
        }
    }
}
