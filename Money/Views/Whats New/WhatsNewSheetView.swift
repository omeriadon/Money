import ColorfulX
import Defaults
import Inject
import SwiftUI

struct WhatsNewBackground: UIViewRepresentable {
	func makeUIView(context _: Context) -> some UIView {
		let host = UIHostingController(rootView: _BackgroundContent())
		host.view.backgroundColor = .clear
		return host.view
	}

	func updateUIView(_: UIViewType, context _: Context) {}
}

private struct _BackgroundContent: View {
	@State private var colors: [Color] = [.black, .yellow, .black, .yellow, .white]
	@State private var speed: Double = 1.8
	@State private var bias: Double = 0.015
	@State private var noise: Double = 50.0
	@State private var transition: Double = 10.0
	@State private var frameLimit: Int = 120
	@State private var renderScale: Double = 1.0

	var body: some View {
		ColorfulView(
			color: $colors,
			speed: $speed,
			bias: $bias,
			noise: $noise,
			transitionSpeed: $transition,
			frameLimit: $frameLimit,
			renderScale: $renderScale
		)
		.opacity(0.5)
		.saturation(1.2)
		.ignoresSafeArea()
	}
}

struct WhatsNewSheetView: View {
	@ObserveInjection var inject

	@Environment(\.dismiss) var dismiss

	let release: WhatsNewRelease
	let items: [WhatsNewItem]
	var showAll: Bool = false

	@Binding var showSheet: Bool

	@State private var allReleases: [(WhatsNewRelease, [WhatsNewItem])] = []
	@State private var scrolledRelease: WhatsNewRelease?

	init(
		release: WhatsNewRelease,
		items: [WhatsNewItem],
		showAll: Bool = false,
		showSheet: Binding<Bool>
	) {
		self.release = release
		self.items = items
		self.showAll = showAll
		_showSheet = showSheet

		let releases: [(WhatsNewRelease, [WhatsNewItem])] = WhatsNewReleaseCatalog.sortedReleases.reversed().compactMap { r in
			guard let releaseItems = WhatsNewReleaseCatalog.items(for: r) else { return nil }
			return (r, releaseItems)
		}

		_allReleases = State(initialValue: releases)
		_scrolledRelease = State(initialValue: releases.first?.0)
	}

	var body: some View {
		ZStack {
			WhatsNewBackground()

			if showAll {
				allReleasesView
			} else {
				singleReleaseView(release: release, items: items)
			}
		}
		.ignoresSafeArea()

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
		ScrollView {
			VStack(alignment: .leading, spacing: 0) {
				Spacer()
					.frame(height: 50)

				if let r = scrolledRelease, let i = allReleases.first(where: { $0.0 == r })?.1 {
					VStack(alignment: .leading, spacing: 14) {
						itemList(i)
					}
					.id(r.id)
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
					.transition(.asymmetric(
						insertion: .move(edge: .trailing).combined(with: .opacity),
						removal: .move(edge: .leading).combined(with: .opacity)
					))
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
		.scrollBounceBehavior(.basedOnSize)
		.animation(.easeInOut(duration: 0.18), value: scrolledRelease)
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
		.safeAreaBar(edge: .bottom, alignment: .center) {
			HStack(spacing: 12) {
				Menu {
					ForEach(allReleases, id: \.0.id) { r, _ in
						Button {
							withAnimation(.easeInOut(duration: 0.18)) {
								scrolledRelease = r
							}
						} label: {
							Label {
								Text("\(r.version) (\(r.build))")
							} icon: {
								Image(systemName: r == scrolledRelease ? "checkmark.circle.fill" : "circle")
							}
						}
					}
				} label: {
					HStack(spacing: 6) {
						Image("Logo")
							.renderingMode(.template)
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(height: 20)
						Text(scrolledRelease.map { "\($0.version) (\($0.build))" } ?? "Select Release")
						Image(systemName: "chevron.up.chevron.down")
					}
					.font(.title2)
					.padding(8)
				}
				.glassEffect(.regular.interactive(), in: .capsule)

				dismissButton
			}
			.padding(showAll ? 25 : 0)
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
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	var dismissButton: some View {
		Button {
			showSheet = false
		} label: {
			Text("OK")
				.font(.title2)
		}
		.frame(maxWidth: .infinity)
		.buttonStyle(.glassProminent)
		.foregroundStyle(.black)
		.buttonBorderShape(.capsule)
		.buttonSizing(.flexible)
		.padding(showAll ? 0 : 25)
	}
}
