//
//  RepoHolder.swift
//  Money
//
//  Created by Adon Omeri on 21/1/2026.
//

import Combine

final class RepoHolder: ObservableObject {
	@Published var repo: TransactionRepository?
}
