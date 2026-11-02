import SwiftUI

struct PaginaDoDia: View {
    let chave: String
    @EnvironmentObject var loja: Loja
    @EnvironmentObject var lembrete: Lembrete
    @StateObject private var ditado = Ditado()
    @StateObject private var gravador = Gravador()
    @StateObject private var tocador = Tocador()
    @State private var rascunho: String?
    @State private var transcrevendo: Set<UUID> = []
    @State private var erro: String?

    private var dia: Dia { loja.dia(chave) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(tituloDoDia(chave))
                    .font(.largeTitle.bold())

                if let v = dia.versiculo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(v.texto)
                            .font(.title3)
                        Text("\(v.referencia) (\(v.versao))")
                            .font(.callout.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(verde, in: RoundedRectangle(cornerRadius: 12))
                }

                feito
                texto
                notas
                oracoes

                if let erro {
                    Text(erro).foregroundStyle(.red)
                }
            }
            .padding(24)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(tituloDoDia(chave))
        .onDisappear { tocador.parar() }
    }

    private var feito: some View {
        Cartao(titulo: "Devocional") {
            if let f = dia.feitoEm {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(verde)
                    Text("Feito às")
                    DatePicker("", selection: Binding(get: { f }, set: { lembrete.marcarFeito(chave, em: $0) }), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .fixedSize()
                    Spacer()
                    Button("Desmarcar") { lembrete.marcarFeito(chave, em: nil) }
                }
            } else {
                HStack {
                    Text("Ainda não marcado.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Marcar como feito") { lembrete.marcarFeito(chave, em: horarioPadrao()) }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var texto: some View {
        Cartao(titulo: "O que eu escrevi") {
            TextEditor(text: Binding(get: { dia.texto }, set: { t in loja.mudar(chave) { $0.texto = t } }))
                .font(.body)
                .frame(minHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var notas: some View {
        Cartao(titulo: "Notas") {
            ForEach(dia.notas) { nota in
                HStack(alignment: .top) {
                    TextField("Nota", text: textoDaNota(nota.id), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        loja.mudar(chave) { $0.notas.removeAll { $0.id == nota.id } }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Apagar nota")
                }
            }

            if ditado.gravando || ditado.preparando {
                HStack(alignment: .top) {
                    Image(systemName: "waveform")
                        .symbolEffect(.variableColor.iterative, isActive: ditado.gravando)
                        .foregroundStyle(.red)
                    Text(ditado.preparando ? "Preparando o microfone…" : (ditado.texto.isEmpty ? "Pode falar…" : ditado.texto))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            if let r = rascunho {
                VStack(alignment: .leading) {
                    TextField("Texto ditado", text: Binding(get: { r }, set: { rascunho = $0 }), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Button("Salvar nota") {
                            let t = r.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !t.isEmpty { loja.mudar(chave) { $0.notas.append(Nota(texto: t)) } }
                            rascunho = nil
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Descartar") { rascunho = nil }
                    }
                }
            }

            if let e = ditado.erro {
                Text(e).foregroundStyle(.red).font(.callout)
            }

            HStack {
                Button {
                    loja.mudar(chave) { $0.notas.append(Nota(texto: "")) }
                } label: {
                    Label("Nova nota", systemImage: "plus")
                }
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
                    Label(ditado.gravando ? "Parar ditado" : "Ditar nota", systemImage: ditado.gravando ? "stop.circle.fill" : "mic")
                }
                .disabled(ditado.preparando)
            }
        }
    }

    private var oracoes: some View {
        Cartao(titulo: "Orações") {
            ForEach(dia.oracoes) { o in
                HStack {
                    Button {
                        tocador.alternar(o, loja.urlDaOracao(o))
                    } label: {
                        Image(systemName: tocador.tocando == o.id ? "stop.fill" : "play.fill")
                            .frame(width: 18)
                    }
                    Text(o.gravadaEm.formatted(date: .omitted, time: .shortened))
                    Text(duracaoTexto(o.duracao))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Spacer()
                    if transcrevendo.contains(o.id) {
                        ProgressView().controlSize(.small)
                        Text("Transcrevendo…").foregroundStyle(.secondary)
                    } else {
                        Button("Transcrever") { transcrever(o) }
                    }
                    Button {
                        if tocador.tocando == o.id { tocador.parar() }
                        try? FileManager.default.removeItem(at: loja.urlDaOracao(o))
                        loja.mudar(chave) { $0.oracoes.removeAll { $0.id == o.id } }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Apagar oração")
                }
            }

            if let e = gravador.erro {
                Text(e).foregroundStyle(.red).font(.callout)
            }

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
                Label(gravador.gravando ? "Parar gravação" : "Gravar oração", systemImage: gravador.gravando ? "stop.circle.fill" : "record.circle")
            }
            .tint(gravador.gravando ? .red : verde)
        }
    }

    private func textoDaNota(_ id: UUID) -> Binding<String> {
        Binding(
            get: { dia.notas.first { $0.id == id }?.texto ?? "" },
            set: { t in loja.mudar(chave) { d in
                if let i = d.notas.firstIndex(where: { $0.id == id }) { d.notas[i].texto = t }
            } }
        )
    }

    private func horarioPadrao() -> Date {
        if chave == lembrete.estado.dia { return Date() }
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
