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
        let numData = UserDefaults.standard.integer(forKey: DATA_COUNTER_KEY)
        print(numData)
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        for i in 0..<numData  {
            print(i)
            let setFolder = docURL.appendingPathComponent("data_\(i)")
            var storedData = ResultData()
            let numMask = UserDefaults.standard.integer(forKey: "FurnitureFinderMaskCounter_\(i)")
            
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
            if let _ = try? FileManager.default.contentsOfDirectory(at: maskFolderURL,
                                                            includingPropertiesForKeys: nil)
            {
                for idx in 0..<numMask {
                    let url = maskFolderURL.appendingPathComponent("mask_\(idx).png")
                    if let data = try? Data(contentsOf: url),
                       let mask = UIImage(data: data) {
                        storedData.maskList.append(mask)
                    } else {
                        storedData.maskList.append(UIImage())
                    }
                }
            }
            print(numMask)
            print("mask: ", storedData.maskList.count)
            
            let itemsURL = setFolder.appendingPathComponent(ITEMS_PATH)
            if let data = try? Data(contentsOf: itemsURL),
               let decoded = try? JSONDecoder().decode([[SearchItem]].self, from: data) {
                storedData.itemsList = decoded
            } else {
                storedData.itemsList = []
            }
            
            print("items", storedData.itemsList.count)
            
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
