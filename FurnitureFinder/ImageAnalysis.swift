//
//  ImageAnalysis.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 7/11/25.
//

import SwiftUI
import UIKit
import AVFoundation
import Vision
import CoreML
import Foundation
import CoreImage

/// Errors that can occur during analysis
enum AnalysisError: Error {
    /// The input image couldn’t be prepared for the model (pixel buffer / cgImage conversion failed)
    case DetectionError
}


class ImageAnalysis: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var totalDetections: Int = 0
    @Published var furnitureImages: [Int: UIImage] = [:]
    @Published var furnitureCaptions: [String] = []
    @Published var itemsByIndex: [Int: [SearchItem]] = [:]
    @Published var segmentationMasks: [Int: UIImage] = [:]
    @Published var analysisStarted: Bool = false
    private let detector: FurnitureDetector
    
    init(detector: FurnitureDetector) {
        self.detector = detector
    }
    
    func runAnalysis(on original: UIImage) {
        Task {
            // reset state on main
            await MainActor.run {
                self.isLoading = true
                self.analysisStarted = true
                self.totalDetections   = 0
                self.furnitureImages   = [:]
                self.furnitureCaptions = []
                self.itemsByIndex      = [:]
                self.segmentationMasks = [:]
            }
            try? self.detector.predict(img: original)
            guard let detections = try? self.detector.processDetectionResults() else {
                throw AnalysisError.DetectionError
            }
            guard !detections.isEmpty else {
                await MainActor.run { self.isLoading = false }
                return
            }
            await MainActor.run { self.totalDetections = detections.count }
            guard let originalCG = original.cgImage else {
                await MainActor.run { self.isLoading = false }
                return
            }
            
            for det in detections {
                print(COCOLabels.all[det.cls])
                
                let origImgW = CGFloat(originalCG.width)
                let origImgH = CGFloat(originalCG.height)
                let cropBoxes: [[CGFloat]] = detections.map { det in
                    let segRect = det.rect
                        .applying(.init(scaleX: origImgW, y: origImgH))
                        .intersection(.init(x: 0, y: 0, width: origImgW, height: origImgH))
                    return [segRect.origin.x, segRect.origin.y, segRect.origin.x + segRect.size.width, segRect.origin.y + segRect.size.height]
                }
                /*
                 let masks = await fetchMask(cropImage: original, boxArray: cropBoxes)
                 if let masks {
                 for (idx, mask) in masks.enumerated() {
                 if let mask {
                 self.segmentationMasks[idx] = mask
                 print("Mask added.")
                 }
                 }
                 }
                 */
                await MainActor.run {
                    self.isLoading = false   // if you want to hide your spinner too
                }
                /*
                 // 3) Fire off all masks + Amazon calls in parallel:
                 await withTaskGroup(of: Void.self) { group in
                 for (idx, det) in detections.enumerated() {
                 group.addTask {
                 let resizedImgW = CGFloat(cgImage.width)
                 let resizedImgH = CGFloat(cgImage.height)
                 
                 let origImgW = CGFloat(originalCG.width)
                 let origImgH = CGFloat(originalCG.height)
                 print(det.rect)
                 
                 let cropRect = det.rect
                 .applying(.init(scaleX: resizedImgW, y: resizedImgH))
                 .intersection(.init(x: 0, y: 0, width: resizedImgW, height: resizedImgH))
                 
                 let segRect = det.rect
                 .applying(.init(scaleX: origImgW, y: origImgH))
                 .intersection(.init(x: 0, y: 0, width: origImgW, height: origImgH))
                 
                 guard let cropCG = cgImage.cropping(to: cropRect) else { return }
                 let croppedImage = UIImage(cgImage: cropCG)
                 let label = COCOLabels.all[det.cls]
                 print("Label ", label)
                 
                 // push image+label immediately
                 await MainActor.run {
                 self.furnitureImages[idx] = croppedImage
                 self.furnitureCaptions.append(label)
                 }
                 
                 // do SAM + Amazon in parallel
                 //async let items = self.fetchAmazonItems(label: label)
                 async let mask = fetchMask(cropImage: original, box:
                 
                 let gotMask = await mask
                 
                 // update UI when both done
                 await MainActor.run {
                 // Use the newly fetched mask image (gotMask), not the old stored mask
                 self.segmentationMasks[idx] = gotMask
                 // once we have results for every index, clear the spinner
                 if self.itemsByIndex.count == self.totalDetections {
                 self.isLoading = false
                 }
                 }
                 }
                 }
                 }
                 */
            }
        }
        
    }
    
    //for UI Testing
    func dummyAnalysis() {
        self.analysisStarted = true
        let sofaImage = UIImage(named: "sofa") ?? UIImage()
        let sofaMask = UIImage(named: "sofaMask") ?? UIImage()
        let sofaItems = [
            SearchItem(
                title: "3-Piece Living Room Furniture Sets … Gray Fabric",
                link: "https://www.amazon.com/3-Piece-Furniture-Storage-Loveseat-Decoration/dp/B0CW5NLLQQ/ref=sr_1_10?dib=eyJ2IjoiMSJ9.3UajCXmC_ifXRsvfZt6coIG3LICjCBRabpyLbDH1rDHSsy2ptExddqRvPVLpZCQCu8IElmwduXgoQKwvXZLsKIwQseGkXgSweEsev5k86ReLXxLkSbeYi-F2bpp7v7GevXvocWjhUxYyXnV_lYKRZp4HCuw0yAARzpzBMoLFhmY91yBu1afPjGtIsAET2BrAABcZt6Ju-A5xJ_AbrIsT_vMTB79gNYBdT_a-dTEBxn_XAHA1NLqZv6k9uH0gWO-R1nRmp-6B4-I2RhIH44qgnRYlCAZ_tasw3udX6hLH_pc.VAHSpeCjCnWCfjgWS2OMY-1pPeA1iM5ZNVlKeLxzbgg&dib_tag=se&keywords=silver+gray+couch&qid=1752195662&sr=8-10",
                thumbnail: "https://m.media-amazon.com/images/I/718ZL6KFQAL._AC_UL320_.jpg"
            ),
            SearchItem(
                title: "Modern Sectional Sofa with Storage Ottoman … (Light Gray)",
                link: "https://www.amazon.com/Modern-Sectional-Storage-Ottoman-Nailhead/dp/B0FG7L7VG4/ref=sr_1_5?dib=eyJ2IjoiMSJ9.3UajCXmC_ifXRsvfZt6coIG3LICjCBRabpyLbDH1rDHSsy2ptExddqRvPVLpZCQCu8IElmwduXgoQKwvXZLsKIwQseGkXgSweEsev5k86ReLXxLkSbeYi-F2bpp7v7GevXvocWjhUxYyXnV_lYKRZp4HCuw0yAARzpzBMoLFhmY91yBu1afPjGtIsAET2BrAABcZt6Ju-A5xJ_AbrIsT_vMTB79gNYBdT_a-dTEBxn_XAHA1NLqZv6k9uH0gWO-R1nRmp-6B4-I2RhIH44qgnRYlCAZ_tasw3udX6hLH_pc.VAHSpeCjCnWCfjgWS2OMY-1pPeA1iM5ZNVlKeLxzbgg&dib_tag=se&keywords=silver+gray+couch&qid=1752195662&sr=8-5",
                thumbnail: "https://m.media-amazon.com/images/I/81Xk42uJ4EL._AC_UL320_.jpg"
            )
        ]
        let tvImage = UIImage(named: "tv") ?? UIImage()
        let tvMask = UIImage(named: "tvMask") ?? UIImage()
        let tvItems = [SearchItem(
            title: "TCL 43-Inch Class S3 1080p LED Smart TV with Google TV (43S350G, 2023 Model), Google Assistant Built-in with Voice Remote, Compatible with Alexa, Streaming FHD Television,Black",
            link: "https://www.amazon.com/TCL-43S350G-Assistant-Compatible-Television/dp/B0C1J1YCHL/ref=sr_1_10?dib=eyJ2IjoiMSJ9.19nJQP9j6Q2qPs77LDrtLfnWnjdCPx-AS6neuUOD3E9XYNjYmDn1is_Wv2_QRj3sR8JqLHbST0gKXp6s3ce5a3Q8sgjtArgypMJ4xRlfXf05CZ4pTkWddR9m0-J0tXFbM3eQmzkp0XpQgJY1hd70U0zDkukuIZd7DDODQGw4nUcmJ5xRQIClAHX3MiL0OdtZ381lUVkBT4wE_ux2PAIYHWCmbqGKHR24zL7oxq-1y-c.ZAGVpslfORfmYwFSVEzJ7l9oCRg-57bG5Sg82M0mImA&dib_tag=se&keywords=black+tv&qid=1752197299&sr=8-10",
            thumbnail: "https://m.media-amazon.com/images/I/81ylxtsKamL._AC_UY218_.jpg"
        )]
        
        DispatchQueue.main.async {
            self.furnitureImages[0] = sofaImage
            self.furnitureCaptions.append("sofa")
            self.itemsByIndex[0] = sofaItems
            self.segmentationMasks[0] = sofaMask
            
            self.furnitureImages[1] = tvImage
            self.furnitureCaptions.append("tv")
            self.itemsByIndex[1] = tvItems
            self.segmentationMasks[1] = tvMask
            
            self.isLoading = false
        }
    }
}
