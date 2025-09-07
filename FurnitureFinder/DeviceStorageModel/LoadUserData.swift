//
//  LoadUserData.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 9/6/25.
//

import Foundation
import SwiftUI

extension DeviceStorageModel {
    func loadUserData() throws {
        let numData = UserDefaults.standard.integer(forKey: STORAGE_KEY)
        print(numData)
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        for i in 0..<numData  {
            print(i)
            let setFolder = docURL.appendingPathComponent("data_\(i)")
            var storedData = ResultData()
            
            let imageURL = setFolder.appendingPathComponent(IMAGE_PATH)
            
            print("Loading image from:", imageURL.path)
            print("Folder exists:", (try? setFolder.checkResourceIsReachable()) ?? false)
            print("File exists:", FileManager.default.fileExists(atPath: imageURL.path))
            
            guard let data = try? Data(contentsOf: imageURL),
                  let image = UIImage(data: data) else {
                throw StorageError.LoadImageFailed
            }
            storedData.image = image
            
            print("image")
            
            //TO-DO: Use Image Compression Algorithm to allow more mask counts.
            let maskFolderURL = setFolder.appendingPathComponent(MASK_FOLDER_PATH)
            if let files = try? FileManager.default.contentsOfDirectory(at: maskFolderURL,
                                                                        includingPropertiesForKeys: nil)
            {
                for url in files where url.pathExtension.lowercased() == "png" {
                    if let data = try? Data(contentsOf: url),
                       let mask = UIImage(data: data) {
                        storedData.maskList.append(mask)
                    }
                }
            }
            
            print("mask")
            
            let itemsURL = setFolder.appendingPathComponent(ITEMS_PATH)
            if let data = try? Data(contentsOf: itemsURL),
               let decoded = try? JSONDecoder().decode([SearchItem].self, from: data) {
                storedData.itemsList.append(decoded)
            } else {
                storedData.itemsList.append([])
            }
            
            print("items")
            
            let embeddingURL = setFolder.appendingPathComponent(EMBEDDING_PATH)
            if let data = try? Data(contentsOf: embeddingURL),
               let decoded = try? JSONDecoder().decode(ShapedArrayCodable.self, from: data) {
                storedData.embedding = decoded
            } else {
                storedData.embedding = nil
            }
            
            self.userData.append(storedData)
            
            print("embeddings")
            
            self.didUserLoad = true
        }
    }
}
