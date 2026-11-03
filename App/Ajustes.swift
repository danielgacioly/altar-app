import ServiceManagement
import SwiftUI

enum Aba: String, CaseIterable, Identifiable {
    case lembretes = "Lembretes"
    case sistema = "Sistema"

    var id: String { rawValue }
}

enum Aparencia: String, CaseIterable, Identifiable {
    case automatico, claro, escuro

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .automatico: "Automático"
        case .claro: "Claro"
        case .escuro: "Escuro"
        }
    }

    static var salva: Aparencia {
        Aparencia(rawValue: UserDefaults.standard.string(forKey: "aparencia") ?? "") ?? .automatico
    }

    func aplicar() {
        switch self {
        case .automatico: NSApp.appearance = nil
        case .claro: NSApp.appearance = NSAppearance(named: .aqua)
        case .escuro: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

struct Ajustes: View {
    @EnvironmentObject var loja: Loja
    @EnvironmentObject var lembrete: Lembrete
    @State private var aba = Aba.lembretes
    @State private var noLogin = SMAppService.mainApp.status == .enabled
    @State private var erroLogin: String?
    @State private var confirmar = false
    @State private var largura: CGFloat = 0
    @AppStorage("aparencia") private var aparencia = Aparencia.automatico

    private var largo: Bool { largura > 980 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                switch aba {
                case .lembretes:
                    lembretes.entrada(0)
                    VStack(alignment: .leading, spacing: 16) { extras }.entrada(1)
                    VStack(alignment: .leading, spacing: 16) { faixas }.entrada(2)
                case .sistema:
                    sistema.entrada(0)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: 1500)
            .frame(maxWidth: .infinity)
            .modifier(Largura(largura: $largura))
        }
        .navigationTitle("Ajustes")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Seção", selection: $aba) {
                    ForEach(Aba.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
        }
        .confirmationDialog("Voltar todos os ajustes para o padrão? Mensagens e páginas dos dias não mudam.", isPresented: $confirmar) {
            Button("Restaurar", role: .destructive) { loja.config = Config() }
        }
    }

    private func lado<A: View, B: View>(@ViewBuilder _ a: () -> A, @ViewBuilder _ b: () -> B) -> some View {
        Group {
            if largo {
                HStack(alignment: .top, spacing: 20) {
                    a().frame(maxHeight: .infinity, alignment: .top)
                    b().frame(maxHeight: .infinity, alignment: .top)
                }
                .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 24) {
                    a()
                    b()
                }
            }
        }
    }

    private var lembretes: some View {
        lado {
            Grupo(titulo: "Frequência", rodape: "Tela bloqueada e Mac dormindo também não contam.") {
                Linha("Intervalo entre lembretes", "Tempo de uso do Mac até o próximo lembrete.") {
                    Stepper("\(loja.config.minutosEntreLembretes) min", value: $loja.config.minutosEntreLembretes, in: 5...240, step: 5)
                }
                Divider()
                Linha("\"Me lembra\" adia por", "Quanto o botão de adiar empurra o próximo lembrete.") {
                    Stepper("\(loja.config.minutosAdiar) min", value: $loja.config.minutosAdiar, in: 5...120, step: 5)
                }
                Divider()
                Linha("Parar de contar depois de", "Teclado e mouse parados por esse tempo não contam como uso.") {
                    Stepper("\(loja.config.minutosOcioso) min", value: $loja.config.minutosOcioso, in: 1...15)
                }
            }
        } _: {
            Grupo(titulo: "Horários", rodape: nil) {
                Linha("O dia vira às", "Antes desse horário, o que você fizer conta para o dia anterior.") {
                    Picker("O dia vira às", selection: $loja.config.horaViradaDoDia) {
                        ForEach(0..<7) { Text("\($0)h").tag($0) }
                    }
                    .labelsHidden()
                }
                Divider()
                Linha("Sem lembretes", "Horário em que o Altar fica quieto, como a madrugada.") {
                    HStack {
                        Text("das")
                        hora($loja.config.inicioSilencio)
                        Text("às")
                        hora($loja.config.fimSilencio)
                    }
                }
            }
        }
    }

    private var colunas: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16, alignment: .top), count: largura > 1300 ? 3 : (largo ? 2 : 1))
    }

    @ViewBuilder
    private var extras: some View {
        Cabecalho(titulo: "Botões extras", texto: "Aparecem na notificação só nos dias e horários escolhidos, junto com Sim, Não e Me lembra. Exemplo: \"Estou na faculdade\" de segunda a quinta, das 17h às 21h. Se dois valerem ao mesmo tempo, aparece o primeiro da lista.") {
            Button {
                loja.config.extras.append(BotaoExtra(nome: "Novo botão", ocorrencias: [Ocorrencia(dias: [2, 3, 4, 5, 6], inicio: 9 * 60, fim: 12 * 60)]))
            } label: {
                Label("Novo botão extra", systemImage: "plus")
            }
        }
        if loja.config.extras.isEmpty {
            Vazio(texto: "Nenhum botão extra.")
        }
        LazyVGrid(columns: colunas, alignment: .leading, spacing: 16) {
            ForEach($loja.config.extras) { $extra in
                EditorDeExtra(extra: $extra) {
                    loja.config.extras.removeAll { $0.id == extra.id }
                }
                .modifier(Caixa())
            }
        }
    }

    @ViewBuilder
    private var faixas: some View {
        Cabecalho(titulo: "Faixas e frases", texto: "Cada faixa vai do seu horário até o começo da próxima. A frase do lembrete é sorteada entre as da faixa, sem repetir a anterior.") {
            Button {
                loja.config.faixas.append(Faixa(nome: "Nova faixa", inicio: 12 * 60, frases: ["Já fez o devocional hoje?"]))
            } label: {
                Label("Nova faixa", systemImage: "plus")
            }
        }
        LazyVGrid(columns: colunas, alignment: .leading, spacing: 16) {
            ForEach($loja.config.faixas) { $faixa in
                EditorDeFaixa(faixa: $faixa) {
                    loja.config.faixas.removeAll { $0.id == faixa.id }
                }
                .modifier(Caixa())
            }
        }
    }

    private var sistema: some View {
        lado {
            Grupo(titulo: "Aparência", rodape: "No automático, o Altar acompanha o modo claro ou escuro do Mac.") {
                HStack(alignment: .top, spacing: 22) {
                    ForEach(Aparencia.allCases) { a in
                        OpcaoDeAparencia(aparencia: a, escolhida: aparencia == a) {
                            withAnimation(.snappy) { aparencia = a }
                            a.aplicar()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
            }
        } _: {
            VStack(spacing: 24) {
                Grupo(titulo: "Sistema", rodape: erroLogin) {
                    Linha("Abrir junto com o login", "O Altar começa a contar assim que você entra no Mac.") {
                        Toggle("Abrir junto com o login", isOn: Binding(get: { noLogin }, set: { mudarLogin($0) }))
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    Divider()
                    Linha("Estilo da notificação", lembrete.estiloAlerta ? "Alerta: fica na tela até você responder." : "Faixa: some sozinha. Mude para Alertas para não perder o lembrete.") {
                        Button("Abrir ajustes…") { lembrete.abrirAjustesDeNotificacao() }
                    }
                }
                Grupo(titulo: "Padrão", rodape: "Mensagens e páginas dos dias não mudam.") {
                    Linha("Restaurar ajustes padrão", "Volta intervalos, horários, botões extras e faixas ao que vem com o app.") {
                        Button("Restaurar…", role: .destructive) { confirmar = true }
                    }
                }
            }
        }
    }

    private func mudarLogin(_ ligar: Bool) {
        erroLogin = nil
        do {
            if ligar {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            erroLogin = "Não deu pra mudar: \(error.localizedDescription). Coloque o Altar na pasta Aplicativos."
        }
        noLogin = SMAppService.mainApp.status == .enabled
    }
}

struct Linha<Controle: View>: View {
    let titulo: String
    let detalhe: String
    @ViewBuilder var controle: Controle

    init(_ titulo: String, _ detalhe: String, @ViewBuilder controle: () -> Controle) {
        self.titulo = titulo
        self.detalhe = detalhe
        self.controle = controle()
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(titulo)
                Text(detalhe)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            controle
                .monospacedDigit()
                .fixedSize()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

struct Grupo<Conteudo: View>: View {
    let titulo: String
    let rodape: String?
    @ViewBuilder var conteudo: Conteudo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titulo)
                .font(.headline)
                .padding(.horizontal, 4)
            VStack(alignment: .leading, spacing: 0) {
                conteudo
            }
            .modifier(Caixa())
            if let rodape {
                Text(rodape)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            Spacer(minLength: 0)
        }
    }
}

struct Cabecalho<Acao: View>: View {
    let titulo: String
    let texto: String
    @ViewBuilder var acao: Acao

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(titulo)
                    .font(.headline)
                Text(texto)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            acao
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }
}

struct Caixa: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(Superficie(raio: 14))
    }
}

struct Expansivel<Titulo: View, Conteudo: View>: View {
    @State private var aberto = false
    @ViewBuilder var titulo: Titulo
    @ViewBuilder var conteudo: Conteudo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy) { aberto.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(aberto ? 90 : 0))
                        .frame(width: 12)
                    titulo
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if aberto {
                Divider()
                conteudo
                    .padding(16)
                    .transition(.opacity.combined(with: .offset(y: -6)))
            }
        }
    }
}

func hora(_ minutos: Binding<Int>) -> some View {
    DatePicker("", selection: Binding(
        get: { Calendar.current.startOfDay(for: Date()).addingTimeInterval(Double(minutos.wrappedValue * 60)) },
        set: { minutos.wrappedValue = minutoDoDia($0) }
    ), displayedComponents: .hourAndMinute)
    .labelsHidden()
    .fixedSize()
}

struct EditorDeExtra: View {
    @Binding var extra: BotaoExtra
    let apagar: () -> Void

    var body: some View {
        Expansivel {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(extra.nome.isEmpty ? "Sem nome" : extra.nome)
                        .font(.body.weight(.semibold))
                    Text(resumo)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        } conteudo: {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Nome do botão", text: $extra.nome)
                    .textFieldStyle(.roundedBorder)
                Picker("Ao clicar", selection: $extra.efeito) {
                    ForEach(Efeito.allCases) { Text($0.nome).tag($0) }
                }
                .fixedSize()
                if extra.efeito == .porMinutos {
                    Stepper("Por \(extra.minutos) min", value: $extra.minutos, in: 5...600, step: 5)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quando aparece")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach($extra.ocorrencias) { $o in
                        HStack(spacing: 12) {
                            SeletorDeDias(dias: $o.dias)
                            Spacer()
                            hora($o.inicio)
                            Text("às")
                            hora($o.fim)
                            Button {
                                let id = o.id
                                extra.ocorrencias.removeAll { $0.id == id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .help("Remover horário")
                        }
                        .padding(10)
                        .background(.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    Button {
                        extra.ocorrencias.append(Ocorrencia(dias: [2, 3, 4, 5, 6], inicio: 9 * 60, fim: 12 * 60))
                    } label: {
                        Label("Adicionar horário", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                }
                Button("Apagar botão", role: .destructive, action: apagar)
                    .buttonStyle(.borderless)
            }
        }
    }

    private var resumo: String {
        let n = extra.ocorrencias.count
        return extra.efeito.nome + " · " + (n == 1 ? "1 horário" : "\(n) horários")
    }
}

struct SeletorDeDias: View {
    @Binding var dias: Set<Int>
    private let letras = ["D", "S", "T", "Q", "Q", "S", "S"]
    private let nomes = ["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...7, id: \.self) { d in
                let ligado = dias.contains(d)
                Button {
                    if ligado { dias.remove(d) } else { dias.insert(d) }
                } label: {
                    Text(letras[d - 1])
                        .font(.caption.bold())
                        .frame(width: 26, height: 26)
                        .foregroundStyle(ligado ? .white : .primary)
                        .background(ligado ? verdeFundo : Color.secondary.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
                .help(nomes[d - 1])
            }
        }
    }
}

struct EditorDeFaixa: View {
    @Binding var faixa: Faixa
    let apagar: () -> Void

    var body: some View {
        Expansivel {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(faixa.nome)
                        .font(.body.weight(.semibold))
                    Text(faixa.frases.count == 1 ? "1 frase" : "\(faixa.frases.count) frases")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("a partir das \(textoHora(faixa.inicio))")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        } conteudo: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    TextField("Nome da faixa", text: $faixa.nome)
                        .textFieldStyle(.roundedBorder)
                    Text("Começa às")
                    hora($faixa.inicio)
                }
                Text("Frases")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(faixa.frases.indices, id: \.self) { i in
                    HStack {
                        TextField("Frase", text: Binding(
                            get: { i < faixa.frases.count ? faixa.frases[i] : "" },
                            set: { if i < faixa.frases.count { faixa.frases[i] = $0 } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        Button {
                            if i < faixa.frases.count {
                                faixa.frases.remove(at: i)
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .help("Remover frase")
                    }
                }
                HStack {
                    Button {
                        faixa.frases.append("")
                    } label: {
                        Label("Adicionar frase", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                    Button("Apagar faixa", role: .destructive, action: apagar)
                        .buttonStyle(.borderless)
                }
            }
        }
    }
}

struct OpcaoDeAparencia: View {
    let aparencia: Aparencia
    let escolhida: Bool
    let escolher: () -> Void

    var body: some View {
        Button(action: escolher) {
            VStack(spacing: 10) {
                miniatura
                    .frame(width: 132, height: 86)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.primary.opacity(0.16), lineWidth: 1))
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(verde, lineWidth: escolhida ? 3 : 0))
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                Text(aparencia.nome)
                    .font(.callout.weight(escolhida ? .semibold : .regular))
                    .foregroundStyle(escolhida ? .primary : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(escolhida ? .isSelected : [])
    }

    @ViewBuilder
    private var miniatura: some View {
        switch aparencia {
        case .claro:
            MiniJanela(escuro: false)
        case .escuro:
            MiniJanela(escuro: true)
        case .automatico:
            MiniJanela(escuro: false)
                .overlay {
                    MiniJanela(escuro: true)
                        .mask(HStack(spacing: 0) { Color.clear; Color.black })
                }
        }
    }
}

struct MiniJanela: View {
    let escuro: Bool

    var body: some View {
        let fundo = escuro ? Color(white: 0.14) : Color(white: 0.985)
        let lateral = escuro ? Color(white: 0.22) : Color(white: 0.9)
        let traco = escuro ? Color.white.opacity(0.17) : Color.black.opacity(0.1)
        let marca = escuro ? Color(red: 0.09, green: 0.5, blue: 0.31) : Color(red: 0, green: 0.447, blue: 0.231)
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2.5) {
                    Circle().fill(Color(red: 1, green: 0.37, blue: 0.34))
                    Circle().fill(Color(red: 1, green: 0.74, blue: 0.18))
                    Circle().fill(Color(red: 0.16, green: 0.78, blue: 0.25))
                }
                .frame(width: 19, height: 5)
                .padding(.bottom, 5)
                Capsule().fill(marca).frame(width: 26, height: 5)
                Capsule().fill(traco).frame(width: 20, height: 4)
                Capsule().fill(traco).frame(width: 24, height: 4)
                Capsule().fill(traco).frame(width: 17, height: 4)
            }
            .padding(6)
            .frame(width: 40, alignment: .topLeading)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(lateral, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Capsule().fill(traco).frame(width: 36, height: 5)
                    .padding(.bottom, 2)
                RoundedRectangle(cornerRadius: 3, style: .continuous).fill(marca).frame(height: 14)
                Capsule().fill(traco).frame(height: 4)
                Capsule().fill(traco).frame(width: 44, height: 4)
            }
            .padding(.top, 8)
            .padding(.trailing, 8)
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(fundo)
    }
}
