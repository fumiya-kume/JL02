import SwiftUI

extension EdgeInsets {
    var horizontal: CGFloat { leading + trailing }
    var vertical: CGFloat { top + bottom }

    func safeRect(in size: CGSize) -> CGRect {
        CGRect(
            x: leading,
            y: top,
            width: max(0, size.width - horizontal),
            height: max(0, size.height - vertical)
        )
    }
}

extension View {
    func hudHorizontalPadding(_ safeAreaInsets: EdgeInsets, base: CGFloat = 20) -> some View {
        padding(.leading, safeAreaInsets.leading + base)
            .padding(.trailing, safeAreaInsets.trailing + base)
    }
}
