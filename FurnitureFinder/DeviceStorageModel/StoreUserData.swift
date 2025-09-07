//
//  StoreUserData.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 9/6/25.
//

import Foundation
import SwiftUI

extension DeviceStorageModel {
    func storeUserData(resultData: ResultData) throws {
        let currentIndex = UserDefaults.standard.integer(forKey: STORAGE_KEY)
        print(currentIndex)
        let setFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("data_\(currentIndex)")
        do {
            try FileManager.default.createDirectory(at: setFolder, withIntermediateDirectories: true)
        } catch {
            throw StorageError.NewFolderFailed
        }
        
        print("Set")
        
        guard let img = resultData.image else {
            throw StorageError.SaveImageFailed
        }
        
        let imageURL = setFolder.appendingPathComponent(IMAGE_PATH)
        do {
            guard let data = img.pngData() else {
                throw pngEncodingFailed()
            }
            try data.write(to: imageURL)
        } catch {
            throw StorageError.SaveImageFailed
        }
        
        print("image")
        
        let embeddingURL = setFolder.appendingPathComponent(EMBEDDING_PATH)
        do {
            guard let path = Bundle.main.resourceURL else {
                throw BundleLocateResourceFailed()
            }
            let imgEncoder = try! ImgEncoder(resourcesAt: path)
            let imgEmbeddings = try! imgEncoder.computeImgEmbedding(img: img)
            let payload = ShapedArrayCodable(shape: imgEmbeddings.shape, scalars: imgEmbeddings.scalars)
            let data = try JSONEncoder().encode(payload)
            try data.write(to: embeddingURL)
        } catch {
            throw StorageError.SaveEmbeddingFailed
        }
        
        print("embedding")
        
        let maskFolderURL = setFolder.appendingPathComponent(MASK_FOLDER_PATH)
        var idx = 0
        do {
            try FileManager.default.createDirectory(at: maskFolderURL, withIntermediateDirectories: true)
            for mask in resultData.maskList {
                guard let data = mask.pngData() else {
                    print("Encoding failed")
                    throw pngEncodingFailed()
                }
                let maskURL = maskFolderURL.appendingPathComponent("mask_\(idx).png")
                try data.write(to: maskURL)
                idx += 1
            }
        } catch {
            throw StorageError.SaveMaskFailed
        }
        
        print("mask")

        let itemsURL = setFolder.appendingPathComponent(ITEMS_PATH)
        do {
            guard let data = try? JSONEncoder().encode(resultData.itemsList) else {
                throw JSONEncodingError()
            }
            try data.write(to: itemsURL)
        } catch {
            throw StorageError.SaveImageFailed
        }
        
        print("item")
        
        UserDefaults.standard.set(currentIndex + 1, forKey: STORAGE_KEY)
        print(UserDefaults.standard.integer(forKey: STORAGE_KEY))
    }
}
