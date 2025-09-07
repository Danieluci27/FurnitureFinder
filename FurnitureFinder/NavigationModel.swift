//
//  NavigationModel.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 7/26/25.
//

import Foundation
import SwiftUI


class NavigationModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedMasks: [UIImage] = []
    @Published var selectedItems: [[SearchItem]] = []
    @Published var masksReady: Bool = true
}
