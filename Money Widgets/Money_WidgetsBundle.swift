//
//  Money_WidgetsBundle.swift
//  Money Widgets
//
//  Created by Adon Omeri on 12/2/2026.
//

import SwiftUI
import WidgetKit

@main
struct Money_WidgetsBundle: WidgetBundle {
	var body: some Widget {
		Money_WidgetsSimple()
		Money_WidgetsDetailed()
		Money_WidgetsChart()
		Money_WidgetsGoalGauge()
	}
}
