//
//  DeviceStorageModel.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 9/6/25.

import Foundation
import SwiftUI

struct ResultData {
    init() {
        self.maskList = []
        self.itemsList = []
    }
    var image: UIImage?
    var maskList: [UIImage]
    var itemsList: [[SearchItem]]
    var embedding: ShapedArrayCodable?
}

let STORAGE_KEY: String = "FurnitureFinderDataCounter"
let IMAGE_PATH: String = "image.png"
let EMBEDDING_PATH: String = "embedding.json"
let ITEMS_PATH: String = "items.json"
let MASK_FOLDER_PATH: String = "masks"

enum StorageError: Error {
    case NewFolderFailed
    case SaveImageFailed
    case SaveEmbeddingFailed
    case SaveItemsFailed
    case SaveMaskFailed
    
    case LoadImageFailed
    case LoadEmbeddingFailed
    case LoadItemsFailed
    case LoadMaskFailed
}
struct BundleLocateResourceFailed: Error {}
struct JSONEncodingError: Error {}
struct pngEncodingFailed: Error {}

class DeviceStorageModel: ObservableObject {
    @Published var userData: [ResultData]
    @Published var didUserLoad: Bool
    
    init () {
        self.userData = []
        self.didUserLoad = false
    }
}

