//
//  SettingsView.swift
//  Money
//
//  Created by Adon Omeri on 19/1/2026.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var transactionRepo: TransactionRepository

    @State private var showAlert = false
    @State private var errorMessage = ""
    @State private var errorTitle = ""

    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false

    @State private var firstName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var passwordConfirm: String = ""

    @State private var isSaving = false
    @State private var saveSuccess = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("First Name", text: $firstName)
                        .autocapitalization(.words)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("New Password", text: $password)
                    SecureField("Confirm Password", text: $passwordConfirm)
                } header: {
                    Text("Account Info")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if firstNameChanged && firstName.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("First name cannot be empty")
                        }
                        if emailChanged && !isValidEmail(email) && !email.isEmpty {
                            Text("Email is not valid")
                        }
                        if passwordChanged && password.count < 8 {
                            Text("Password must be at least 8 characters")
                        }
                        if passwordChanged && password != passwordConfirm {
                            Text("Passwords do not match")
                        }
                    }
                    .foregroundStyle(.red)
                }
                .sectionActions {
                    Button {
                        Task { await updateAccount() }
                    } label: {
                        ZStack {
                            if !isSaving {
                                Text("Save Changes")
                                    .transition(.blurReplace)
                            } else {
                                HStack {
                                    ProgressView()
                                    Text("Saving Changes")
                                }
                                .transition(.blurReplace)
                            }
                        }
                        .animation(.easeInOut, value: isSaving)
                    }
                    .disabled(!canSave)
                }
                .task {
                    await transactionRepo.network.refreshCurrentUser()
                }

                Section("Danger Zone") {
                    Button {
                        showLogoutConfirmation = true
                    } label: {
                        Label("Logout", systemImage: "arrow.right.to.line")
                    }
                    .alert("Logout?", isPresented: $showLogoutConfirmation) {
                        Button(role: .destructive) {
                            Task { try? await transactionRepo.logout() }
                        } label: { Text("Yes") }
                        Button(role: .cancel) {} label: { Text("No") }
                    }

                    Button {
                        showDeleteAccountConfirmation = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                    .alert("Are you sure you want to delete your account?", isPresented: $showDeleteAccountConfirmation) {
                        Button(role: .destructive) {
                            Task { try? await transactionRepo.deleteUser() }
                        } label: { Text("Yes") }
                        Button(role: .cancel) {} label: { Text("No") }
                    } message: { Text("This will permanently delete all your transactions.") }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings").font(.headline)
                }
            }
            .alert(errorTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage) }
            .alert("Success", isPresented: $saveSuccess) {
                Button("OK", role: .cancel) {}
            } message: { Text("Your account has been updated.") }
            .task { loadCurrentUser() }
        }
    }

    // MARK: - Field Change Detection

    private var firstNameChanged: Bool {
        firstName != (transactionRepo.network.firstName ?? "")
    }

    private var emailChanged: Bool {
        email != (transactionRepo.network.email ?? "")
    }

    private var passwordChanged: Bool {
        !password.isEmpty
    }

    // MARK: - Save Button Logic

    private var canSave: Bool {
        let changed = firstNameChanged || emailChanged || passwordChanged
        let validFirstName = !firstNameChanged || !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        let validEmail = !emailChanged || isValidEmail(email)
        let validPassword = !passwordChanged || (password.count >= 8 && password == passwordConfirm)
        return changed && validFirstName && validEmail && validPassword && !isSaving
    }

    private func loadCurrentUser() {
        firstName = transactionRepo.network.firstName ?? ""
        email = transactionRepo.network.email ?? ""
    }

    private func updateAccount() async {
        // Only send changed fields
        var updatePassword: String? = nil
        if passwordChanged {
            guard password == passwordConfirm else {
                errorTitle = "Password Mismatch"
                errorMessage = "The passwords do not match."
                showAlert = true
                return
            }
            updatePassword = password
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await transactionRepo.updateUser(
                firstName: firstNameChanged ? firstName : nil,
                email: emailChanged ? email : nil,
                password: updatePassword
            )
            saveSuccess = true
        } catch {
            errorTitle = "Failed to Update Account"
            errorMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(email.startIndex ..< email.endIndex, in: email)
        let matches = detector?.matches(in: email, options: [], range: range) ?? []
        return matches.count == 1 && matches.first?.url?.scheme == "mailto"
    }
}

#Preview {
    SettingsView()
}
