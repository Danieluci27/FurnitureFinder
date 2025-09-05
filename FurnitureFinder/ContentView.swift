//
//  ContentView.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 6/23/25.
//

//fashion + furniture + kitchenware Items.

import SwiftUI
import PhotosUI
import UIKit
import AVFoundation
import Vision
import CoreML
import Accelerate

// Extensions for pixel buffer & mask conversion
extension Int: Identifiable {
    public var id: Int { self }
}

enum Screen: Hashable {
    case analysis
    case saved
    case maskedPage
}

struct ContentView: View {
    @State private var path = NavigationPath()
    @StateObject private var navModel = NavigationModel()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                Button("Saved") { 
                    path.append(Screen.saved)
                }

                Button("Analysis") {
                    path.append(Screen.analysis)
                }

            }
            .navigationTitle("Welcome")
            .navigationDestination(for: Screen.self) { screen in
                switch screen {
                case .analysis:
                    AnalysisView()
                case .saved:
                    SavedView(path: $path)
                case .maskedPage:
                    MaskedImagePage(
                            image: navModel.selectedImage,
                            masks: navModel.selectedMasks,
                            items: navModel.selectedItems
                    )
                }
            }
        }
        .environmentObject(navModel)
    }
}

func createMultipartBody(
    with imageData: Data,
    fieldName: String,
    fileName: String,
    boundary: String
) -> Data {
    var body = Data()
    let lineBreak = "\r\n"
    
    // --boundary\r\n
    body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
    
    // Content-Disposition: form-data; name="images"; filename="sofa.jpg"\r\n
    body.append(
        "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\(lineBreak)"
            .data(using: .utf8)!
    )
    
    // Content-Type: image/jpeg\r\n\r\n
    body.append("Content-Type: image/jpeg\(lineBreak)\(lineBreak)"
        .data(using: .utf8)!)
    
    // image binary
    body.append(imageData)
    
    // \r\n
    body.append(lineBreak.data(using: .utf8)!)
    
    // --boundary--\r\n
    body.append("--\(boundary)--\(lineBreak)"
        .data(using: .utf8)!)
    
    return body
}

#Preview {
    ContentView()
}
