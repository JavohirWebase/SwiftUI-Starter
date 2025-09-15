import SwiftUI

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var focused: FocusState<SignInView.Field?>.Binding
    let field: SignInView.Field
    var onSubmit: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .padding()
                .frame(height: 52)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused(focused, equals: field)
                .submitLabel(field == .username ? .next : .done)
                .onSubmit(onSubmit)
        }
    }
}

struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var focused: FocusState<SignInView.Field?>.Binding
    let field: SignInView.Field
    var onSubmit: () -> Void = {}
    
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            
            HStack {
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .focused(focused, equals: field)
                .submitLabel(.done)
                .onSubmit(onSubmit)
                
                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(height: 52)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}
