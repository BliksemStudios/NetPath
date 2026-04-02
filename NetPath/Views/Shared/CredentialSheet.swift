import SwiftUI

struct CredentialSheet: View {
    let server: String
    let onSubmit: (String, String, String, Bool) async -> Void
    let onCancel: () -> Void

    @State private var domain: String
    @State private var username = ""
    @State private var password = ""
    @State private var saveToKeychain = true
    @State private var isSubmitting = false

    init(server: String,
         onSubmit: @escaping (String, String, String, Bool) async -> Void,
         onCancel: @escaping () -> Void) {
        self.server = server
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self._domain = State(initialValue: server.domainPrefix)
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 32))
                    .foregroundStyle(Design.Colors.accent)
                Text("Connect to \(server)")
                    .font(.headline)
            }

            Form {
                TextField("Domain", text: $domain)
                    .textFieldStyle(.roundedBorder)
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                Toggle("Save to Keychain", isOn: $saveToKeychain)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Connect") {
                    isSubmitting = true
                    Task {
                        await onSubmit(domain, username, password, saveToKeychain)
                        isSubmitting = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(username.isEmpty || password.isEmpty || isSubmitting)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
