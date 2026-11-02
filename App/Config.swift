import Foundation

struct Faixa: Codable, Identifiable, Hashable {
    var id = UUID()
    var nome: String
    var inicio: Int
    var frases: [String]
}

enum Efeito: String, Codable, CaseIterable, Identifiable {
    case ateFimDoHorario
    case porMinutos
    case ateVirarODia

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .ateFimDoHorario: "Silenciar até o fim do horário"
        case .porMinutos: "Silenciar por alguns minutos"
        case .ateVirarODia: "Silenciar até o dia virar"
        }
    }
}

struct Ocorrencia: Codable, Identifiable, Hashable {
    var id = UUID()
    var dias: Set<Int>
    var inicio: Int
    var fim: Int
}

struct BotaoExtra: Codable, Identifiable, Hashable {
    var id = UUID()
    var nome: String
    var efeito: Efeito = .ateFimDoHorario
    var minutos = 60
    var ocorrencias: [Ocorrencia] = []
}

struct Config: Codable, Equatable {
    var minutosEntreLembretes = 30
    var minutosAdiar = 15
    var minutosOcioso = 2
    var horaViradaDoDia = 2
    var inicioSilencio = 2 * 60
    var fimSilencio = 7 * 60
    var faixas: [Faixa] = Config.faixasPadrao
    var extras: [BotaoExtra] = Config.extrasPadrao

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let p = Config()
        minutosEntreLembretes = try c.decodeIfPresent(Int.self, forKey: .minutosEntreLembretes) ?? p.minutosEntreLembretes
        minutosAdiar = try c.decodeIfPresent(Int.self, forKey: .minutosAdiar) ?? p.minutosAdiar
        minutosOcioso = try c.decodeIfPresent(Int.self, forKey: .minutosOcioso) ?? p.minutosOcioso
        horaViradaDoDia = try c.decodeIfPresent(Int.self, forKey: .horaViradaDoDia) ?? p.horaViradaDoDia
        inicioSilencio = try c.decodeIfPresent(Int.self, forKey: .inicioSilencio) ?? p.inicioSilencio
        fimSilencio = try c.decodeIfPresent(Int.self, forKey: .fimSilencio) ?? p.fimSilencio
        faixas = try c.decodeIfPresent([Faixa].self, forKey: .faixas) ?? p.faixas
        extras = try c.decodeIfPresent([BotaoExtra].self, forKey: .extras) ?? p.extras
    }

    static let extrasPadrao = [
        BotaoExtra(nome: "Estou na faculdade", efeito: .ateFimDoHorario, ocorrencias: [
            Ocorrencia(dias: [2, 5], inicio: 9 * 60, fim: 12 * 60),
            Ocorrencia(dias: [2, 3, 4, 5], inicio: 17 * 60, fim: 21 * 60)
        ])
    ]

    static let faixasPadrao = [
        Faixa(nome: "Antes de dormir", inicio: 0, frases: [
            "Vamos fazer o devocional antes de dormir?",
            "Já é tarde. Termina o dia com a Palavra.",
            "Antes de deitar, ainda dá tempo do devocional de hoje.",
            "O dia tá quase virando. Já fez o devocional?"
        ]),
        Faixa(nome: "Começo do dia", inicio: 7 * 60, frases: [
            "Bom dia! Que tal começar o dia com o devocional?",
            "Preparado pra entregar o seu dia ao Senhor?",
            "Antes de o dia começar a correr, já abriu a Palavra hoje?",
            "Bom dia. O devocional de hoje tá te esperando."
        ]),
        Faixa(nome: "Antes do almoço", inicio: 11 * 60, frases: [
            "Ei, que tal um devocional antes do almoço?",
            "Dá uma paradinha: já fez o devocional hoje?",
            "Já tá quase na hora de comer. E o devocional, já foi?",
            "Antes de almoçar, que tal um tempo com o Senhor?"
        ]),
        Faixa(nome: "Depois do almoço", inicio: 13 * 60, frases: [
            "Vamos fazer o devocional antes de voltar ao trabalho?",
            "Para um pouquinho e pensa no Senhor. Já fez o devocional?",
            "Que tal um momento com Deus antes de seguir a tarde?",
            "Depois do almoço, uma pausa pra olhar pra cima. Já fez o devocional?"
        ]),
        Faixa(nome: "Antes da faculdade", inicio: 15 * 60, frases: [
            "Ei, que tal um devocional antes de ir pra faculdade?",
            "Antes de sair pra aula, já separou um tempo com Deus?",
            "A faculdade vem aí. Dá tempo de um devocional rápido?",
            "Vai sair pra aula? Leva a Palavra com você. Já fez o devocional?"
        ]),
        Faixa(nome: "Anoitecendo", inicio: 17 * 60, frases: [
            "Ei, já tá anoitecendo. Vamos lembrar do devocional?",
            "O dia tá acabando e o devocional ainda não foi. Já fez?",
            "Anoiteceu, mas ainda dá tempo. Que tal o devocional agora?",
            "Ainda não fez o devocional hoje? Dá tempo antes de a noite acabar."
        ]),
        Faixa(nome: "Encerramento", inicio: 21 * 60, frases: [
            "Vamos fazer o devocional antes de relaxar?",
            "Antes do entretenimento, que tal um tempo com o Senhor?",
            "Vai voltar ao trabalho ou descansar? Antes, um devocional.",
            "O dia tá fechando. Já separou um tempo com Deus?"
        ])
    ]

    func faixa(em data: Date) -> Faixa? {
        let agora = minutoDoDia(data)
        let ordenadas = faixas.sorted { $0.inicio < $1.inicio }
        return ordenadas.last { $0.inicio <= agora } ?? ordenadas.last
    }

    func silencioso(_ data: Date) -> Bool {
        dentro(minutoDoDia(data), inicioSilencio, fimSilencio)
    }

    func diaLogico(_ data: Date) -> String {
        chaveDoDia(data.addingTimeInterval(Double(-horaViradaDoDia * 3600)))
    }

    func proximaVirada(depois data: Date) -> Date {
        let cal = Calendar.current
        var d = cal.date(bySettingHour: horaViradaDoDia, minute: 0, second: 0, of: data) ?? data
        if d <= data { d = cal.date(byAdding: .day, value: 1, to: d) ?? d }
        return d
    }

    func extrasAtivos(em data: Date) -> [(BotaoExtra, Date)] {
        let cal = Calendar.current
        let semana = cal.component(.weekday, from: data)
        let agora = minutoDoDia(data)
        var ativos: [(BotaoExtra, Date)] = []
        for extra in extras where !extra.nome.isEmpty {
            for o in extra.ocorrencias where o.dias.contains(semana) && dentro(agora, o.inicio, o.fim) {
                var fim = cal.startOfDay(for: data).addingTimeInterval(Double(o.fim * 60))
                if fim <= data { fim = cal.date(byAdding: .day, value: 1, to: fim) ?? fim }
                ativos.append((extra, fim))
                break
            }
        }
        return ativos
    }
}

func minutoDoDia(_ data: Date) -> Int {
    let c = Calendar.current.dateComponents([.hour, .minute], from: data)
    return (c.hour ?? 0) * 60 + (c.minute ?? 0)
}

func dentro(_ m: Int, _ inicio: Int, _ fim: Int) -> Bool {
    inicio <= fim ? (m >= inicio && m < fim) : (m >= inicio || m < fim)
}

func chaveDoDia(_ data: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: data)
}

func dataDaChave(_ chave: String) -> Date? {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f.date(from: chave)
}

func textoHora(_ minutos: Int) -> String {
    String(format: "%02d:%02d", minutos / 60, minutos % 60)
}
