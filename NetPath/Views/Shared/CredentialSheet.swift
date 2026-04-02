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
    @FocusState private var focusedField: Field?

    enum Field { case domain, username, password }

    init(server: String,
         onSubmit: @escaping (String, String, String, Bool) async -> Void,
         onCancel: @escaping () -> Void) {
        self.server = server
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self._domain = State(initialValue: server.domainPrefix)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 16))
                    .foregroundStyle(Design.Colors.accent)
                Text("Connect to \(server)")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.bottom, 4)

            // Fields
            VStack(spacing: 8) {
                HStack {
                    Text("Domain")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .trailing)
                    TextField("CORP", text: $domain)
                        .textFieldStyle(.roundedBorder)
                        .font(Design.Fonts.pathMono)
                        .focused($focusedField, equals: .domain)
                }

                HStack {
                    Text("Username")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .trailing)
                    TextField("username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .font(Design.Fonts.pathMono)
                        .focused($focusedField, equals: .username)
                }

                HStack {
                    Text("Password")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .trailing)
                    SecureField("", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .password)
                        .onSubmit { submit() }
                }
            }

            // Options + buttons
            HStack {
                Toggle("Save to Keychain", isOn: $saveToKeychain)
                    .font(.system(size: 12))
                    .toggleStyle(.checkbox)

                Spacer()

                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.cancelAction)

                Button("Connect") { submit() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(username.isEmpty || password.isEmpty || isSubmitting)
                    .buttonStyle(.borderedProminent)
                    .tint(Design.Colors.accent)
            }
            .padding(.top, 4)
        }
        .padding(Design.Launcher.inputPadding)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .username
            }
        }
    }

    private func submit() {
        guard !username.isEmpty, !password.isEmpty, !isSubmitting else { return }
        isSubmitting = true
        Task {
            await onSubmit(domain, username, password, saveToKeychain)
            isSubmitting = false
        }
    }
}
