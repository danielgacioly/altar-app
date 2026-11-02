import ServiceManagement
import SwiftUI

enum Aba: String, CaseIterable, Identifiable {
    case lembretes = "Lembretes"
    case sistema = "Sistema"

    var id: String { rawValue }
}

struct Ajustes: View {
    @EnvironmentObject var loja: Loja
    @EnvironmentObject var lembrete: Lembrete
    @State private var aba = Aba.lembretes
    @State private var noLogin = SMAppService.mainApp.status == .enabled
    @State private var erroLogin: String?
    @State private var confirmar = false
    @State private var largura: CGFloat = 0

    private var largo: Bool { largura > 980 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                switch aba {
                case .lembretes:
                    lembretes
                    VStack(alignment: .leading, spacing: 16) { extras }
                    VStack(alignment: .leading, spacing: 16) { faixas }
                case .sistema:
                    sistema
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
            Grupo(titulo: "Frequência", icone: "bell.badge", rodape: "Tela bloqueada e Mac dormindo também não contam.") {
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
            Grupo(titulo: "Horários", icone: "moon.zzz", rodape: nil) {
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
        Cabecalho(titulo: "Botões extras", icone: "hand.tap", texto: "Aparecem na notificação só nos dias e horários escolhidos, junto com Sim, Não e Me lembra. Exemplo: \"Estou na faculdade\" de segunda a quinta, das 17h às 21h. Se dois valerem ao mesmo tempo, aparece o primeiro da lista.") {
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
        Cabecalho(titulo: "Faixas e frases", icone: "text.bubble", texto: "Cada faixa vai do seu horário até o começo da próxima. A frase do lembrete é sorteada entre as da faixa, sem repetir a anterior.") {
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
            Grupo(titulo: "Sistema", icone: "macwindow", rodape: erroLogin) {
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
        } _: {
            Grupo(titulo: "Padrão", icone: "arrow.counterclockwise", rodape: "Mensagens e páginas dos dias não mudam.") {
                Linha("Restaurar ajustes padrão", "Volta intervalos, horários, botões extras e faixas ao que vem com o app.") {
                    Button("Restaurar…", role: .destructive) { confirmar = true }
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
    let icone: String
    let rodape: String?
    @ViewBuilder var conteudo: Conteudo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(titulo)
            } icon: {
                Image(systemName: icone).foregroundStyle(verde)
            }
            .font(.headline)
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
    let icone: String
    let texto: String
    @ViewBuilder var acao: Acao

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Label {
                    Text(titulo)
                } icon: {
                    Image(systemName: icone).foregroundStyle(verde)
                }
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
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator.opacity(0.6)))
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
                        .background(.background, in: RoundedRectangle(cornerRadius: 10))
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
