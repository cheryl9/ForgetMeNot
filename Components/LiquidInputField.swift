import SwiftUI

struct LiquidInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "aaaaaa"))
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(Color(hex: "555555"))
            } else {
                TextField(placeholder, text: $text)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(Color(hex: "555555"))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            Capsule()
                .fill(Color(hex: "efefef").opacity(0.9))
        )
    }
}