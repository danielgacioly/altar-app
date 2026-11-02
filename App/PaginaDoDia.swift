import SwiftUI

struct PaginaDoDia: View {
    let chave: String
    @EnvironmentObject var loja: Loja
    @EnvironmentObject var lembrete: Lembrete
    @StateObject private var ditado = Ditado()
    @StateObject private var ditadoTexto = Ditado()
    @StateObject private var gravador = Gravador()
    @StateObject private var tocador = Tocador()
    @State private var rascunho: String?
    @State private var transcrevendo: Set<UUID> = []
    @State private var erro: String?
    @State private var largura: CGFloat = 0

    private var dia: Dia { loja.dia(chave) }
    private var ehHoje: Bool { chave == lembrete.estado.dia }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cabecalho
                if ehHoje {
                    mensagemDoDia
                }

                if largura > 980 {
                    HStack(alignment: .top, spacing: 20) {
                        devocional
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        VStack(spacing: 20) {
                            registro
                            notas
                            oracoes
                            Spacer(minLength: 0)
                        }
                        .frame(width: min(440, largura * 0.38))
                        .frame(maxHeight: .infinity)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    registro
                    devocional
                    notas
                    oracoes
                }

                if let erro {
                    Label(erro, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: 1500)
            .frame(maxWidth: .infinity)
            .modifier(Largura(largura: $largura))
        }
        .navigationTitle(ehHoje ? "Hoje" : tituloDoDia(chave))
        .onDisappear { tocador.parar() }
    }

    private var cabecalho: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tituloDoDia(chave))
                .font(.largeTitle.weight(.bold))
            Text(ehHoje ? "Seu devocional de hoje" : "Seu devocional deste dia")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var mensagemDoDia: some View {
        if let v = dia.versiculo {
            VStack(alignment: .leading, spacing: 10) {
                Label("Mensagem do dia", systemImage: "quote.opening")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .opacity(0.75)
                Text(v.texto)
                    .font(.system(.title2, design: .serif))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                if !v.rodape.isEmpty {
                    Text(v.rodape)
                        .font(.callout.weight(.semibold))
                        .opacity(0.85)
                }
            }
            .foregroundStyle(.white)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [verdeFundo, verdeFundo.mix(with: .black, by: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
    }

    @ViewBuilder
    private var registro: some View {
        if let f = dia.feitoEm {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Devocional registrado")
                            .font(.title3.weight(.semibold))
                        let n = loja.sequenciaAtual(hoje: lembrete.estado.dia)
                        if ehHoje && n > 0 {
                            Text(n == 1 ? "1 dia seguido" : "\(n) dias seguidos")
                                .opacity(0.85)
                        }
                    }
                    .foregroundStyle(.white)
                }
                HStack {
                    Text("Às")
                        .foregroundStyle(.white.opacity(0.85))
                    DatePicker("Horário", selection: Binding(get: { f }, set: { lembrete.marcarFeito(chave, em: $0) }), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .fixedSize()
                    Spacer()
                    Button("Desfazer") { lembrete.marcarFeito(chave, em: nil) }
                        .buttonStyle(.bordered)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(verdeFundo, in: RoundedRectangle(cornerRadius: 16))
        } else {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 30))
                        .foregroundStyle(verde)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ehHoje ? "Já fez o devocional hoje?" : "Fez o devocional neste dia?")
                            .font(.title3.weight(.semibold))
                        Text("Registre para contar na sua sequência.")
                            .foregroundStyle(.secondary)
                    }
                }
                Button {
                    lembrete.marcarFeito(chave, em: horarioPadrao())
                } label: {
                    Label("Registrar devocional", systemImage: "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(verdeFundo)
                .controlSize(.extraLarge)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(verde.opacity(0.5), lineWidth: 1.5))
        }
    }

    private var devocional: some View {
        Cartao(titulo: "Devocional", icone: "book.closed", preencher: largura > 980) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Texto bíblico")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("Texto bíblico", text: Binding(get: { dia.leitura }, set: { t in loja.mudar(chave) { $0.leitura = t } }), prompt: Text("Ex.: Romanos 8:28-39"))
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .padding(10)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("O que eu escrevi")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextEditor(text: Binding(get: { dia.texto }, set: { t in loja.mudar(chave) { $0.texto = t } }))
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .frame(minHeight: 260, maxHeight: .infinity)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .topLeading) {
                        if dia.texto.isEmpty {
                            Text("O que Deus falou com você nesse texto?")
                                .font(.system(size: 15))
                                .foregroundStyle(.tertiary)
                                .padding(.leading, 11)
                                .padding(.top, 6)
                                .allowsHitTesting(false)
                        }
                    }
            }
            .frame(maxHeight: .infinity)

            if ditadoTexto.gravando || ditadoTexto.preparando {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "waveform")
                        .symbolEffect(.variableColor.iterative, isActive: ditadoTexto.gravando)
                        .foregroundStyle(.red)
                    Text(ditadoTexto.preparando ? "Preparando o microfone…" : (ditadoTexto.texto.isEmpty ? "Pode falar. O texto entra no fim do que você escreveu." : ditadoTexto.texto))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            if let e = ditadoTexto.erro {
                Text(e).foregroundStyle(.red).font(.callout)
            }
        } acoes: {
            Button {
                Task {
                    if ditadoTexto.gravando {
                        await ditadoTexto.parar()
                        let t = ditadoTexto.texto
                        if !t.isEmpty {
                            loja.mudar(chave) { d in
                                d.texto = d.texto.isEmpty ? t : d.texto + (d.texto.hasSuffix("\n") ? "" : "\n") + t
                            }
                        }
                    } else {
                        await ditadoTexto.iniciar()
                    }
                }
            } label: {
                Label(ditadoTexto.gravando ? "Parar" : "Ditar", systemImage: ditadoTexto.gravando ? "stop.fill" : "mic.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(ditadoTexto.gravando ? .red : nil)
            .disabled(ditadoTexto.preparando || ditado.gravando)
            .help("Ditar no que você escreveu")
        }
    }

    private var notas: some View {
        Cartao(titulo: "Notas", icone: "note.text") {
            if dia.notas.isEmpty && rascunho == nil && !ditado.gravando && !ditado.preparando {
                Vazio(texto: "Nenhuma nota ainda. Escreva ou dite pelo microfone.")
            }

            ForEach(dia.notas) { nota in
                NotaEditavel(nota: nota) { t in
                    loja.mudar(chave) { d in
                        if let i = d.notas.firstIndex(where: { $0.id == nota.id }) { d.notas[i].texto = t }
                    }
                } apagar: {
                    loja.mudar(chave) { $0.notas.removeAll { $0.id == nota.id } }
                }
            }

            if ditado.gravando || ditado.preparando {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "waveform")
                        .symbolEffect(.variableColor.iterative, isActive: ditado.gravando)
                        .foregroundStyle(.red)
                    Text(ditado.preparando ? "Preparando o microfone…" : (ditado.texto.isEmpty ? "Pode falar…" : ditado.texto))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            if let r = rascunho {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confira o texto antes de salvar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Texto ditado", text: Binding(get: { r }, set: { rascunho = $0 }), axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    HStack {
                        Button("Descartar") { rascunho = nil }
                        Button("Salvar nota") {
                            let t = r.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !t.isEmpty { loja.mudar(chave) { $0.notas.append(Nota(texto: t)) } }
                            rascunho = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(verdeFundo)
                        .keyboardShortcut(.defaultAction)
                    }
                }
            }

            if let e = ditado.erro {
                Text(e).foregroundStyle(.red).font(.callout)
            }
        } acoes: {
            HStack(spacing: 6) {
                Button {
                    Task {
                        if ditado.gravando {
                            await ditado.parar()
                            rascunho = ditado.texto
                        } else {
                            rascunho = nil
                            await ditado.iniciar()
                        }
                    }
                } label: {
                    Label(ditado.gravando ? "Parar" : "Ditar", systemImage: ditado.gravando ? "stop.fill" : "mic.fill")
                }
                .tint(ditado.gravando ? .red : nil)
                .disabled(ditado.preparando || ditadoTexto.gravando)
                .help("Ditar uma nota pelo microfone")
                Button {
                    loja.mudar(chave) { $0.notas.append(Nota(texto: "")) }
                } label: {
                    Image(systemName: "plus")
                }
                .help("Nova nota")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var oracoes: some View {
        Cartao(titulo: "Orações", icone: "hands.and.sparkles") {
            if dia.oracoes.isEmpty && !gravador.gravando {
                Vazio(texto: "Grave uma oração para ouvir depois.")
            }

            ForEach(dia.oracoes) { o in
                HStack(spacing: 10) {
                    Button {
                        tocador.alternar(o, loja.urlDaOracao(o))
                    } label: {
                        Image(systemName: tocador.tocando == o.id ? "stop.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(verdeFundo, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help(tocador.tocando == o.id ? "Parar" : "Ouvir")
                    VStack(alignment: .leading, spacing: 1) {
                        Text(horaTexto(o.gravadaEm))
                        Text(duracaoTexto(o.duracao))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Spacer()
                    if transcrevendo.contains(o.id) {
                        ProgressView().controlSize(.small)
                    } else {
                        Button("Transcrever") { transcrever(o) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Transcreve e adiciona às notas")
                    }
                    Button {
                        if tocador.tocando == o.id { tocador.parar() }
                        try? FileManager.default.removeItem(at: loja.urlDaOracao(o))
                        loja.mudar(chave) { $0.oracoes.removeAll { $0.id == o.id } }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help("Apagar oração")
                }
                .padding(8)
                .background(.background, in: RoundedRectangle(cornerRadius: 10))
            }

            if let inicio = gravador.inicio {
                HStack(spacing: 10) {
                    Image(systemName: "record.circle.fill")
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse)
                    Text("Gravando")
                    TimelineView(.periodic(from: inicio, by: 1)) { ctx in
                        Text(duracaoTexto(ctx.date.timeIntervalSince(inicio)))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            if let e = gravador.erro {
                Text(e).foregroundStyle(.red).font(.callout)
            }
        } acoes: {
            Button {
                if gravador.gravando {
                    if let o = gravador.parar() {
                        loja.mudar(chave) { $0.oracoes.append(o) }
                    }
                } else {
                    tocador.parar()
                    Task { await gravador.iniciar() }
                }
            } label: {
                Label(gravador.gravando ? "Parar" : "Gravar", systemImage: gravador.gravando ? "stop.fill" : "record.circle")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(gravador.gravando ? .red : nil)
            .help("Gravar uma oração em áudio")
        }
    }

    private func horarioPadrao() -> Date {
        if ehHoje { return Date() }
        let base = dataDaChave(chave) ?? Date()
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: base) ?? base
    }

    private func transcrever(_ o: Oracao) {
        transcrevendo.insert(o.id)
        erro = nil
        Task {
            do {
                let t = try await Fala.transcrever(loja.urlDaOracao(o))
                if !t.isEmpty {
                    loja.mudar(chave) { $0.notas.append(Nota(texto: "Oração: " + t)) }
                }
            } catch {
                erro = "Não deu pra transcrever: \(error.localizedDescription)"
            }
            transcrevendo.remove(o.id)
        }
    }
}

struct NotaEditavel: View {
    let nota: Nota
    let salvar: (String) -> Void
    let apagar: () -> Void
    @State private var texto: String

    init(nota: Nota, salvar: @escaping (String) -> Void, apagar: @escaping () -> Void) {
        self.nota = nota
        self.salvar = salvar
        self.apagar = apagar
        _texto = State(initialValue: nota.texto)
    }

    private var mudou: Bool { texto != nota.texto }

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                TextField("Nota", text: $texto, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(verde.opacity(mudou ? 0.6 : 0)))
                Button(action: apagar) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Apagar nota")
            }
            if mudou {
                HStack {
                    Button("Descartar") { texto = nota.texto }
                    Button("Salvar alterações") { salvar(texto) }
                        .buttonStyle(.borderedProminent)
                        .tint(verdeFundo)
                }
                .controlSize(.small)
                .padding(.trailing, 24)
            }
        }
        .onChange(of: nota.texto) { _, novo in texto = novo }
    }
}
