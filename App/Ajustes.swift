import ServiceManagement
import SwiftUI

struct Ajustes: View {
    @EnvironmentObject var loja: Loja
    @EnvironmentObject var lembrete: Lembrete
    @State private var noLogin = SMAppService.mainApp.status == .enabled
    @State private var erroLogin: String?
    @State private var confirmar = false

    var body: some View {
        Form {
            Section("Lembretes") {
                Stepper("Um lembrete a cada \(loja.config.minutosEntreLembretes) min de uso", value: $loja.config.minutosEntreLembretes, in: 5...240, step: 5)
                Stepper("\"Me lembra\" adia por \(loja.config.minutosAdiar) min de uso", value: $loja.config.minutosAdiar, in: 5...120, step: 5)
                Stepper("Parado há \(loja.config.minutosOcioso) min ou mais não conta como uso", value: $loja.config.minutosOcioso, in: 1...15)
            }

            Section("Horários") {
                Picker("O dia vira às", selection: $loja.config.horaViradaDoDia) {
                    ForEach(0..<7) { Text("\($0)h").tag($0) }
                }
                HStack {
                    Text("Sem lembretes das")
                    Spacer()
                    hora($loja.config.inicioSilencio)
                    Text("às")
                    hora($loja.config.fimSilencio)
                }
            }

            Section {
                ForEach($loja.config.extras) { $extra in
                    EditorDeExtra(extra: $extra) {
                        loja.config.extras.removeAll { $0.id == extra.id }
                    }
                }
                Button {
                    loja.config.extras.append(BotaoExtra(nome: "Novo botão", ocorrencias: [Ocorrencia(dias: [2, 3, 4, 5, 6], inicio: 9 * 60, fim: 12 * 60)]))
                } label: {
                    Label("Novo botão extra", systemImage: "plus")
                }
            } header: {
                Text("Botões extras")
            } footer: {
                Text("Aparecem na notificação só nos dias e horários escolhidos, junto com Sim, Não e Me lembra. Se dois valerem ao mesmo tempo, aparece o primeiro da lista.")
            }

            Section {
                ForEach($loja.config.faixas) { $faixa in
                    EditorDeFaixa(faixa: $faixa) {
                        loja.config.faixas.removeAll { $0.id == faixa.id }
                    }
                }
                Button {
                    loja.config.faixas.append(Faixa(nome: "Nova faixa", inicio: 12 * 60, frases: ["Já fez o devocional hoje?"]))
                } label: {
                    Label("Nova faixa", systemImage: "plus")
                }
            } header: {
                Text("Faixas do dia e frases")
            } footer: {
                Text("Cada faixa vai do seu horário até o começo da próxima. A frase do lembrete é sorteada entre as da faixa, sem repetir a anterior.")
            }

            Section("Sistema") {
                Toggle("Abrir o Altar junto com o login", isOn: Binding(get: { noLogin }, set: { mudarLogin($0) }))
                if let erroLogin {
                    Text(erroLogin).foregroundStyle(.red).font(.callout)
                }
                LabeledContent("Estilo da notificação") {
                    HStack {
                        Text(lembrete.estiloAlerta ? "Alerta (fica na tela)" : "Faixa (some sozinha)")
                            .foregroundStyle(lembrete.estiloAlerta ? Color.secondary : Color.orange)
                        Button("Abrir ajustes…") { lembrete.abrirAjustesDeNotificacao() }
                    }
                }
                Button("Restaurar ajustes padrão", role: .destructive) { confirmar = true }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Ajustes")
        .confirmationDialog("Voltar todos os ajustes para o padrão? Versículos e páginas dos dias não mudam.", isPresented: $confirmar) {
            Button("Restaurar", role: .destructive) { loja.config = Config() }
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
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                TextField("Nome do botão", text: $extra.nome)
                Picker("Ao clicar", selection: $extra.efeito) {
                    ForEach(Efeito.allCases) { Text($0.nome).tag($0) }
                }
                if extra.efeito == .porMinutos {
                    Stepper("Por \(extra.minutos) min", value: $extra.minutos, in: 5...600, step: 5)
                }
                Text("Quando aparece").font(.callout.bold())
                ForEach($extra.ocorrencias) { $o in
                    HStack {
                        SeletorDeDias(dias: $o.dias)
                        Spacer()
                        hora($o.inicio)
                        Text("às")
                        hora($o.fim)
                        Button {
                            extra.ocorrencias.removeAll { $0.id == o.id }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                HStack {
                    Button("Adicionar horário") {
                        extra.ocorrencias.append(Ocorrencia(dias: [2, 3, 4, 5, 6], inicio: 9 * 60, fim: 12 * 60))
                    }
                    Spacer()
                    Button("Apagar botão", role: .destructive, action: apagar)
                }
            }
            .padding(.vertical, 6)
        } label: {
            Text(extra.nome.isEmpty ? "Sem nome" : extra.nome).bold()
        }
    }
}

struct SeletorDeDias: View {
    @Binding var dias: Set<Int>
    private let letras = ["D", "S", "T", "Q", "Q", "S", "S"]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...7, id: \.self) { d in
                let ligado = dias.contains(d)
                Button {
                    if ligado { dias.remove(d) } else { dias.insert(d) }
                } label: {
                    Text(letras[d - 1])
                        .font(.caption.bold())
                        .frame(width: 22, height: 22)
                        .foregroundStyle(ligado ? .white : .primary)
                        .background(ligado ? verde : Color.secondary.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct EditorDeFaixa: View {
    @Binding var faixa: Faixa
    let apagar: () -> Void

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Nome da faixa", text: $faixa.nome)
                    Text("Começa às")
                    hora($faixa.inicio)
                }
                ForEach(faixa.frases.indices, id: \.self) { i in
                    HStack {
                        TextField("Frase", text: Binding(
                            get: { i < faixa.frases.count ? faixa.frases[i] : "" },
                            set: { if i < faixa.frases.count { faixa.frases[i] = $0 } }
                        ))
                        Button {
                            faixa.frases.remove(at: i)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                HStack {
                    Button("Adicionar frase") { faixa.frases.append("") }
                    Spacer()
                    Button("Apagar faixa", role: .destructive, action: apagar)
                }
            }
            .padding(.vertical, 6)
        } label: {
            HStack {
                Text(faixa.nome).bold()
                Spacer()
                Text("a partir das \(textoHora(faixa.inicio))").foregroundStyle(.secondary)
            }
        }
    }
}
