//
//  Device.swift
//  Money
//
//  Created by Adon Omeri on 21/1/2026.
//

import Foundation

func isiPhone() -> Bool {
	#if os(iOS)
		return true
	#else
		return false
	#endif
}
