import SwiftUI

struct CustomBackButton: View {
    @Environment(\.dismiss) private var dismiss
    var label: String = "Back"
    var body: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text(label)
            }
            .font(.headline)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}
