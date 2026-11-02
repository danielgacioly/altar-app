import AVFoundation
import Speech

enum Fala {
    static let local = Locale(identifier: "pt-BR")

    static func preparar(_ modulo: SpeechTranscriber) async throws {
        if let pedido = try await AssetInventory.assetInstallationRequest(supporting: [modulo]) {
            try await pedido.downloadAndInstall()
        }
    }

    static func microfone() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    static func transcrever(_ url: URL) async throws -> String {
        let transcritor = SpeechTranscriber(locale: local, preset: .transcription)
        try await preparar(transcritor)
        let arquivo = try AVAudioFile(forReading: url)
        let analisador = try await SpeechAnalyzer(inputAudioFile: arquivo, modules: [transcritor], finishAfterFile: true)
        var texto = ""
        for try await r in transcritor.results {
            texto += String(r.text.characters)
        }
        _ = analisador
        return texto.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
final class Ditado: ObservableObject {
    @Published private(set) var gravando = false
    @Published private(set) var preparando = false
    @Published var texto = ""
    @Published var erro: String?

    private var motor: AVAudioEngine?
    private var entrada: AsyncStream<AnalyzerInput>.Continuation?
    private var analisador: SpeechAnalyzer?
    private var leitura: Task<Void, Never>?
    private var pronto = ""

    func iniciar() async {
        erro = nil
        texto = ""
        pronto = ""
        guard await Fala.microfone() else {
            erro = "O Altar não tem acesso ao microfone. Libere em Ajustes do Sistema > Privacidade e Segurança > Microfone."
            return
        }
        preparando = true
        defer { preparando = false }
        do {
            let transcritor = SpeechTranscriber(locale: Fala.local, transcriptionOptions: [], reportingOptions: [.volatileResults], attributeOptions: [])
            try await Fala.preparar(transcritor)
            guard let formato = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcritor]) else {
                erro = "Não deu pra preparar o reconhecimento de fala."
                return
            }
            let (fluxo, cont) = AsyncStream<AnalyzerInput>.makeStream()
            entrada = cont
            let analisador = SpeechAnalyzer(modules: [transcritor])
            self.analisador = analisador
            leitura = Task { [weak self] in
                do {
                    for try await r in transcritor.results {
                        guard let self else { return }
                        let parte = String(r.text.characters)
                        if r.isFinal {
                            self.pronto += parte
                            self.texto = self.pronto
                        } else {
                            self.texto = self.pronto + parte
                        }
                    }
                } catch {}
            }
            try await analisador.start(inputSequence: fluxo)

            let motor = AVAudioEngine()
            let natural = motor.inputNode.outputFormat(forBus: 0)
            guard let conversor = AVAudioConverter(from: natural, to: formato) else {
                erro = "Formato de áudio do microfone não suportado."
                return
            }
            motor.inputNode.installTap(onBus: 0, bufferSize: 4096, format: natural) { buffer, _ in
                if let saida = converter(buffer, conversor) {
                    cont.yield(AnalyzerInput(buffer: saida))
                }
            }
            try motor.start()
            self.motor = motor
            gravando = true
        } catch {
            erro = "Erro no ditado: \(error.localizedDescription)"
        }
    }

    func parar() async {
        motor?.inputNode.removeTap(onBus: 0)
        motor?.stop()
        motor = nil
        entrada?.finish()
        entrada = nil
        try? await analisador?.finalizeAndFinishThroughEndOfInput()
        await leitura?.value
        analisador = nil
        leitura = nil
        gravando = false
        texto = texto.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private func converter(_ buffer: AVAudioPCMBuffer, _ conversor: AVAudioConverter) -> AVAudioPCMBuffer? {
    let razao = conversor.outputFormat.sampleRate / buffer.format.sampleRate
    let capacidade = AVAudioFrameCount(Double(buffer.frameLength) * razao + 1)
    guard let saida = AVAudioPCMBuffer(pcmFormat: conversor.outputFormat, frameCapacity: capacidade) else { return nil }
    var entregue = false
    var erro: NSError?
    conversor.convert(to: saida, error: &erro) { _, status in
        if entregue {
            status.pointee = .noDataNow
            return nil
        }
        entregue = true
        status.pointee = .haveData
        return buffer
    }
    return erro == nil && saida.frameLength > 0 ? saida : nil
}

@MainActor
final class Gravador: ObservableObject {
    @Published private(set) var gravando = false
    @Published var erro: String?
    private var gravador: AVAudioRecorder?
    private var nome = ""

    func iniciar() async {
        erro = nil
        guard await Fala.microfone() else {
            erro = "O Altar não tem acesso ao microfone. Libere em Ajustes do Sistema > Privacidade e Segurança > Microfone."
            return
        }
        nome = UUID().uuidString + ".m4a"
        let ajustes: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            let g = try AVAudioRecorder(url: Arquivos.oracoes.appendingPathComponent(nome), settings: ajustes)
            g.record()
            gravador = g
            gravando = true
        } catch {
            erro = "Não deu pra gravar: \(error.localizedDescription)"
        }
    }

    func parar() -> Oracao? {
        guard let g = gravador else { return nil }
        let duracao = g.currentTime
        g.stop()
        gravador = nil
        gravando = false
        return Oracao(arquivo: nome, duracao: duracao)
    }
}

@MainActor
final class Tocador: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var tocando: UUID?
    private var player: AVAudioPlayer?

    func alternar(_ oracao: Oracao, _ url: URL) {
        if tocando == oracao.id {
            parar()
            return
        }
        parar()
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        p.delegate = self
        p.play()
        player = p
        tocando = oracao.id
    }

    func parar() {
        player?.stop()
        player = nil
        tocando = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.parar() }
    }
}
