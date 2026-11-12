#if DEBUG
import SwiftUI

/// Test builds only: ways to reach and force things that otherwise depend on
/// the time, the season, the date or a run of taps. Never in a release build.
struct DeveloperView: View {
    @EnvironmentObject private var sample: SampleFamily
    @AppStorage("debugScene") private var scene = ""
    @AppStorage("debugMonth") private var month = ""
    @AppStorage("debugHour") private var hour = ""
    @AppStorage("debugPeekOften") private var peekOften = false
    @AppStorage("puggleGreetedOn") private var greetedOn = ""
    @State private var showingSplash = false
    @State private var showingPad = false
    @State private var sticker: EarnedSticker?
    @State private var cleared = false

    private static let stickers: [EarnedSticker] = [
        EarnedSticker(id: "card-1", title: "First card", style: .card(0),
                      detail: "Five stamps on a card, and the shiny one on the end."),
        EarnedSticker(id: "dry-1", title: "First dry day", style: StickerStyle(shape: "shape-soft-square", foil: .sea),
                      detail: "A day on the potty with no accidents."),
        EarnedSticker(id: "food-1", title: "First food", style: StickerStyle(shape: "shape-scallop", foil: .gold, emblem: "icon-solids"),
                      detail: "A first taste of something new."),
        EarnedSticker(id: "milestone", title: "First steps", style: StickerStyle(shape: "shape-blossom", foil: .sunset, emblem: "icon-milestone"),
                      detail: Date.now.formatted(date: .long, time: .omitted)),
    ]

    var body: some View {
        List {
            Section {
                Picker("Today's scene", selection: $scene) {
                    Text("By the date").tag("")
                    Text("Hills and bird").tag("0")
                    Text("Beach and crab").tag("1")
                    Text("Backyard and snail").tag("2")
                    Text("Bush and kookaburra").tag("3")
                }
                Button("Play Puggle's entrance again") { greetedOn = "" }
            } header: {
                Text("Today")
            } footer: {
                Text("Go back to Today to see a change. The entrance plays when Today comes back into view.")
            }
            .listRowBackground(Palette.paper)

            Section {
                Picker("Season", selection: $month) {
                    Text("By the date").tag("")
                    Text("Spring (blossom)").tag(seasonMonth(.spring))
                    Text("Summer (scallop)").tag(seasonMonth(.summer))
                    Text("Autumn (quatrefoil)").tag(seasonMonth(.autumn))
                    Text("Winter (hexagon)").tag(seasonMonth(.winter))
                }
                Picker("Time of day", selection: $hour) {
                    Text("By the clock").tag("")
                    Text("Morning (peach)").tag("8")
                    Text("Day (cream)").tag("13")
                    Text("Evening (lilac)").tag("18")
                }
                Button("Show the splash") { showingSplash = true }
            } header: {
                Text("Splash")
            } footer: {
                Text("Seasons follow this phone's region, so the season names here already allow for the south.")
            }
            .listRowBackground(Palette.paper)

            Section {
                Button("Open the play pad") { showingPad = true }
                Toggle("Puggle visits after every mark", isOn: $peekOften)
                Button(cleared ? "Play pad sheets cleared" : "Clear every play pad sheet", role: .destructive) {
                    try? FileManager.default.removeItem(at: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("play-pad.json"))
                    cleared = true
                }
                .disabled(cleared)
            } header: {
                Text("Play pad")
            }
            .listRowBackground(Palette.paper)

            Section {
                ForEach(Self.stickers) { item in
                    Button {
                        sticker = item
                    } label: {
                        HStack(spacing: 12) {
                            StickerView(style: item.style, size: 36)
                            Text(item.title).foregroundStyle(Palette.ink)
                        }
                    }
                }
            } header: {
                Text("Stickers")
            } footer: {
                Text("Opens each in the large viewer, whether or not it has been earned.")
            }
            .listRowBackground(Palette.paper)

            Section {
                if sample.isOn {
                    Button("Leave the sample family") { sample.leave() }
                } else {
                    Button("Look around the sample family") { sample.start() }
                }
            } header: {
                Text("Stamps, cards and the stamp book")
            } footer: {
                Text("The sample family has Bea, who is potty training: Today shows her Potty tile and the stamp book, and logging a wee for her opens the stamper.")
            }
            .listRowBackground(Palette.paper)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sand)
        .navigationTitle("Developer")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingSplash) {
            SplashView()
                .onTapGesture { showingSplash = false }
                .task {
                    try? await Task.sleep(for: .seconds(4))
                    showingSplash = false
                }
        }
        .fullScreenCover(isPresented: $showingPad) { PlayPadView() }
        .sheet(item: $sticker) { StickerDetailView(sticker: $0) }
    }

    /// A month that gives this season here, north or south of the equator.
    private func seasonMonth(_ season: SplashLook.Season) -> String {
        for month in [4, 7, 10, 1] {
            if SplashLook.season(forMonth: month) == season { return String(month) }
        }
        return ""
    }
}
#endif
