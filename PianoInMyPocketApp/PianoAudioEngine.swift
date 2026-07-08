import AVFoundation
import SwiftUI

@MainActor
final class PianoAudioEngine: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private let sampleRate = 44_100
    private var noteDataCache: [Int: Data] = [:]
    private var activePlayers: Set<AVAudioPlayer> = []

    override init() {
        super.init()
        configureSession()
    }

    func play(_ key: PianoKey) {
        do {
            let data = noteDataCache[key.midiNote] ?? makePianoWAVData(
                frequency: key.frequency,
                velocity: key.midiNote == 60 ? 0.92 : 0.82
            )
            noteDataCache[key.midiNote] = data

            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            player.prepareToPlay()
            activePlayers.insert(player)
            player.play()
        } catch {
            print("Could not play \(key.label): \(error.localizedDescription)")
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            activePlayers.remove(player)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            activePlayers.remove(player)
        }
    }

    private func configureSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
        }
        #endif
    }

    private func makePianoWAVData(frequency: Double, velocity: Double) -> Data {
        let duration = 1.55
        let samples = makeSamples(frequency: frequency, velocity: velocity, duration: duration)
        return makeWAVData(samples: samples)
    }

    private func makeSamples(frequency: Double, velocity: Double, duration: Double) -> [Int16] {
        let sampleCount = Int(duration * Double(sampleRate))
        var samples: [Int16] = []
        samples.reserveCapacity(sampleCount)

        for frame in 0..<sampleCount {
            let time = Double(frame) / Double(sampleRate)
            let attack = min(1.0, time / 0.012)
            let decay = exp(-2.95 * time)
            let body = sin(2.0 * .pi * frequency * time)
            let harmonic2 = 0.38 * sin(2.0 * .pi * frequency * 2.01 * time)
            let harmonic3 = 0.20 * sin(2.0 * .pi * frequency * 3.02 * time)
            let hammer = 0.08 * sin(2.0 * .pi * frequency * 7.0 * time) * exp(-18.0 * time)
            let sample = (body + harmonic2 + harmonic3 + hammer) * attack * decay * velocity
            let clamped = max(-0.95, min(0.95, sample))

            samples.append(Int16(clamped * Double(Int16.max)))
        }

        return samples
    }

    private func makeWAVData(samples: [Int16]) -> Data {
        let byteRate = sampleRate * 2
        let dataSize = samples.count * 2
        let riffSize = 36 + dataSize
        var data = Data()

        data.appendASCII("RIFF")
        data.appendLittleEndian(UInt32(riffSize))
        data.appendASCII("WAVE")
        data.appendASCII("fmt ")
        data.appendLittleEndian(UInt32(16))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt32(sampleRate))
        data.appendLittleEndian(UInt32(byteRate))
        data.appendLittleEndian(UInt16(2))
        data.appendLittleEndian(UInt16(16))
        data.appendASCII("data")
        data.appendLittleEndian(UInt32(dataSize))

        for sample in samples {
            data.appendLittleEndian(UInt16(bitPattern: sample))
        }

        return data
    }
}

private extension Data {
    mutating func appendASCII(_ string: String) {
        append(contentsOf: string.utf8)
    }

    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { bytes in
            append(contentsOf: bytes)
        }
    }
}
