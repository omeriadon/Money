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
                Section("Account Info") {
                    TextField("First Name", text: $firstName)
                        .autocapitalization(.words)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("New Password", text: $password)
                    SecureField("Confirm Password", text: $passwordConfirm)
                }
                .sectionActions {
                    Button("Save Changes") {
                        Task {
                            await updateAccount()
                        }
                    }
                    .disabled(
                        isSaving
                            || transactionRepo.network.firstName == firstName
                            || transactionRepo.network.email == email
                            || password == ""
                    )
                }
                .alert("Success", isPresented: $saveSuccess) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your account has been updated.")
                }

                Section("Danger Zone") {
                    Button {
                        showLogoutConfirmation = true
                    } label: {
                        Label("Logout", systemImage: "arrow.right.to.line")
                    }
                    .alert("Logout?", isPresented: $showLogoutConfirmation) {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    try await transactionRepo.logout()
                                } catch {
                                    errorTitle = "Failed to Logout"
                                    errorMessage = error.localizedDescription
                                    showAlert = true
                                }
                            }
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
                            Task {
                                do {
                                    try await transactionRepo.deleteUser()
                                } catch {
                                    errorTitle = "Failed to Delete Account"
                                    errorMessage = error.localizedDescription
                                    showAlert = true
                                }
                            }
                        } label: { Text("Yes") }
                        Button(role: .cancel) {} label: { Text("No") }
                    } message: {
                        Text("This will permanently delete all your transactions.")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings").font(.headline)
                }
            }
            .alert(errorTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                loadCurrentUser()
            }
        }
    }

    private func loadCurrentUser() {
        firstName = transactionRepo.network.firstName ?? ""
        email = transactionRepo.network.email ?? ""
    }

    private func updateAccount() async {
        guard password == passwordConfirm else {
            errorTitle = "Password Mismatch"
            errorMessage = "The passwords do not match."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await transactionRepo.updateUser(
                firstName: firstName,
                email: email,
                password: password.isEmpty ? nil : password
            )
            saveSuccess = true
        } catch {
            errorTitle = "Failed to Update Account"
            errorMessage = error.localizedDescription
            showAlert = true
        }
    }
}

#Preview {
    SettingsView()
}
