import AVFoundation

/// Soft but firm bell for the end of a rest (web `bell()`): three sine partials, quick attack, long gentle decay.
/// Synthesised once into an in-memory WAV, so there is no audio asset to ship.
@MainActor
final class Bell {
    static let shared = Bell()
    private var player: AVAudioPlayer?

    private static let wav: Data = {
        let rate = 44_100.0, secs = 1.8
        let n = Int(rate * secs)
        let partials: [(f: Double, v: Double, d: Double)] = [(660, 0.34, 1.6), (1320, 0.16, 1.1), (1980, 0.07, 0.7)]
        var pcm = [Int16](repeating: 0, count: n)
        for i in 0..<n {
            let t = Double(i) / rate
            var x = 0.0
            for p in partials where t < p.d {
                let attack = min(t / 0.01, 1)
                x += sin(2 * .pi * p.f * t) * p.v * attack * pow(0.0001 / p.v, t / p.d)
            }
            pcm[i] = Int16(max(-1, min(1, x)) * 32_000)
        }
        var d = Data()
        func u32(_ v: UInt32) { var v = v.littleEndian; d.append(Data(bytes: &v, count: 4)) }
        func u16(_ v: UInt16) { var v = v.littleEndian; d.append(Data(bytes: &v, count: 2)) }
        d.append("RIFF".data(using: .ascii)!); u32(UInt32(36 + n * 2)); d.append("WAVEfmt ".data(using: .ascii)!)
        u32(16); u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate) * 2); u16(2); u16(16)
        d.append("data".data(using: .ascii)!); u32(UInt32(n * 2))
        pcm.withUnsafeBufferPointer { d.append(Data(buffer: $0)) }
        return d
    }()

    func ring() {
        // .playback + mixWithOthers: rings even with the silent switch on, and plays over music without stopping it.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        player = try? AVAudioPlayer(data: Self.wav)
        player?.volume = 0.8
        player?.play()
    }
}
