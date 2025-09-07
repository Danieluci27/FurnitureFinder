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
    @EnvironmentObject var vm: ImageAnalysis
    @EnvironmentObject var storage: DeviceStorageModel
    @Binding var path: NavigationPath
    @State var searchResults: [(idx: Int, score: Float)]
    @State private var firstAppear: Bool
    @State var isSearching: Bool
    @State private var embeddings: [ShapedArrayCodable?]
    @State private var searchText: String
    @State private var pendingText: String
    @State private var showAlert: Bool
    @State private var showAlertMessage: String
    
    init (path: Binding<NavigationPath>) {
        self._path = path
        self._firstAppear = State(initialValue: true)
        self._isSearching = State(initialValue: false)
        self._searchText = State(initialValue: "")
        self._pendingText = State(initialValue: "")
        self._searchResults = State(initialValue: [])
        self._embeddings = State(initialValue: [])
        self._showAlert = State(initialValue: false)
        self._showAlertMessage = State(initialValue: "")
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
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        let indices: [Int] = self.searchText.isEmpty
                        ? Array(storage.userData.indices)
                            : self.searchResults.map { $0.idx }
                        ForEach(indices, id: \.self) { (index: Int) in
                            if let image = storage.userData[index].image {
                                let masks = storage.userData[index].maskList
                                let items = storage.userData[index].itemsList
                                SavedImageTile(image: image) {
                                    navModel.selectedImage = image
                                    navModel.selectedMasks = masks
                                    navModel.selectedItems = items
                                    navModel.masksReady = true
                                    path.append(Screen.resultsView)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
        .onAppear {
            if !storage.didUserLoad {
                do {
                    try storage.loadUserData()
                    try extractEmbeddings()
                } catch {
                    self.showAlertMessage = ""
                    self.showAlert = true
                }
            }
        }
        .alert("Load Status", isPresented: $showAlert, actions: { Button("OK", role: .cancel) {} }, message: { Text(showAlertMessage) })
    }
}
extension SavedView {
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
            for i in 0...self.embeddings.count {
                if let shapedArr = self.embeddings[i] {
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
            print("fails to encode")
            throw TextEncoderError.computeTextEncodingError
        }
    }
}

extension SavedView {
    func extractEmbeddings() throws {
        for idx in storage.userData.indices {
            self.embeddings.append(storage.userData[idx].embedding)
        }
    }
}

enum SearchError: Error {
    case EmptyText
}

enum JSONDecodeError: Error {
    case InvalidType
}
