//
//  LoginView.swift
//  Money
//
//  Created by Adon Omeri on 18/1/2026.
//

import SwiftUI

struct LoginView: View {
	@EnvironmentObject var networkManager: NetworkManager
	@Environment(\.dismiss) var dismiss

	@State var loginDetails = UserLoginDTO(email: "", password: "")

	@State var isLoading = false
	@State var isSuccess = false

	var canSubmit: Bool {
		isValidEmail(loginDetails.email) &&
			!(loginDetails.password.count < 8) &&
			!loginDetails.email.isEmpty && !loginDetails.password.isEmpty
	}

	@State var showAlert = false
	@State var alertTitle = ""
	@State var alertMessage = ""

	var body: some View {
		NavigationStack {
			Form {
				Section {
					TextField("Email", text: $loginDetails.email)
						.textContentType(.emailAddress)
						.keyboardType(.emailAddress)
				} header: {
					Text("Email")
				} footer: {
					if !isValidEmail(loginDetails.email) && !loginDetails.email.isEmpty {
						Text("Not a valid email")
							.foregroundStyle(.red)
					}
				}

				Section {
					SecureField("Password", text: $loginDetails.password)
						.textContentType(.password)
				} header: {
					Text("Password")
				} footer: {
					if loginDetails.password.count < 8 && !loginDetails.password.isEmpty {
						Text("Password should be at least 8 characters")
							.foregroundStyle(.red)
					}
				}
			}
			.alert(alertTitle, isPresented: $showAlert, actions: {
				Button {} label: { Text("OK") }
			}, message: { Text(alertMessage) })
			.blur(radius: isLoading ? 20 : 0)
			.animation(.easeInOut, value: isLoading)
			.safeAreaBar(edge: .bottom, alignment: .center, spacing: 30) {
				Button {
					dismissKeyboard()
					isLoading = true
					showAlert = false

					Task {
						do {
							let success = try await networkManager.login(
								email: loginDetails.email,
								password: loginDetails.password
							)

							if success {
								withAnimation { isSuccess = true }
								try? await Task.sleep(nanoseconds: 1_000_000_000)
								withAnimation {
									isSuccess = false
									isLoading = false
									dismiss()
								}
							} else {
								isLoading = false
							}
						} catch {
							withAnimation { isLoading = false }
							alertTitle = "Login Failed"
							alertMessage = error.localizedDescription
							showAlert = true
						}
					}

				} label: {
					Text("Log In")
						.padding(.vertical, 10)
						.padding(.horizontal, 15)
						.foregroundStyle(canSubmit ? .black : .primary)
				}
				.buttonStyle(.glassProminent)
				.padding(.bottom)
				.blur(radius: isLoading ? 20 : 0)
				.disabled(!canSubmit)
			}

			.overlay(alignment: .center) {
				if isLoading {
					progressView
				}
			}

			.animation(.easeInOut, value: "\(loginDetails.email)\(loginDetails.password)")
			.toolbar {
				ToolbarItem(placement: .title) {
					Text("Log In")
						.fontDesign(.monospaced)
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button(role: .close) { dismiss() }
				}
			}
		}
	}

	@ViewBuilder
	var progressView: some View {
		if isSuccess {
			Image(systemName: "checkmark")
				.imageScale(.large)
				.tint(.accent)
				.transition(.blurReplace)
		} else {
			ProgressView()
				.scaleEffect(2)
				.transition(.blurReplace)
		}
	}

	func isValidEmail(_ email: String) -> Bool {
		let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
		let range = NSRange(email.startIndex ..< email.endIndex, in: email)
		let matches = detector?.matches(in: email, options: [], range: range) ?? []
		return matches.count == 1 && matches.first?.url?.scheme == "mailto"
	}
}

#Preview {
	LoginView()
}
