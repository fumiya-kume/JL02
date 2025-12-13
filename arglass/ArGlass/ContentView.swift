import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HUDViewModel()

    var body: some View {
        HUDRootView(viewModel: viewModel)
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}

