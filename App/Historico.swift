import SwiftUI

struct Historico: View {
    @EnvironmentObject var loja: Loja
    @EnvironmentObject var lembrete: Lembrete
    @State private var mes = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
    @State private var caminho: [String] = []
    @State private var largura: CGFloat = 0
    @State private var ano = Calendar.current.component(.year, from: Date())
    private let cal = Calendar.current

    var body: some View {
        NavigationStack(path: $caminho) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    numeros
                    if largura > 980 {
                        HStack(alignment: .top, spacing: 20) {
                            calendario
                                .frame(maxWidth: .infinity)
                                .frame(maxHeight: .infinity)
                            VStack(spacing: 20) {
                                recentes
                                faixas
                            }
                            .frame(width: min(420, largura * 0.36))
                            .frame(maxHeight: .infinity)
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .fixedSize(horizontal: false, vertical: true)
                    } else {
                        calendario
                        recentes
                        faixas
                    }
                    painelDoAno
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .frame(maxWidth: 1500)
                .frame(maxWidth: .infinity)
                .modifier(Largura(largura: $largura))
            }
            .navigationTitle("Histórico")
            .navigationDestination(for: String.self) { PaginaDoDia(chave: $0) }
        }
    }

    private var numeros: some View {
        let eventos = eventosDoMes
        let naos: Set<String> = ["nao", "dispensada", "sumiu", "clicou"]
        let colunas = Array(repeating: GridItem(.flexible(), spacing: 14), count: largura > 760 ? 5 : 3)
        return LazyVGrid(columns: colunas, spacing: 14) {
            Numero(valor: loja.sequenciaAtual(hoje: lembrete.estado.dia), nome: "Dias seguidos", icone: "flame.fill", cor: .orange)
            Numero(valor: loja.maiorSequencia, nome: "Maior sequência", icone: "trophy.fill", cor: .yellow)
            Numero(valor: diasDoMes.filter { loja.dias[chaveDoDia($0)]?.feitoEm != nil }.count, nome: "Feitos no mês", icone: "checkmark.circle.fill", cor: verde)
            Numero(valor: eventos.filter { $0.tipo == "adiar" }.count, nome: "Adiamentos no mês", icone: "clock.arrow.circlepath", cor: .blue)
            Numero(valor: eventos.filter { naos.contains($0.tipo) }.count, nome: "\"Não\" no mês", icone: "xmark.circle.fill", cor: .secondary)
        }
    }

    private var calendario: some View {
        Cartao(titulo: tituloDoMes, icone: "calendar", preencher: largura > 980) {
            let colunas = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
            LazyVGrid(columns: colunas, spacing: 8) {
                ForEach(Array(["dom", "seg", "ter", "qua", "qui", "sex", "sáb"].enumerated()), id: \.offset) { _, d in
                    Text(d.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                ForEach(0..<vazios, id: \.self) { _ in Color.clear.frame(height: 48) }
                ForEach(diasDoMes, id: \.self) { data in
                    celula(data)
                }
            }
            HStack(spacing: 16) {
                legenda(verdeFundo, "Feito")
                legenda(.clear, "Hoje", borda: true)
                Spacer()
                Text("Clique num dia para abrir a página dele.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } acoes: {
            HStack(spacing: 4) {
                Button { mudarMes(-1) } label: { Image(systemName: "chevron.left") }
                    .help("Mês anterior")
                Button("Hoje") { mes = cal.dateInterval(of: .month, for: Date())?.start ?? Date() }
                Button { mudarMes(1) } label: { Image(systemName: "chevron.right") }
                    .help("Próximo mês")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private func celula(_ data: Date) -> some View {
        let chave = chaveDoDia(data)
        let feito = loja.dias[chave]?.feitoEm != nil
        let hoje = chave == lembrete.estado.dia
        let futuro = chave > lembrete.estado.dia
        let temAlgo = loja.dias[chave]?.temConteudo ?? false
        return Button {
            caminho.append(chave)
        } label: {
            VStack(spacing: 3) {
                Text("\(cal.component(.day, from: data))")
                    .font(.body.weight(hoje ? .bold : .regular))
                Circle()
                    .fill(temAlgo ? (feito ? Color.white : verde) : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(feito ? Color.white : (futuro ? Color.secondary.opacity(0.5) : Color.primary))
            .background(feito ? verdeFundo : Color.secondary.opacity(futuro ? 0.03 : 0.08), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(verde, lineWidth: hoje ? 2 : 0))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(futuro)
        .help(feito ? "Feito" : (futuro ? "" : "Abrir página"))
    }

    private func legenda(_ cor: Color, _ nome: String, borda: Bool = false) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(cor)
                .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(verde, lineWidth: borda ? 1.5 : 0))
                .frame(width: 12, height: 12)
            Text(nome).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var faixas: some View {
        let ordenadas = loja.config.faixas.sorted {
            $0.inicio < $1.inicio
        }

        var contagem: [String: Int] = [:]

        for d in loja.dias.values {
            guard let f = d.feitoEm else { continue }

            let minuto = minutoDoDia(f)

            let faixa = ordenadas.last {
                $0.inicio <= minuto
            } ?? ordenadas.last

            if let faixa {
                contagem[faixa.nome, default: 0] += 1
            }
        }

        let ordem = ordenadas.map(\.nome)

        let lista = ordem.compactMap { nome in
            contagem[nome].map {
                (nome: nome, n: $0)
            }
        }

        return Cartao(
            titulo: "Quando você faz o devocional",
            icone: "chart.bar.fill",
            preencher: largura > 980
        ) {
            if lista.isEmpty {
                Vazio(
                    texto: "Assim que você marcar alguns dias, aparece aqui em que faixas do dia você mais faz o devocional."
                )
            } else {
                let maior = lista.map(\.n).max() ?? 1
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(lista, id: \.nome) { item in
                        HStack(spacing: 10) {
                            Text(item.nome)
                                .frame(width: 130, alignment: .trailing)
                                .lineLimit(1)
                            GeometryReader { proxy in
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(verdeFundo)
                                    .frame(width: proxy.size.width * CGFloat(item.n) / CGFloat(maior))
                            }
                            .frame(height: 22)
                            Text("\(item.n)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: CGFloat(lista.count) * 32 + 10)
            }
        }
    }

    private var recentes: some View {
        let dias = loja.dias.values.filter { $0.feitoEm != nil }.sorted { $0.id > $1.id }.prefix(5)
        return Cartao(titulo: "Últimos devocionais", icone: "clock", preencher: largura > 980) {
            if dias.isEmpty {
                Vazio(texto: "Os devocionais que você registrar aparecem aqui.")
            }
            ForEach(Array(dias)) { d in
                Button {
                    caminho.append(d.id)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(verde)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tituloDoDia(d.id))
                                .font(.callout.weight(.semibold))
                            Text(resumo(d))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .background(.background, in: RoundedRectangle(cornerRadius: 10))
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func resumo(_ d: Dia) -> String {
        if !d.leitura.isEmpty && !d.texto.isEmpty { return d.leitura + " — " + d.texto }
        if !d.leitura.isEmpty { return d.leitura }
        if !d.texto.isEmpty { return d.texto }
        if let n = d.notas.first?.texto, !n.isEmpty { return n }
        if !d.oracoes.isEmpty { return "Oração gravada" }
        return "Registrado às " + (d.feitoEm.map(horaTexto) ?? "")
    }

    private var painelDoAno: some View {
        let feitos = loja.feitos
        let doAno = feitos.filter { $0.hasPrefix(String(ano)) }.count
        return Cartao(titulo: "\(String(ano)) · \(doAno) \(doAno == 1 ? "devocional" : "devocionais")", icone: "square.grid.3x3.fill") {
            GradeDoAno(ano: ano, feitos: feitos, hoje: lembrete.estado.dia) { caminho.append($0) }
                .id(ano)
        } acoes: {
            HStack(spacing: 4) {
                Button { ano -= 1 } label: { Image(systemName: "chevron.left") }
                    .help("Ano anterior")
                Button { ano += 1 } label: { Image(systemName: "chevron.right") }
                    .help("Próximo ano")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var tituloDoMes: String {
        let t = mes.formatted(.dateTime.month(.wide).year().locale(ptBR))
        return t.prefix(1).uppercased() + t.dropFirst()
    }

    private var diasDoMes: [Date] {
        guard let r = cal.range(of: .day, in: .month, for: mes) else { return [] }
        return r.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: mes) }
    }

    private var vazios: Int {
        cal.component(.weekday, from: mes) - 1
    }

    private var eventosDoMes: [Evento] {
        let prefixo = String(chaveDoDia(mes).prefix(7))
        return loja.eventos.filter { $0.dia.hasPrefix(prefixo) }
    }

    private func mudarMes(_ n: Int) {
        mes = cal.date(byAdding: .month, value: n, to: mes) ?? mes
    }
}

struct Numero: View {
    let valor: Int
    let nome: String
    let icone: String
    let cor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icone)
                .font(.title3)
                .foregroundStyle(cor)
            Text("\(valor)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            Text(nome)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.separator.opacity(0.6)))
    }
}
