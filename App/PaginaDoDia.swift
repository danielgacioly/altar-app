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
    @State private var celebrar = 0

    private enum Captura { case texto, nota, oracao }

    private var dia: Dia { loja.dia(chave) }
    private var ehHoje: Bool { chave == lembrete.estado.dia }

    private var captura: Captura? {
        if ditadoTexto.gravando || ditadoTexto.preparando { return .texto }
        if ditado.gravando || ditado.preparando { return .nota }
        if gravador.gravando { return .oracao }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cabecalho.entrada(0)
                if ehHoje {
                    mensagemDoDia.entrada(1)
                }

                Group {
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
                }
                .entrada(2)

                if let erro {
                    Label(erro, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, captura == nil ? 24 : 96)
            .frame(maxWidth: 1500)
            .frame(maxWidth: .infinity)
            .modifier(Largura(largura: $largura))
        }
        .overlay(alignment: .bottom) {
            barra
                .animation(.spring(duration: 0.45, bounce: 0.28), value: captura)
        }
        .navigationTitle(ehHoje ? "Hoje" : tituloDoDia(chave))
        .onDisappear {
            tocador.parar()
            encerrarCapturas()
        }
        .sensoryFeedback(.levelChange, trigger: celebrar)
    }

    private var cabecalho: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tituloDoDia(chave))
                .font(.system(size: 30, weight: .bold))
            Text(ehHoje ? "Seu devocional de hoje" : "Seu devocional deste dia")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var mensagemDoDia: some View {
        if let v = dia.versiculo {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mensagem do dia")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(verde)
                Citacao(versiculo: v)
            }
            .padding(.vertical, 4)
            .frame(maxWidth: 900, alignment: .leading)
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
                        .symbolEffect(.bounce.up, options: .nonRepeating, value: celebrar)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Devocional registrado")
                            .font(.title3.weight(.semibold))
                        let n = loja.sequenciaAtual(hoje: lembrete.estado.dia)
                        if ehHoje && n > 0 {
                            Text(n == 1 ? "1 dia seguido" : "\(n) dias seguidos")
                                .opacity(0.85)
                                .contentTransition(.numericText(value: Double(n)))
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
                    Button("Desfazer") {
                        withAnimation(.snappy) { lembrete.marcarFeito(chave, em: nil) }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(verdeFundo, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .transition(.scale(scale: 0.96).combined(with: .opacity))
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
                    withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                        lembrete.marcarFeito(chave, em: horarioPadrao())
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { celebrar += 1 }
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
            .modifier(Superficie())
            .transition(.scale(scale: 0.96).combined(with: .opacity))
        }
    }

    private var devocional: some View {
        Cartao(titulo: "Devocional", preencher: largura > 980) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Texto bíblico")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("Texto bíblico", text: Binding(get: { dia.leitura }, set: { t in loja.mudar(chave) { $0.leitura = t } }), prompt: Text("Ex.: Romanos 8:28-39"))
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .padding(10)
                    .background(.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                    .background(.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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

            if let e = ditadoTexto.erro {
                Text(e).foregroundStyle(.red).font(.callout)
            }
        } acoes: {
            Button(action: alternarDitadoTexto) {
                Label(ditadoTexto.gravando ? "Parar" : "Ditar", systemImage: ditadoTexto.gravando ? "stop.fill" : "mic.fill")
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(ditadoTexto.gravando ? .red : nil)
            .disabled(ditadoTexto.preparando || (captura != nil && captura != .texto))
            .help("Ditar no que você escreveu")
        }
    }

    private var notas: some View {
        Cartao(titulo: "Notas") {
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

            if let r = rascunho {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confira o texto antes de salvar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Texto ditado", text: Binding(get: { r }, set: { rascunho = $0 }), axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                Button(action: alternarDitado) {
                    Label(ditado.gravando ? "Parar" : "Ditar", systemImage: ditado.gravando ? "stop.fill" : "mic.fill")
                        .contentTransition(.symbolEffect(.replace))
                }
                .tint(ditado.gravando ? .red : nil)
                .disabled(ditado.preparando || (captura != nil && captura != .nota))
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
        Cartao(titulo: "Orações") {
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
                .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }

            if let e = gravador.erro {
                Text(e).foregroundStyle(.red).font(.callout)
            }
        } acoes: {
            Button(action: alternarGravacao) {
                Label(gravador.gravando ? "Parar" : "Gravar", systemImage: gravador.gravando ? "stop.fill" : "record.circle")
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(gravador.gravando ? .red : nil)
            .disabled(captura != nil && captura != .oracao)
            .help("Gravar uma oração em áudio")
        }
    }

    @ViewBuilder
    private var barra: some View {
        if let c = captura {
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(.red)
                            .frame(width: 9, height: 9)
                            .phaseAnimator([1.0, 0.3]) { ponto, fase in
                                ponto.opacity(fase)
                            } animation: { _ in .easeInOut(duration: 0.9) }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(c == .oracao ? "Gravando oração" : (c == .nota ? "Ditando uma nota" : "Ditando no seu texto"))
                                .font(.callout.weight(.semibold))
                            detalhe(c)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }
                        .frame(minWidth: 180, maxWidth: 440, alignment: .leading)
                    }
                    .padding(.leading, 18)
                    .padding(.trailing, 22)
                    .padding(.vertical, 11)
                    .glassEffect(.regular, in: Capsule())

                    Button {
                        switch c {
                        case .texto: alternarDitadoTexto()
                        case .nota: alternarDitado()
                        case .oracao: alternarGravacao()
                        }
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                    .tint(.red)
                    .disabled(ditado.preparando || ditadoTexto.preparando)
                    .help("Parar")
                }
            }
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private func detalhe(_ c: Captura) -> some View {
        switch c {
        case .oracao:
            if let inicio = gravador.inicio {
                TimelineView(.periodic(from: inicio, by: 1)) { ctx in
                    Text(duracaoTexto(ctx.date.timeIntervalSince(inicio)))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
        case .texto:
            Text(ditadoTexto.preparando ? "Preparando o microfone…" : (ditadoTexto.texto.isEmpty ? "Pode falar. O texto entra no fim do que você escreveu." : ditadoTexto.texto))
        case .nota:
            Text(ditado.preparando ? "Preparando o microfone…" : (ditado.texto.isEmpty ? "Pode falar. Você confere antes de salvar." : ditado.texto))
        }
    }

    private func alternarDitadoTexto() {
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
    }

    private func alternarDitado() {
        Task {
            if ditado.gravando {
                await ditado.parar()
                withAnimation(.snappy) { rascunho = ditado.texto }
            } else {
                rascunho = nil
                await ditado.iniciar()
            }
        }
    }

    private func alternarGravacao() {
        if gravador.gravando {
            if let o = gravador.parar() {
                withAnimation(.snappy) { loja.mudar(chave) { $0.oracoes.append(o) } }
            }
        } else {
            tocador.parar()
            Task { await gravador.iniciar() }
        }
    }

    private func encerrarCapturas() {
        if gravador.gravando {
            alternarGravacao()
        }
        if ditadoTexto.gravando {
            alternarDitadoTexto()
        }
        if ditado.gravando {
            let chave = chave
            Task {
                await ditado.parar()
                let t = ditado.texto
                if !t.isEmpty {
                    loja.mudar(chave) { $0.notas.append(Nota(texto: t)) }
                }
            }
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
                    .background(.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(verde.opacity(mudou ? 0.6 : 0)))
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
                .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .animation(.snappy(duration: 0.2), value: mudou)
        .onChange(of: nota.texto) { _, novo in texto = novo }
    }
}
