import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = PianoAudioEngine()
    @State private var selectedKeyboardRange: KeyboardRange = .aroundMiddleC

    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > proxy.size.height
            let chooserGap: CGFloat = isWide ? 4 : 6

            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.02, green: 0.018, blue: 0.015), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: chooserGap)

                    KeyboardRangePicker(selectedRange: $selectedKeyboardRange)
                        .frame(height: isWide ? 30 : 36)
                        .frame(maxWidth: isWide ? 360 : 300)
                        .padding(.horizontal, isWide ? 8 : 12)

                    Spacer()
                        .frame(height: chooserGap)

                    RedFeltStrip()
                        .frame(height: isWide ? 10 : 12)

                    PianoKeyboard(keys: selectedKeyboardRange.keys, audioEngine: audioEngine)
                        .padding(.horizontal, isWide ? 2 : 6)
                        .padding(.bottom, isWide ? 2 : 6)
                }
                .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            }
        }
        .preferredColorScheme(.dark)
    }
}

private enum KeyboardRange: String, CaseIterable, Identifiable {
    case bass
    case aroundMiddleC
    case soprano

    var id: Self { self }

    var title: String {
        switch self {
        case .bass:
            "Bass"
        case .aroundMiddleC:
            "Center"
        case .soprano:
            "Soprano"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .bass:
            "Bass range, C2 through C4"
        case .aroundMiddleC:
            "Center range, C3 through C5"
        case .soprano:
            "Soprano range, C4 through C6"
        }
    }

    var keys: [PianoKey] {
        switch self {
        case .bass:
            PianoKey.keys(in: 36...60)
        case .aroundMiddleC:
            PianoKey.twoOctavesAroundMiddleC
        case .soprano:
            PianoKey.keys(in: 60...84)
        }
    }
}

private struct KeyboardRangePicker: View {
    @Binding var selectedRange: KeyboardRange

    var body: some View {
        Picker("Keyboard range", selection: $selectedRange) {
            ForEach(KeyboardRange.allCases) { range in
                Text(range.title)
                    .tag(range)
                    .accessibilityLabel(Text(range.accessibilityLabel))
            }
        }
        .pickerStyle(.segmented)
        .tint(Color(red: 0.70, green: 0.05, blue: 0.055))
        .accessibilityHint(Text("Changes which octaves are displayed on the piano keyboard"))
    }
}

private struct RedFeltStrip: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.30, green: 0.02, blue: 0.025), Color(red: 0.70, green: 0.05, blue: 0.055), Color(red: 0.24, green: 0.01, blue: 0.018)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(0.10))
                .frame(height: 1)
        }
    }
}

private struct PianoKeyboard: View {
    let keys: [PianoKey]
    @ObservedObject var audioEngine: PianoAudioEngine

    private var whiteKeys: [PianoKey] { keys.filter { !$0.isSharp } }
    private var blackKeys: [PianoKey] { keys.filter(\.isSharp) }

    var body: some View {
        GeometryReader { proxy in
            let whiteKeyWidth = proxy.size.width / CGFloat(whiteKeys.count)
            let blackKeyWidth = whiteKeyWidth * 0.62
            let blackKeyHeight = proxy.size.height * 0.64

            ZStack(alignment: .topLeading) {
                HStack(spacing: 1.5) {
                    ForEach(whiteKeys) { key in
                        PianoWhiteKey(key: key, audioEngine: audioEngine)
                    }
                }

                ForEach(blackKeys) { key in
                    PianoBlackKey(key: key, audioEngine: audioEngine)
                        .frame(width: blackKeyWidth, height: blackKeyHeight)
                        .offset(x: blackKeyOffset(for: key, whiteKeyWidth: whiteKeyWidth, blackKeyWidth: blackKeyWidth))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.black.opacity(0.72), lineWidth: 2)
            }
        }
    }

    private func blackKeyOffset(for key: PianoKey, whiteKeyWidth: CGFloat, blackKeyWidth: CGFloat) -> CGFloat {
        let whiteKeysBeforeBlackKey = keys.prefix { $0.id != key.id }.filter { !$0.isSharp }.count
        return CGFloat(whiteKeysBeforeBlackKey) * whiteKeyWidth - (blackKeyWidth / 2)
    }
}

private struct PianoWhiteKey: View {
    let key: PianoKey
    @ObservedObject var audioEngine: PianoAudioEngine
    @State private var isPressed = false

    var body: some View {
        KeyTouchSurface(isPressed: $isPressed, accessibilityLabel: "Piano key \(key.label)") {
            audioEngine.play(key)
        } label: {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: isPressed
                                ? [Color(red: 0.73, green: 0.70, blue: 0.62), Color(red: 0.95, green: 0.91, blue: 0.82)]
                                : [Color(red: 1.0, green: 0.98, blue: 0.90), Color(red: 0.82, green: 0.78, blue: 0.67)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(.white.opacity(0.42))
                            .frame(width: 2)
                    }
                    .shadow(color: .black.opacity(isPressed ? 0.12 : 0.36), radius: isPressed ? 1 : 4, x: 0, y: isPressed ? 1 : 4)

                Text(key.label)
                    .font(.system(size: 11, weight: key.midiNote == 60 ? .bold : .medium, design: .rounded))
                    .foregroundStyle(key.midiNote == 60 ? Color(red: 0.48, green: 0.04, blue: 0.04) : .black.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 10)
            }
        }
        .scaleEffect(y: isPressed ? 0.985 : 1, anchor: .top)
    }
}

private struct PianoBlackKey: View {
    let key: PianoKey
    @ObservedObject var audioEngine: PianoAudioEngine
    @State private var isPressed = false

    var body: some View {
        KeyTouchSurface(isPressed: $isPressed, accessibilityLabel: "Piano key \(key.label)") {
            audioEngine.play(key)
        } label: {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: isPressed
                            ? [Color(red: 0.015, green: 0.015, blue: 0.014), Color(red: 0.12, green: 0.11, blue: 0.10)]
                            : [Color(red: 0.13, green: 0.12, blue: 0.11), Color.black, Color(red: 0.05, green: 0.045, blue: 0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.82), radius: 5, x: 0, y: 4)
        }
        .scaleEffect(y: isPressed ? 0.965 : 1, anchor: .top)
    }
}

private struct KeyTouchSurface<Label: View>: View {
    @Binding var isPressed: Bool
    let accessibilityLabel: String
    let onPress: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        label()
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        onPress()
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
            .accessibilityLabel(Text(accessibilityLabel))
            .accessibilityAddTraits(.isButton)
    }
}

struct PianoKey: Identifiable, Equatable {
    let midiNote: Int
    let name: String
    let octave: Int

    var id: Int { midiNote }
    var isSharp: Bool { name.contains("#") }
    var label: String { "\(name)\(octave)" }
    var frequency: Double {
        440.0 * pow(2.0, Double(midiNote - 69) / 12.0)
    }

    static let twoOctavesAroundMiddleC: [PianoKey] = keys(in: 48...72)

    static func keys(in midiRange: ClosedRange<Int>) -> [PianoKey] {
        midiRange.map { midi in
            makeKey(midiNote: midi)
        }
    }

    private static func makeKey(midiNote midi: Int) -> PianoKey {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let name = noteNames[midi % 12]
        let octave = (midi / 12) - 1
        return PianoKey(midiNote: midi, name: name, octave: octave)
    }
}
