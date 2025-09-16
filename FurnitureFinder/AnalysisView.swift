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
    @EnvironmentObject private var vm: ImageAnalysis
    @EnvironmentObject private var storage: DeviceStorageModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var isPickerPresented: Bool
    @State private var selectedIndex: Int?
    @State private var selectedMaskIndex: Int?
    @State private var isShowingResult: Bool
    @State var showErrorAlert: Bool
    @State var errorMessage: String
    
    init() {
        self._selectedItem = State(initialValue: nil)
        self._isPickerPresented = State(initialValue: true)
        self._isShowingResult = State(initialValue: false)
        self._errorMessage = State(initialValue: "")
        self._showErrorAlert = State(initialValue: false)
    }
    
    var body: some View {
        NavigationView{
            GeometryReader { geo in
                VStack(spacing: 0) {
                    if let img = vm.data.image {
                        MaskedImageView(
                            baseImage: img,
                            masks: vm.data.maskList,
                            //show the mask only if segmentationMasks array is not empty and execution is finished.
                            maskReady: !vm.data.maskList.isEmpty && (!vm.isLoading && vm.analysisStarted),
                            onMaskTap: { idx in
                                selectedIndex = idx
                            }
                        )
                        .frame(
                            width: geo.size.width,
                            height: geo.size.height / 2
                        )
                    }
                    else {
                        ZStack {
                            // gray placeholder background
                            Rectangle()
                                .fill(Color(UIColor.systemGray5))
                                .frame(width: geo.size.width, height: geo.size.height / 2)
                            
                            // hint content
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 40))
                                    .opacity(0.6)
                                Text("Upload an image")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { isPickerPresented = true }
                    }
                    Divider()
                    //Executing Analysis/Loading View
                    if vm.isLoading {
                        VStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.5)
                            Spacer()
                        }
                        .frame(height: geo.size.height / 2)
                    }
                    
                    //Pre-analysis View
                    if (!vm.analysisStarted && !vm.isLoading) {
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
                                        vm.data.image = ui
                                    }
                                }
                            }
                            
                            Button("Analyze") {
                                Task {
                                    do {
                                        try await vm.runAnalysis()
                                    } catch {
                                        errorMessage = "Sorry, something went wrong while analyzing an image."
                                        showErrorAlert = true
                                    }
                                }
                            }
                            .disabled(vm.data.image == nil)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(vm.data.image == nil ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .errorAlert(title: "Analyze",
                                        isPresented: $showErrorAlert,
                                        message: errorMessage)
                        }
                        .padding()
                        .frame(height: geo.size.height / 2)
                        
                    }
                    //Post-analysis View
                    else if (vm.analysisStarted && !vm.isLoading) {
                        
                        Button("Save") {
                            do {
                                try storage.storeUserData(resultData: vm.data)
                            } catch {
                                errorMessage = "Sorry, something went wrong while saving your data. Please try again later."
                                showErrorAlert = true
                            }
                        }
                        .errorAlert(title: "Save",
                                    isPresented: $showErrorAlert,
                                    message: errorMessage)
                        
                        Button("Return Home") {
                            vm.analysisStarted = false
                            vm.isLoading = false
                            vm.data = ResultData()
                            
                            dismiss()
                        }
                        
                    }
                }
                .sheet(item: $selectedIndex, onDismiss: { selectedIndex = nil }) { idx in
                    ProductsView(
                        items: vm.data.itemsList[idx],
                        dismiss: { selectedIndex = nil }
                    )
                }
            }
            .navigationTitle("Furniture Finder")
        }
    }
}

extension View {
    func errorAlert(title: String,
                    isPresented: Binding<Bool>,
                    message: String) -> some View {
        self.alert(title, isPresented: isPresented, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(message)
        })
    }
}
