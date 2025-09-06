//
//  saved.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 7/25/25.
//

import Foundation
import SwiftUI
import CoreML


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
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        let indices: [Int] = self.searchText.isEmpty
                            ? Array(self.savedImages.indices)
                            : self.searchResults.map { $0.index }
                        ForEach(indices, id: \.self) { (index: Int) in
                            let savedImage = self.savedImages[index]
                            SavedImageTile(image: savedImage) {
                                navModel.selectedImage = savedImage
                                navModel.selectedMasks = self.savedMasksList[index]
                                navModel.selectedItems = self.savedItemsList[index]
                                navModel.masksReady = true
                                path.append(Screen.resultsView)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
        .onAppear {
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
    
        if self.searchText.isEmpty {
            throw SearchError.EmptyText
        }
        
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

enum SearchError: Error {
    case EmptyText
}

enum JSONDecodeError: Error {
    case InvalidType
}
