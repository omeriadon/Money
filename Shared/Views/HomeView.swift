
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var transactionRepo: TransactionRepository

    var total: Double {
        transactionRepo.transactions.reduce(0) { $0 + $1.change }
    }

    @State private var didSyncOnce = false
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showAddTransaction = false

    var body: some View {
        NavigationStack {
            VStack {
                Text(total.formatted(.currency(code: "AUD")))
                    .padding(.horizontal)
                    .font(.system(size: 300))
                    .lineLimit(1)
                    .minimumScaleFactor(0.01)
                    .contentTransition(.numericText())
                    .task {
                        if !didSyncOnce {
                            didSyncOnce = true
                            await refresh()
                        }
                    }
            }
            #if !os(iOS)
            .containerBackground(total < 0 ? Color.red.gradient : Color.clear.gradient, for: .tabView)
            .navigationTitle(Text("Money"))
            #else
            .containerBackground(total < 0 ? Color.red.gradient : Color.clear.gradient, for: .navigation)
            #endif
            .toolbar { toolbarContent }
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .title) {
                        Text("Money")
                    }
                #endif

                ToolbarItem(placement: isiPhone() == true ? .topBarTrailing : .bottomBar) {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Label("Add Transaction", systemImage: "plus")
                    }
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(.black)
                }

                #if os(iOS)
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                #endif

                ToolbarItem(placement: .topBarTrailing) {
                    RefreshButton(isLoading: $isLoading, showSuccess: $showSuccess) {
                        await refresh()
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                TransactionDetailView(isNew: true)
                    .presentationDragIndicator(.hidden)
            }
        }
    }

    private func refresh() async {
        do {
            isLoading = true
            try await transactionRepo.syncTransactions()
            showSuccess = true
            Task {
                try? await Task.sleep(for: .seconds(1))
                showSuccess = false
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
