import ColorfulX
import Defaults
import Inject
import SwiftUI

struct WhatsNewSheetView: View {
	@ObserveInjection var inject

	@Environment(\.dismiss) var dismiss

	let release: WhatsNewRelease
	let items: [WhatsNewItem]
	var showAll: Bool = false

	@Binding var showSheet: Bool

	@State private var colourfulColors: [Color] = [.black, .yellow, .black, .yellow, .white]
	@State private var colourfulSpeed: Double = 1.8
	@State private var colourfulBias: Double = 0.015
	@State private var colourfulNoise: Double = 50.0
	@State private var colourfulTransition: Double = 10.0
	@State private var frameLimit: Int = 120
	@State private var renderScale: Double = 1.0
	@State private var scrolledRelease: WhatsNewRelease?

	private var allReleases: [(WhatsNewRelease, [WhatsNewItem])] {
		WhatsNewReleaseCatalog.sortedReleases.reversed().compactMap { r in
			guard let i = WhatsNewReleaseCatalog.items(for: r) else { return nil }
			return (r, i)
		}
	}

	var body: some View {
		NavigationStack {
			ZStack {
				ColorfulView(
					color: $colourfulColors,
					speed: $colourfulSpeed,
					bias: $colourfulBias,
					noise: $colourfulNoise,
					transitionSpeed: $colourfulTransition,
					frameLimit: $frameLimit,
					renderScale: $renderScale
				)
				.opacity(0.5)
				.saturation(1.2)

				if showAll {
					allReleasesView
				} else {
					singleReleaseView(release: release, items: items)
				}
			}
			.ignoresSafeArea()
		}
		#if os(iOS)
		.enableInjection()
		#endif
	}

	// MARK: - Single release (existing behaviour)

	func singleReleaseView(release: WhatsNewRelease, items: [WhatsNewItem]) -> some View {
		ScrollView {
			Spacer().frame(height: 50)
			itemList(items)
				.padding()
		}
		.scrollIndicatorsFlash(onAppear: true)
		.scrollBounceBehavior(.basedOnSize)
		.safeAreaBar(edge: .bottom, alignment: .center, spacing: 10) {
			dismissButton
		}
		.safeAreaBar(edge: .top, alignment: .center) {
			releaseHeader(release: release)
		}
	}

	// MARK: - All releases

	var allReleasesView: some View {
		NavigationStack {
			ScrollView {
				Spacer()
					.frame(height: 50)

				if let r = scrolledRelease, let i = allReleases.first(where: { $0.0 == r })?.1 {
					VStack(alignment: .leading, spacing: 14) {
						itemList(i)
					}
					.padding()
					.transition(.opacity)
				}
			}
			.scrollBounceBehavior(.basedOnSize)
			.animation(.easeInOut, value: scrolledRelease)
			.onAppear { scrolledRelease = allReleases.first?.0 }
			.safeAreaBar(edge: .top, alignment: .center) {
				VStack(spacing: 15) {
					Image("Logo")
						.renderingMode(.template)
						.resizable()
						.aspectRatio(contentMode: .fit)
						.foregroundStyle(.white)
						.frame(maxWidth: 100)
						.padding(24)
						.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 35))

					if let r = scrolledRelease {
						Text("v\(r.version) (\(r.build))")
							.font(.title2.bold())
							.contentTransition(.numericText())
							.animation(.spring(duration: 0.3), value: scrolledRelease)
					}
				}
				.padding(.top, 30)
			}
			.toolbar {
				ToolbarItem(placement: .status) {
					HStack(spacing: 12) {
						Menu {
							ForEach(allReleases, id: \.0.id) { r, _ in
								Button {
									scrolledRelease = r
								} label: {
									Label {
										Text("v\(r.version) (\(r.build))")
									} icon: {
										Image("Logo")
											.renderingMode(.template)
											.resizable()
											.aspectRatio(contentMode: .fit)
									}
									if r == scrolledRelease {
										Image(systemName: "checkmark")
									}
								}
							}
						} label: {
							Label {
								if let r = scrolledRelease {
									Text("v\(r.version) (\(r.build))")
								}
							} icon: {
								Image("Logo")
									.renderingMode(.template)
									.resizable()
									.aspectRatio(contentMode: .fit)
							}
						}

						dismissButton
					}
				}
			}
		}
	}

	// MARK: - Shared components

	func releaseHeader(release: WhatsNewRelease) -> some View {
		VStack(spacing: 15) {
			Image("Logo")
				.renderingMode(.template)
				.resizable()
				.aspectRatio(contentMode: .fit)
				.foregroundStyle(.white)
				.frame(maxWidth: 100)
				.padding(24)
				.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 35))
			Text(showAll ? "All Releases" : "What's New - \(release.version) (\(release.build))")
				.font(.title2.bold())
		}
		.padding(.top, 30)
	}

	func itemList(_ items: [WhatsNewItem]) -> some View {
		VStack(alignment: .leading, spacing: 14) {
			ForEach(items) { item in
				HStack(alignment: .center, spacing: 12) {
					Image(systemName: item.symbolName)
						.resizable()
						.scaledToFit()
						.frame(width: 40, height: 40)
						.padding(15)
						.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 20))
					VStack(alignment: .leading, spacing: 4) {
						Text(item.title).font(.headline).bold()
						Text(item.description).font(.subheadline)
					}
				}
			}
		}
	}

	var dismissButton: some View {
		Button {
			showSheet = false
		} label: {
			Text("OK")
				.font(.title2)
				.padding(.vertical, 4)
		}
		.frame(maxWidth: .infinity)
		.buttonStyle(.glassProminent)
		.foregroundStyle(.black)
		.buttonSizing(.flexible)
		.buttonBorderShape(.capsule)
		.padding(25)
	}
}
