import AppKit

struct Versiculo: Codable, Identifiable, Hashable {
    var id = UUID()
    var referencia: String
    var texto: String
    var versao = "ARC"

    enum CodingKeys: String, CodingKey { case referencia, texto, versao }

    var rodape: String {
        [referencia, versao].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

struct Nota: Codable, Identifiable, Hashable {
    var id = UUID()
    var criadaEm = Date()
    var texto: String
}

struct Oracao: Codable, Identifiable, Hashable {
    var id = UUID()
    var gravadaEm = Date()
    var arquivo: String
    var duracao: Double = 0
}

struct Dia: Codable, Identifiable {
    var id: String
    var versiculo: Versiculo?
    var feitoEm: Date?
    var leitura = ""
    var texto = ""
    var notas: [Nota] = []
    var oracoes: [Oracao] = []

    init(id: String, versiculo: Versiculo?) {
        self.id = id
        self.versiculo = versiculo
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        versiculo = try c.decodeIfPresent(Versiculo.self, forKey: .versiculo)
        feitoEm = try c.decodeIfPresent(Date.self, forKey: .feitoEm)
        leitura = try c.decodeIfPresent(String.self, forKey: .leitura) ?? ""
        texto = try c.decodeIfPresent(String.self, forKey: .texto) ?? ""
        notas = try c.decodeIfPresent([Nota].self, forKey: .notas) ?? []
        oracoes = try c.decodeIfPresent([Oracao].self, forKey: .oracoes) ?? []
    }

    var temConteudo: Bool {
        !leitura.isEmpty || !texto.isEmpty || !notas.isEmpty || !oracoes.isEmpty
    }
}

struct Perfil: Codable, Equatable {
    var nome = ""

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nome = try c.decodeIfPresent(String.self, forKey: .nome) ?? ""
    }
}

struct Estado: Codable {
    var dia = ""
    var feitoEm: Date?
    var segundosAtivos: Double = 0
    var alvoMinutos: Double = 30
    var silencioAte: Date?
    var pausado = false
    var aguardando: String?
    var aguardandoDesde: Date?
    var ultimaFrase: String?
}

struct Evento: Codable {
    let data: Date
    let dia: String
    let faixa: String?
    let tipo: String
    var versiculo: String?
}

enum Arquivos {
    static var pasta: URL {
        let nome = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Altar"
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent(nome)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func subpasta(_ nome: String) -> URL {
        let url = pasta.appendingPathComponent(nome)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static var estadoURL: URL { pasta.appendingPathComponent("estado.json") }
    static var registroURL: URL { pasta.appendingPathComponent("registro.jsonl") }
    static var configURL: URL { pasta.appendingPathComponent("ajustes.json") }
    static var versiculosURL: URL { pasta.appendingPathComponent("versiculos.json") }
    static var perfilURL: URL { pasta.appendingPathComponent("perfil.json") }
    static var fotoURL: URL { pasta.appendingPathComponent("foto.png") }
    static var dias: URL { subpasta("dias") }
    static var oracoes: URL { subpasta("oracoes") }

    static func codificador() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    static func decodificador() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    static func ler<T: Decodable>(_ tipo: T.Type, de url: URL) -> T? {
        guard let dados = try? Data(contentsOf: url) else { return nil }
        return try? decodificador().decode(tipo, from: dados)
    }

    static func gravar<T: Encodable>(_ valor: T, em url: URL) {
        guard let dados = try? codificador().encode(valor) else { return }
        try? dados.write(to: url, options: .atomic)
    }

    static func registrar(_ evento: Evento) {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        guard var linha = try? e.encode(evento) else { return }
        linha.append(0x0A)
        if let h = try? FileHandle(forWritingTo: registroURL) {
            h.seekToEndOfFile()
            h.write(linha)
            try? h.close()
        } else {
            try? linha.write(to: registroURL)
        }
    }

    static func eventos() -> [Evento] {
        guard let texto = try? String(contentsOf: registroURL, encoding: .utf8) else { return [] }
        let d = decodificador()
        return texto.split(separator: "\n").compactMap { try? d.decode(Evento.self, from: Data($0.utf8)) }
    }

    static func ditto(_ argumentos: [String]) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        p.arguments = argumentos
        try p.run()
        p.waitUntilExit()
        if p.terminationStatus != 0 { throw CocoaError(.fileWriteUnknown) }
    }

    static func exportar(para destino: URL) throws {
        try? FileManager.default.removeItem(at: destino)
        try ditto(["-c", "-k", "--sequesterRsrc", "--keepParent", pasta.path, destino.path])
    }

    static func restaurar(de zip: URL) throws {
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: temp) }
        try ditto(["-x", "-k", zip.path, temp.path])
        let candidatos = [temp] + ((try? fm.contentsOfDirectory(at: temp, includingPropertiesForKeys: nil)) ?? [])
        guard let origem = candidatos.first(where: { fm.fileExists(atPath: $0.appendingPathComponent("dias").path) }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        for item in (try? fm.contentsOfDirectory(at: pasta, includingPropertiesForKeys: nil)) ?? [] {
            try fm.trashItem(at: item, resultingItemURL: nil)
        }
        for item in try fm.contentsOfDirectory(at: origem, includingPropertiesForKeys: nil) {
            try fm.copyItem(at: item, to: pasta.appendingPathComponent(item.lastPathComponent))
        }
    }

    static func versiculosDoApp() -> [Versiculo] {
        guard let url = Bundle.main.url(forResource: "versiculos", withExtension: "json") else { return [] }
        return ler([Versiculo].self, de: url) ?? []
    }
}

final class Loja: ObservableObject {
    @Published var config: Config {
        didSet { if config != oldValue { Arquivos.gravar(config, em: Arquivos.configURL) } }
    }
    @Published var versiculos: [Versiculo] {
        didSet { Arquivos.gravar(versiculos, em: Arquivos.versiculosURL) }
    }
    @Published var perfil: Perfil {
        didSet { if perfil != oldValue { Arquivos.gravar(perfil, em: Arquivos.perfilURL) } }
    }
    @Published private(set) var foto: NSImage?
    @Published private(set) var dias: [String: Dia] = [:]
    @Published private(set) var eventos: [Evento] = []

    init() {
        config = Arquivos.ler(Config.self, de: Arquivos.configURL) ?? Config()
        versiculos = Arquivos.ler([Versiculo].self, de: Arquivos.versiculosURL) ?? Arquivos.versiculosDoApp()
        perfil = Arquivos.ler(Perfil.self, de: Arquivos.perfilURL) ?? Perfil()
        foto = NSImage(contentsOf: Arquivos.fotoURL)
        let urls = (try? FileManager.default.contentsOfDirectory(at: Arquivos.dias, includingPropertiesForKeys: nil)) ?? []
        for url in urls where url.pathExtension == "json" {
            if let d = Arquivos.ler(Dia.self, de: url) { dias[d.id] = d }
        }
        eventos = Arquivos.eventos()
    }

    func dia(_ chave: String) -> Dia {
        dias[chave] ?? Dia(id: chave, versiculo: versiculoDoDia(chave))
    }

    func salvar(_ dia: Dia) {
        dias[dia.id] = dia
        Arquivos.gravar(dia, em: Arquivos.dias.appendingPathComponent(dia.id + ".json"))
    }

    func mudar(_ chave: String, _ mudanca: (inout Dia) -> Void) {
        var d = dia(chave)
        mudanca(&d)
        salvar(d)
    }

    func registrar(_ evento: Evento) {
        Arquivos.registrar(evento)
        eventos.append(evento)
    }

    func versiculoDoDia(_ chave: String) -> Versiculo? {
        guard !versiculos.isEmpty else { return nil }
        let n = chave.unicodeScalars.reduce(0) { $0 &* 31 &+ Int($1.value) }
        return versiculos[abs(n) % versiculos.count]
    }

    var feitos: Set<String> {
        Set(dias.values.filter { $0.feitoEm != nil }.map(\.id))
    }

    func sequenciaAtual(hoje: String) -> Int {
        contarSequencia(feitos, ate: hoje)
    }

    var maiorSequencia: Int {
        contarMaiorSequencia(feitos)
    }

    func mudarFoto(_ url: URL) {
        guard let original = NSImage(contentsOf: url) else { return }
        let lado: CGFloat = 512
        let tamanho = original.size
        let escala = lado / max(1, min(tamanho.width, tamanho.height))
        let alvo = NSSize(width: tamanho.width * escala, height: tamanho.height * escala)
        let nova = NSImage(size: NSSize(width: lado, height: lado), flipped: false) { _ in
            original.draw(in: NSRect(x: (lado - alvo.width) / 2, y: (lado - alvo.height) / 2, width: alvo.width, height: alvo.height))
            return true
        }
        guard let tiff = nova.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: Arquivos.fotoURL, options: .atomic)
        foto = NSImage(data: png)
    }

    func removerFoto() {
        try? FileManager.default.removeItem(at: Arquivos.fotoURL)
        foto = nil
    }

    var primeiroDevocional: Date? {
        feitos.compactMap(dataDaChave).min()
    }

    func urlDaOracao(_ o: Oracao) -> URL {
        Arquivos.oracoes.appendingPathComponent(o.arquivo)
    }
}
