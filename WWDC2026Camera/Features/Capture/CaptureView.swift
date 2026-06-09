import SwiftUI

struct CaptureView: View {
    @Bindable var viewModel: CaptureViewModel

    @State private var accumulatedOffset = CGSize(width: 0, height: OverlayTransform.defaultVerticalOffset)
    @GestureState private var magnification: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                cameraLayer

                GlassOverlayHost(scale: viewModel.overlayScale, showBase: viewModel.showBase)
                    .frame(
                        width: WWDC26ObjectMetrics.unitSize(showBase: viewModel.showBase).width * viewModel.overlayScale,
                        height: WWDC26ObjectMetrics.unitSize(showBase: viewModel.showBase).height * viewModel.overlayScale
                    )
                    .offset(
                        x: viewModel.overlayOffset.width,
                        y: viewModel.overlayOffset.height
                    )
                    .gesture(overlayGestures)
                    .accessibilityLabel("WWDC26 ガラスオブジェクト")

                controlsLayer
            }
            .onAppear {
                viewModel.updatePreviewSize(geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                viewModel.updatePreviewSize(newSize)
            }
        }
        .ignoresSafeArea()
        .task {
            await viewModel.onAppear()
        }
        .onDisappear {
            Task { await viewModel.onDisappear() }
        }
        .alert("エラー", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var cameraLayer: some View {
#if targetEnvironment(simulator)
        SimulatorCameraBackground()
#else
        CameraPreviewView(source: viewModel.previewSource)
#endif
    }

    private var controlsLayer: some View {
        VStack {
            if viewModel.showSaveConfirmation {
                Label("保存しました", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: Capsule())
                    .padding(.top, 60)
            }

            Spacer()

            ZStack {
                Button {
                    Task { await viewModel.capturePhoto() }
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(.white, lineWidth: 4)
                            .frame(width: 78, height: 78)

                        Circle()
                            .fill(.white)
                            .frame(width: 64, height: 64)
                            .opacity(viewModel.isCapturing ? 0.5 : 1.0)
                    }
                }
                .disabled(viewModel.isCapturing)
                .accessibilityLabel("撮影")

                HStack {
                    Spacer()

                    Button {
                        viewModel.toggleBase()
                    } label: {
                        Image(systemName: viewModel.showBase ? "square.3.layers.3d.top.filled" : "square.3.layers.3d")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .glassEffect(.regular, in: Circle())
                    }
                    .accessibilityLabel("台座の表示")
                    .accessibilityValue(viewModel.showBase ? "オン" : "オフ")
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 48)
        }
    }

    private var overlayGestures: some Gesture {
        let drag = DragGesture()
            .onChanged { value in
                let translation = CGSize(
                    width: accumulatedOffset.width + value.translation.width,
                    height: accumulatedOffset.height + value.translation.height
                )
                viewModel.dragChanged(translation: translation)
            }
            .onEnded { value in
                accumulatedOffset = CGSize(
                    width: accumulatedOffset.width + value.translation.width,
                    height: accumulatedOffset.height + value.translation.height
                )
                viewModel.dragChanged(translation: accumulatedOffset)
                viewModel.dragEnded()
            }

        let pinch = MagnificationGesture()
            .updating($magnification) { value, state, _ in
                state = value
                viewModel.magnificationChanged(value)
            }
            .onEnded { value in
                viewModel.magnificationEnded(value)
            }

        return drag.simultaneously(with: pinch)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}

#Preview {
    CaptureContainer()
}
