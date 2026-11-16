import SwiftUI

/// "One Boot", the first book (docs/stories/one-boot.md), as a storyboard: rough flat scenes with the cast
/// as they are in the app, to see whether the book works before anything is drawn properly.
extension Book {
    static let oneBoot = Book(title: "One Boot", pages: [
        // 1. The burrow, morning.
        BookPage(ground: Color(hex: 0xB98A5E), horizon: 0.45,
                 props: [.init(thing: .door, x: 0.3, y: 0.5, wide: 0.42), .init(thing: .puddle, x: 0.7, y: 0.9, wide: 0.4)],
                 cast: [.init(who: "mum", x: 0.3, y: 0.74, tall: 0.42), .init(who: "puggle", x: 0.62, y: 0.86, tall: 0.4)],
                 boat: CGPoint(x: 0.72, y: 0.9),
                 words: ["It is a puddle day.", "Puggle has her boots."], refrain: "One boot on. One boot gone."),
        // 2. The log pile.
        BookPage(props: [.init(thing: .log, x: 0.5, y: 0.78, wide: 0.7), .init(thing: .log, x: 0.4, y: 0.66, wide: 0.55, colour: Color(hex: 0x8A5A3C))],
                 cast: [.init(who: "puggle", x: 0.84, y: 0.94, tall: 0.36)],
                 flap: .init(shape: .capsule, hinge: .top, rect: CGRect(x: 0.2, y: 0.42, width: 0.56, height: 0.18), colour: Color(hex: 0xA97A52), who: "quill", found: .cone),
                 boat: CGPoint(x: 0.1, y: 0.9), ask: "Is it under the logs?",
                 words: ["No boot. A cone! And Quill.", "\u{201C}Not yet,\u{201D} says Quill. Then she comes too."], refrain: "One boot on. One boot gone."),
        // 3. The paddock.
        BookPage(ground: Color(hex: 0xD9C08A),
                 props: [.init(thing: .mound, x: 0.2, y: 0.85, wide: 0.3, colour: Color(hex: 0xA97A52))],
                 cast: [.init(who: "quill", x: 0.86, y: 0.9, tall: 0.3), .init(who: "puggle", x: 0.68, y: 0.94, tall: 0.36)],
                 flap: .init(shape: .dome, hinge: .bottom, rect: CGRect(x: 0.22, y: 0.4, width: 0.5, height: 0.24), colour: Color(hex: 0xB98A5E), who: "digby", found: .flower),
                 boat: CGPoint(x: 0.92, y: 0.3), ask: "Is it down the hole?",
                 words: ["No boot. A flower! And Digby.", "\u{201C}Me too!\u{201D} says Digby."], refrain: "One boot on. One boot gone."),
        // 4. The big gum.
        BookPage(props: [.init(thing: .trunk, x: 0.32, y: 0.55, wide: 0.16), .init(thing: .leaves, x: 0.3, y: 0.2, wide: 0.7, colour: Color(hex: 0x2F8552))],
                 cast: [.init(who: "digby", x: 0.9, y: 0.92, tall: 0.3), .init(who: "quill", x: 0.74, y: 0.9, tall: 0.3), .init(who: "puggle", x: 0.57, y: 0.94, tall: 0.36)],
                 flap: .init(shape: .blob, hinge: .leading, rect: CGRect(x: 0.4, y: 0.08, width: 0.5, height: 0.28), colour: Color(hex: 0x3C9A5F), who: "kip", found: .leaf),
                 boat: CGPoint(x: 0.1, y: 0.92), ask: "Is it up the tree?",
                 words: ["No boot. A leaf! And Kip.", "\u{201C}I can see the whole creek,\u{201D} says Kip. \u{201C}Wait for me.\u{201D}"]),
        // 5. The sandy bend.
        BookPage(ground: Color(hex: 0xF4E7B0), horizon: 0.5,
                 props: [.init(thing: .water, x: 0.5, y: 0.47, wide: 1.0)],
                 cast: [.init(who: "kip", x: 0.12, y: 0.96, tall: 0.3), .init(who: "digby", x: 0.3, y: 0.98, tall: 0.3), .init(who: "quill", x: 0.86, y: 0.98, tall: 0.3), .init(who: "puggle", x: 0.68, y: 0.99, tall: 0.34)],
                 flap: .init(shape: .rounded, hinge: .trailing, rect: CGRect(x: 0.26, y: 0.5, width: 0.5, height: 0.2), colour: Color(hex: 0xE5553B), who: "sunny", found: .bucket),
                 boat: CGPoint(x: 0.85, y: 0.42), ask: "Is it under the towel?",
                 words: ["No boot. A bucket! And Sunny.", "\u{201C}The rule is,\u{201D} says Sunny, \u{201C}we look together.\u{201D}"], refrain: "One boot on. One boot gone."),
        // 6. The stepping stones.
        BookPage(ground: Color(hex: 0x8DB8E8), horizon: 0.4,
                 props: (0..<5).map { .init(thing: .stone, x: 0.12 + Double($0) * 0.19, y: 0.82 - Double($0) * 0.05, wide: 0.2) },
                 cast: [.init(who: "kip", x: 0.12, y: 0.8, tall: 0.22), .init(who: "sunny", x: 0.31, y: 0.75, tall: 0.24), .init(who: "digby", x: 0.5, y: 0.7, tall: 0.22),
                        .init(who: "quill", x: 0.69, y: 0.65, tall: 0.22), .init(who: "puggle", x: 0.86, y: 0.61, tall: 0.26)],
                 flap: .init(shape: .dome, hinge: .bottom, rect: CGRect(x: 0.3, y: 0.1, width: 0.42, height: 0.2), colour: Color(hex: 0xD8B77A), who: nil, found: .duck),
                 boat: CGPoint(x: 0.14, y: 0.93), ask: "Is it under Pop's hat?",
                 words: ["No boot. A duck!", "\u{201C}Well, I never,\u{201D} says Nan."]),
        // 7. Nan and Pop's porch.
        BookPage(sky: Color(hex: 0xF3D9C9), ground: Color(hex: 0xC9A06A), horizon: 0.7,
                 props: [.init(thing: .tin, x: 0.5, y: 0.52, wide: 0.5)],
                 cast: [.init(who: "nan", x: 0.14, y: 0.96, tall: 0.44), .init(who: "pop", x: 0.87, y: 0.96, tall: 0.44), .init(who: "puggle", x: 0.5, y: 0.99, tall: 0.3)],
                 flap: .init(shape: .rounded, hinge: .top, rect: CGRect(x: 0.25, y: 0.33, width: 0.5, height: 0.16), colour: Color(hex: 0x1F4E96), who: nil, found: .biscuit),
                 boat: CGPoint(x: 0.5, y: 0.2), ask: "Is it in the tin?",
                 words: ["No boot. A biscuit.", "Two, at Nan\u{2019}s."]),
        // 8. The way home: the parade.
        BookPage(horizon: 0.55,
                 props: [.init(thing: .water, x: 0.5, y: 0.5, wide: 1.0), .init(thing: .leaves, x: 0.9, y: 0.25, wide: 0.4)],
                 cast: [.init(who: "sunny", x: 0.1, y: 0.92, tall: 0.3, hat: .bucket), .init(who: "quill", x: 0.28, y: 0.92, tall: 0.27, hat: .cone),
                        .init(who: "kip", x: 0.46, y: 0.92, tall: 0.27, hat: .leaf), .init(who: "digby", x: 0.64, y: 0.92, tall: 0.26, hat: .flower),
                        .init(who: "puggle", x: 0.84, y: 0.94, tall: 0.3)],
                 boat: CGPoint(x: 0.3, y: 0.5),
                 words: ["Step, squelch. Step, squelch."], refrain: "One boot on. One boot gone."),
        // 9. The basket by the door.
        BookPage(ground: Color(hex: 0xB98A5E), horizon: 0.4,
                 props: [.init(thing: .door, x: 0.82, y: 0.34, wide: 0.3), .init(thing: .basket, x: 0.42, y: 0.74, wide: 0.6)],
                 cast: [.init(who: "puggle", x: 0.86, y: 0.98, tall: 0.34)],
                 flap: .init(shape: .rounded, hinge: .leading, rect: CGRect(x: 0.14, y: 0.42, width: 0.56, height: 0.22), colour: Color(hex: 0xBFD9F5), who: "pebble", found: .boot),
                 boat: CGPoint(x: 0.1, y: 0.2), ask: "Is it in the basket?",
                 words: ["Ba!"]),
        // 10. Closer.
        BookPage(sky: Color(hex: 0xF4E7B0), ground: Color(hex: 0xB98A5E), horizon: 0.72,
                 cast: [.init(who: "pebble", x: 0.3, y: 0.92, tall: 0.42, hat: .boot), .init(who: "puggle", x: 0.7, y: 0.94, tall: 0.5, hat: .boot)],
                 boat: CGPoint(x: 0.9, y: 0.12),
                 words: ["Puggle looks at the boot.", "Pebble looks at Puggle.", "\u{201C}Mine,\u{201D} says Puggle. Then: \u{201C}Ba.\u{201D}"]),
        // 11. Outside the burrow.
        BookPage(ground: Color(hex: 0xCFE5D2), horizon: 0.5,
                 props: [.init(thing: .puddle, x: 0.5, y: 0.93, wide: 0.6)],
                 cast: [.init(who: "dad", x: 0.9, y: 0.72, tall: 0.36), .init(who: "sunny", x: 0.1, y: 0.8, tall: 0.26, hat: .bucket), .init(who: "quill", x: 0.25, y: 0.82, tall: 0.24, hat: .cone),
                        .init(who: "kip", x: 0.72, y: 0.82, tall: 0.24, hat: .leaf), .init(who: "digby", x: 0.58, y: 0.84, tall: 0.23, hat: .flower),
                        .init(who: "pebble", x: 0.4, y: 0.9, tall: 0.22, hat: .boot), .init(who: "puggle", x: 0.5, y: 0.97, tall: 0.3, hat: .boot)],
                 boat: CGPoint(x: 0.66, y: 0.93),
                 words: ["No boots on.", "Splash.", "And the creek went on by."]),
    ])
}
