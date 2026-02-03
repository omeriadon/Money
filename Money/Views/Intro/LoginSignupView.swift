//
//  LoginSignupView.swift
//  Money
//
//  Created by Adon Omeri on 18/1/2026.
//

import SwiftUI

struct LoginSignupView: View {
    @EnvironmentObject var networkManager: NetworkManager

    @State var showSignup = false
    @State var showLogin = false

    var body: some View {
        GeometryReader { geo in
            NavigationStack {
                VStack(alignment: .center, spacing: 50) {
                    Spacer()
                    LinearGradient(
                        colors: [Color.yellow, Color.yellow.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .mask(
                        Image("Logo")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    )
                    VStack(spacing: 10) {
                        Text("Money")
                            .font(.largeTitle.scaled(by: 2))
                            .bold()
                        Text("Track money simply and efficiently.")
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 20) {
                        Button {
                            showSignup = true
                        } label: {
                            Text("Sign Up")
                                .padding()
                        }
                        .buttonStyle(.glassProminent)
                        .foregroundStyle(.black)

                        Button {
                            showLogin = true

                        } label: {
                            Text("Login")
                                .padding()
                        }
                        .buttonStyle(.glass)
                    }
                    .frame(width: geo.size.width * 0.8)
                    .buttonSizing(.flexible)
                    .buttonBorderShape(.capsule)
                }
                .fontDesign(.monospaced)
                .sheet(isPresented: $showSignup) {
                    SignupView()
                        .environmentObject(networkManager)
                }
                .sheet(isPresented: $showLogin) {
                    LoginView()
                        .environmentObject(networkManager)
                }
            }
        }
    }
}
