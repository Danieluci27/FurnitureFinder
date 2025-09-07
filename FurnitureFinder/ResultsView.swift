import SwiftUI

struct ResultsView: View {
    let image: UIImage?
    let masks: [UIImage]
    let masksReady: Bool
    let items: [[SearchItem]]
    @State private var selectedIndex: Int? = nil
    @State private var showInstruction: Bool = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                if let img = image {
                    MaskedImageView(
                        baseImage: img,
                        masks: masks,
                        maskReady: masksReady,
                        onMaskTap: { tappedIdx in
                            selectedIndex = tappedIdx
                        }
                    )
                    .frame(width: geo.size.width, height: geo.size.height / 2)
                } else {
                    Text("No image loaded.")
                        .frame(height: geo.size.height / 2)
                }
                if masksReady {
                    ZStack {
                        Image("robot")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .position(x: 60, y: geo.size.height / 2 - 40)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showInstruction.toggle()
                                print(showInstruction)
                            }

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
            }
            .onAppear {
                showInstruction = false
            }
            .sheet(item: $selectedIndex, onDismiss: {selectedIndex = nil}) { idx in
                    ProductsView(items: items[idx],
                                dismiss: { selectedIndex = nil })
            }
        }
    }
}
