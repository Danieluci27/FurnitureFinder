//
//  saved.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 7/25/25.
//

import Foundation
import SwiftUI
import CoreML

struct SavedView: View {
    @EnvironmentObject var navModel: NavigationModel
    @Binding var path: NavigationPath
    @State private var savedImages: [UIImage] = []
    @State private var searchResults: [(index: Int, score: Float)] = []
    @State private var savedMasksList: [[Int: UIImage]] = []
    @State private var savedItemsList: [[Int: [SearchItem]]] = []
    @State private var savedShapedArray: [ShapedArrayCodable?] = []
    @State private var firstAppear: Bool = true
    @State private var isSearching: Bool = false
    @State private var searchText: String = ""
    @State private var pendingText: String = ""
    
    struct SavedImageTile: View {
        let image: UIImage
        let onTap: () -> Void
        var body: some View {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(6)
                .onTapGesture { 
                    onTap() }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search...", text: $pendingText)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onSubmit { self.searchText = self.pendingText; try? self.pickPhotos() }
                
                Button(action: {
                    self.searchText = self.pendingText
                    if !self.searchText.isEmpty {
                        do { try self.pickPhotos() } catch { print(error) }
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .padding(8)
                }
            }
            .padding([.top, .horizontal], 12)
            if self.isSearching {
                ProgressView()
                    .controlSize(.large)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                ScrollView {
                    //Default if (searchText == empty) else use searchResults to show the custom set of images.
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        let indices: [Int] = self.searchText.isEmpty
                            ? Array(self.savedImages.indices)
                            : self.searchResults.map { $0.index }
                        ForEach(indices, id: \.self) { index in
                            SavedImageTile(image: self.savedImages[index]) {
                                navModel.selectedImage = self.savedImages[index]
                                navModel.selectedMasks = self.savedMasksList[index]
                                navModel.selectedItems = self.savedItemsList[index]
                                path.append(Screen.maskedPage)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
        .onAppear {
            //firstAppear on current usage?
            if self.firstAppear {
                self.loadSavedData()
                self.firstAppear = false
            }
        }
    }
    
    func pickPhotos() throws {
        self.isSearching = true
        self.searchResults.removeAll()
        guard let path = Bundle.main.resourceURL else {
            fatalError("Couldn’t locate bundle resource root.")
        }
        let textEncoder = try! TextEncoder(resourcesAt: path)
        let textEmb = try? textEncoder.computeTextEmbedding(prompt: self.searchText)
        if let textEmb {
            for i in 0..<self.savedShapedArray.count {
                if let shapedArr = self.savedShapedArray[i] {
                    let imgEmb = MLShapedArray<Float32>(scalars: shapedArr.scalars, shape: shapedArr.shape)
                    let sim = cosine_similarity(A: textEmb, B: imgEmb)
                    print(sim)
                    if sim > 0.1 {
                        self.searchResults.append((i, sim))
                    }
                }
            }
            guard !self.searchResults.isEmpty else { return }
            
            // convert to tuples and sort by score desc
            self.searchResults = self.searchResults.sorted { $0.score > $1.score }

            
            self.isSearching = false
            print(self.isSearching)
        } else {
            throw TextEncoderError.computeTextEncodingError
        }
    }

    func loadSavedData() {
        let key = "savedSetCounter"
        let totalSets = UserDefaults.standard.integer(forKey: key)
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        for i in 0..<totalSets {
            let setFolder = docURL.appendingPathComponent("set_\(i)")
            let imagePath = setFolder.appendingPathComponent("image.png")
            if let imageData = try? Data(contentsOf: imagePath),
               let image = UIImage(data: imageData) {
                self.savedImages.append(image)
            } else {
                continue
            }

            var masks: [Int: UIImage] = [:]
            for index in 0..<10 {
                let maskURL = setFolder.appendingPathComponent("mask_\(index).png")
                if let data = try? Data(contentsOf: maskURL),
                   let maskImage = UIImage(data: data) {
                    masks[index] = maskImage
                }
            }
            self.savedMasksList.append(masks)

            let itemsURL = setFolder.appendingPathComponent("itemsByIndex.json")
            if let data = try? Data(contentsOf: itemsURL),
               let decoded = try? JSONDecoder().decode([Int: [SearchItem]].self, from: data) {
                    self.savedItemsList.append(decoded)
            } else {
                self.savedItemsList.append([:])
            }
            
            let embeddingURL = setFolder.appendingPathComponent("embedding.json")
            if let data = try? Data(contentsOf: embeddingURL),
               let decoded = try? JSONDecoder().decode(ShapedArrayCodable.self, from: data) {
                self.savedShapedArray.append(decoded)
            } else {
                self.savedShapedArray.append(nil)
                //if empty, skip
            }
        }
    }
}

struct MaskedImagePage: View {
    let image: UIImage?
    let masks: [Int: UIImage]
    let items: [Int: [SearchItem]]
    @State private var selectedIndex: Int? = nil
    @State private var showInstruction: Bool = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                if let img = image {
                    MaskedImageView(
                        baseImage: img,
                        masks: masks,
                        maskReady: true,
                        onMaskTap: { tappedIdx in
                            selectedIndex = tappedIdx
                        }
                    )
                    .frame(width: geo.size.width, height: geo.size.height / 2)
                } else {
                    Text("No image loaded.")
                        .frame(height: geo.size.height / 2)
                }

                ZStack {
                    // Fixed-position robot
                    Image("robot")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .position(x: 60, y: geo.size.height / 2 - 40)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showInstruction.toggle()
                            print(showInstruction)
                        }

                    // Message above robot
                    if showInstruction {
                        Text("Click on the highlighted objects to view the products!")
                            .font(.subheadline)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                            .fixedSize(horizontal: false, vertical: true)
                            .position(x: 190, y: geo.size.height / 2 - 110)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height / 2)
            }
            .onAppear {
                showInstruction = false
            }
            .sheet(item: $selectedIndex, onDismiss: {selectedIndex = nil}) { idx in
                if let products = items[idx] {
                    ResultsView(items: products,
                                dismiss: { selectedIndex = nil })
                }
            }
        }
    }
}

enum JSONDecodeError: Error {
    case InvalidType
}
