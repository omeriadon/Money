//
//  SignupView.swift
//  Money
//
//  Created by Adon Omeri on 18/1/2026.
//

import SwiftUI

struct SignupView: View {
	@EnvironmentObject var networkManager: NetworkManager
	@Environment(\.dismiss) var dismiss

	@State var signUpDetails = UserSignupDTO(firstName: "", email: "", password: "")

	@State var confirmPassword = ""

	@State var isLoading = false
	@State var isSuccess = false

	var canSubmit: Bool {
		!(signUpDetails.firstName.count > 30) &&
			signUpDetails.firstName.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) } &&
			isValidEmail(signUpDetails.email) &&
			!(signUpDetails.password.count < 8) &&
			signUpDetails.password == confirmPassword &&

			!signUpDetails.email.isEmpty && !signUpDetails.firstName.isEmpty && !signUpDetails.password.isEmpty
	}

	@State var showAlert = false
	@State var alertTitle = ""
	@State var alertMessage = ""

	var body: some View {
		NavigationStack {
			Form {
				Section {
					TextField("First Name", text: $signUpDetails.firstName)
						.textContentType(.givenName)

				} header: {
					Text("First Name")

				} footer: {
					if signUpDetails.firstName.count > 30 {
						Text("Too long")
							.foregroundStyle(.red)
					}
					if !signUpDetails.firstName.unicodeScalars.allSatisfy({ CharacterSet.letters.contains($0) }) {
						Text("Only letters")
							.foregroundStyle(.red)
					}
				}

				Section {
					TextField("Email", text: $signUpDetails.email)
						.textContentType(.emailAddress)
				} header: {
					Text("Email")

				} footer: {
					if !isValidEmail(signUpDetails.email) && !signUpDetails.email.isEmpty {
						Text("Not a valid email")
							.foregroundStyle(.red)
					}
				}
				Section {
					SecureField("Password", text: $signUpDetails.password)
						.textContentType(.newPassword)
					SecureField("Confirm Password", text: $confirmPassword)
						.textContentType(.newPassword)

				} header: {
					Text("Password")

				} footer: {
					if signUpDetails.password.count < 8 && !signUpDetails.password.isEmpty {
						Text("Passwords should be above 8 characters")
							.foregroundStyle(.red)
					}
					if (signUpDetails.password != confirmPassword) && !confirmPassword.isEmpty {
						Text("Passwords don't match")
							.foregroundStyle(.red)
					}
				}
			}
			.alert(alertTitle, isPresented: $showAlert, actions: {
				Button {} label: {
					Text("OK")
				}
			}, message: { Text(alertMessage) })
			.blur(radius: isLoading ? 10 : 0)
			.animation(.easeInOut, value: isLoading)
			.safeAreaBar(edge: .bottom, alignment: .center, spacing: 30) {
				Button {
					dismissKeyboard()
					isLoading = true
					showAlert = false

					Task {
						do {
							let success = try await networkManager.signup(
								firstName: signUpDetails.firstName,
								email: signUpDetails.email,
								password: signUpDetails.password
							)

							if success {
								withAnimation {
									isSuccess = true
								}

								try? await Task.sleep(nanoseconds: 1_000_000_000)
								withAnimation {
									isSuccess = false
									isLoading = false
								}
							} else {
								isLoading = false
							}

						} catch {
							withAnimation { isLoading = false }
							alertTitle = "Error creating account"
							alertMessage = error.localizedDescription
							showAlert = true
						}
					}

				} label: {
					Text("Submit")
						.padding(.vertical, 10)
						.padding(.horizontal, 15)
						.foregroundStyle(canSubmit ? .black : .primary)
				}
				.buttonStyle(.glassProminent)
				.padding(.bottom)
				.blur(radius: isLoading ? 10 : 0)
				.disabled(!canSubmit)
			}

			.overlay(alignment: .center) {
				if isLoading {
					progressView
				}
			}
			.animation(.easeInOut, value: "\(signUpDetails.firstName)\(signUpDetails.email)\(signUpDetails.password)\(confirmPassword)")
			.toolbar {
				ToolbarItem(placement: .title) {
					Text("Sign Up")
						.fontDesign(.monospaced)
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button(role: .close) {
						dismiss()
					}
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
	SignupView()
}
