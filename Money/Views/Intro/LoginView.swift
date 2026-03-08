import SwiftUI

struct LoginView: View {
	@EnvironmentObject var networkManager: NetworkManager
	@Environment(\.dismiss) var dismiss

	@State private var loginDetails = UserLoginDTO(email: "", password: "")
	@State private var isLoading = false
	@State private var isSuccess = false

	@State private var showAlert = false
	@State private var alertTitle = ""
	@State private var alertMessage = ""

	@FocusState private var focusedField: Field?

	enum Field: Hashable {
		case email
		case password
	}

	var canSubmit: Bool {
		isValidEmail(loginDetails.email) &&
			loginDetails.password.count >= 8 &&
			!loginDetails.email.isEmpty && !loginDetails.password.isEmpty
	}

	var body: some View {
		NavigationStack {
			List {
				Section {
					TextField("Email", text: $loginDetails.email)
						.textContentType(.emailAddress)
						.keyboardType(.emailAddress)
						.focused($focusedField, equals: .email)
						.submitLabel(.next)
						.onSubmit { focusedField = .password }
				} header: {
					Text("Email")
				} footer: {
					if !isValidEmail(loginDetails.email), !loginDetails.email.isEmpty {
						Text("Not a valid email")
							.foregroundStyle(.red)
					}
				}

				Section {
					SecureField("Password", text: $loginDetails.password)
						.textContentType(.password)
						.focused($focusedField, equals: .password)
						.submitLabel(.go)
						.onSubmit { attemptLogin() }
				} header: {
					Text("Password")
				} footer: {
					if loginDetails.password.count < 8, !loginDetails.password.isEmpty {
						Text("Password should be at least 8 characters")
							.foregroundStyle(.red)
					}
				}
			}
			.alert(alertTitle, isPresented: $showAlert, actions: {
				Button("OK") {}
			}, message: { Text(alertMessage) })
			.blur(radius: isLoading ? 20 : 0)
			.animation(.smooth, value: isLoading)
			.safeAreaBar(edge: .bottom, alignment: .center, spacing: 30) {
				Button {
					attemptLogin()
				} label: {
					Text("Log In")
						.padding(.vertical, 10)
						.padding(.horizontal, 15)
						.foregroundStyle(canSubmit ? .black : .primary)
				}
				.buttonStyle(.glassProminent)
				.padding(.bottom)
				.blur(radius: isLoading ? 20 : 0)
				.animation(.smooth, value: isLoading)
				.disabled(!canSubmit)
			}
			.overlay(alignment: .center) {
				if isLoading { progressView }
			}
			.animation(.smooth, value: "\(loginDetails.email)\(loginDetails.password)")
			.toolbar {
				ToolbarItem(placement: .title) {
					Text("Log In")
						.fontDesign(.monospaced)
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button(role: .close) { dismiss() }
				}
			}
			.onAppear {
				focusedField = .email
			}
		}
		#if os(iOS)
		.enableInjection()
		#endif
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif

	@ViewBuilder
	var progressView: some View {
		if isSuccess {
			Image(systemName: "checkmark")
				.scaleEffect(2)
				.tint(.accent)
				.transition(.blurReplace)
		} else {
			ProgressView()
				.scaleEffect(2)
				.transition(.blurReplace)
		}
	}

	private func attemptLogin() {
		focusedField = nil
		isLoading = true
		showAlert = false

		Task { @MainActor in
			do {
				try await networkManager.login(
					email: loginDetails.email,
					password: loginDetails.password
				)

				withAnimation {
					isSuccess = true
				}

				try await Task.sleep(for: .seconds(1.5))
				isLoading = false
				dismiss()

			} catch {
				isLoading = false
				alertTitle = "Login Failed"
				alertMessage = error.localizedDescription
				showAlert = true
			}
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
	LoginView()
}
