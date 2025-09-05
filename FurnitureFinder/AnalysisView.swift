//
//  AnalysisView.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 7/25/25.
//

import Foundation
import SwiftUI
import PhotosUI
import CoreML

struct ShapedArrayCodable: Codable {
    let shape: [Int]
    let scalars: [Float]
}


struct AnalysisView: View {
    @StateObject private var vm = ImageAnalysis()
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isPickerPresented = false
    // …and a separate UIImage that you fill later
    @State private var imageToAnalyze: UIImage? = UIImage(named: "room")
    @State private var selectedIndex: Int?
    @State private var selectedMaskIndex: Int?
    @State private var isShowingResult: Bool = false
    @State private var showSaveAlert = false
    @State private var saveStatusMessage = ""
    var body: some View {
        NavigationView{
            GeometryReader { geo in
                VStack(spacing: 0) {
                    // base image (picked or placeholder “room”)
                    if let ui = imageToAnalyze {
                        MaskedImageView(
                            baseImage: ui,
                            masks: vm.segmentationMasks,
                            maskReady: !vm.segmentationMasks.isEmpty && !vm.isLoading
                            
                        ) { tappedIdx in
                            selectedIndex = tappedIdx
                        }
                        .frame(
                            width: geo.size.width,
                            height: geo.size.height / 2
                        )
                        
                    }
                    
                    Divider()
                    
                    // ── BOTTOM HALF: controls or result-grid ──
                    if vm.isLoading {
                        // show spinner while loading
                        VStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.5)
                            Spacer()
                        }
                        .frame(height: geo.size.height / 2)
                    }
                    
                    // start + loading
                    
                    if (vm.start && !vm.isLoading) {
                        // before running dummyAnalysis: show Pick & Analyze
                        HStack(spacing: 20) {
                            PhotosPicker(
                                selection: $selectedItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Text("Pick Photo")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .onChange(of: selectedItem) { _, newItem in
                                guard let item = newItem else { return }
                                Task {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let ui = UIImage(data: data) {
                                        imageToAnalyze = ui
                                    }
                                }
                            }
                            
                            Button("Analyze") {
                                if let ui = imageToAnalyze {
                                    Task {
                                        vm.runAnalysis(on: ui)
                                    }
                                }
                            }
                            .disabled(imageToAnalyze == nil)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(imageToAnalyze == nil ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding()
                        .frame(height: geo.size.height / 2)
                        
                    }
                    //TO-DO: save this to icloud.
                    else if (!vm.start && !vm.isLoading) {
                        //class Storage
                        Button("Save") {
                            var statusMessages: [String] = []
                            
                            let key = "savedSetCounter"
                            let currentIndex = UserDefaults.standard.integer(forKey: key) // defaults to 0
                            
                            let setFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                .appendingPathComponent("set_\(currentIndex)")
                            do {
                                try FileManager.default.createDirectory(at: setFolder, withIntermediateDirectories: true)
                            } catch {
                                statusMessages.append("Failed to create folder for set \(currentIndex).")
                            }
                            
                            let imageURL = setFolder.appendingPathComponent("image.png")
                            if let img = imageToAnalyze {
                                if let data = img.pngData() {
                                    do {
                                        try data.write(to: imageURL)
                                    } catch {
                                        statusMessages.append("Failed to save image.")
                                    }
                                }
                            }
                            
                            //save encodings
                            let embeddingURL = setFolder.appendingPathComponent("embedding.json")
                            if let img = imageToAnalyze {
                                do {
                                    guard let path = Bundle.main.resourceURL else {
                                        fatalError("Couldn’t locate bundle resource root.")
                                    }
                                    
                                    let imgEncoder = try! ImgEncoder(resourcesAt: path)
                                    
                                    let imgEmbeddings = try! imgEncoder.computeImgEmbedding(img: img)
                                    let payload = ShapedArrayCodable(shape: imgEmbeddings.shape, scalars: imgEmbeddings.scalars)
                                    let data = try JSONEncoder().encode(payload)
                                    try data.write(to: embeddingURL)
                                    print(imgEmbeddings)
                                } catch {
                                    statusMessages.append("Failed to save embeddings.")
                                }
                            }
                            
                            
                            // Save itemsByIndex
                            let itemsURL = setFolder.appendingPathComponent("itemsByIndex.json")
                            if let data = try? JSONEncoder().encode(vm.itemsByIndex) {
                                do {
                                    try data.write(to: itemsURL)
                                } catch {
                                    statusMessages.append("Failed to save items.")
                                }
                            } else {
                                statusMessages.append("Encoding items failed.")
                            }

                            // Save segmentationMasks
                            for (index, mask) in vm.segmentationMasks {
                                if let data = mask.pngData() {
                                    let maskURL = setFolder.appendingPathComponent("mask_\(index).png")
                                    do {
                                        try data.write(to: maskURL)
                                    } catch {
                                        statusMessages.append("Failed to save mask \(index).")
                                    }
                                } else {
                                    statusMessages.append("Failed to encode mask \(index).")
                                }
                            }
                        
                            saveStatusMessage = statusMessages.isEmpty ? "Saved successfully." : statusMessages.joined(separator: "\n")
                            showSaveAlert = true
                            
                            UserDefaults.standard.set(currentIndex + 1, forKey: key)
                        }
                    }
                }
                .alert("Save Status", isPresented: $showSaveAlert, actions: {
                    Button("OK", role: .cancel) { }
                }, message: {
                    Text(saveStatusMessage)
                })
                .sheet(item: $selectedIndex, onDismiss: { selectedIndex = nil }) { idx in
                    ResultsView(
                        items: vm.itemsByIndex[idx] ?? [],
                        dismiss: { selectedIndex = nil }
                    )
                }
            }
            .navigationTitle("Furniture Finder")
        }
    }
}
