import SwiftUI

struct ContentView: View {
    @EnvironmentObject var transactionRepo: TransactionRepository

    @State var currentTab = TabItem.home

    let generator = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        TabView(selection: $currentTab) {
            ForEach(TabItem.allCases) { tab in
                Tab(value: tab) {
                    tab.view
                } label: {
                    Label(tab.title, systemImage: tab.symbol)
                        .fontDesign(.monospaced)
                }
            }
        }

        .onChange(of: currentTab) {
            generator.impactOccurred(intensity: 1)
            generator.prepare()
        }
        .onAppear {
            generator.prepare()
        }
        .task {
            await transactionRepo.network.refreshCurrentUser()
        }
    }
}

enum TabItem: CaseIterable, Identifiable {
    case home, list, analyse, settings

    var id: String { title }

    var title: String {
        switch self {
        case .home:
            "Money"
        case .list:
            "Transactions"
        case .settings:
            "Settings"
        case .analyse:
            "Analyse"
        }
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .home:
            HomeView()
        case .list:
            ListView()
        case .settings:
            SettingsView()
        case .analyse:
            AnalyseView()
        }
    }

    var symbol: String {
        switch self {
        case .home:
            "house"
        case .list:
            "mail.stack"
        case .settings:
            "gearshape"
        case .analyse:
            "magnifyingglass"
        }
    }
}
