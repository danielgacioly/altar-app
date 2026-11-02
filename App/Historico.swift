import SwiftUI

struct Historico: View {
    @EnvironmentObject var loja: Loja
    @EnvironmentObject var lembrete: Lembrete
    @State private var mes = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
    @State private var caminho: [String] = []

    private let cal = Calendar.current

    var body: some View {
        NavigationStack(path: $caminho) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    calendario
                    HStack(alignment: .top, spacing: 16) {
                        sequencias
                        doMes
                    }
                    faixas
                }
                .padding(24)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Histórico")
            .navigationDestination(for: String.self) { PaginaDoDia(chave: $0) }
        }
    }

    private var calendario: some View {
        Cartao(titulo: mes.formatted(.dateTime.month(.wide).year().locale(ptBR)).capitalized) {
            HStack {
                Button { mudarMes(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Button("Este mês") { mes = cal.dateInterval(of: .month, for: Date())?.start ?? Date() }
                Spacer()
                Button { mudarMes(1) } label: { Image(systemName: "chevron.right") }
            }
            .buttonStyle(.borderless)

            let colunas = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: colunas, spacing: 6) {
                ForEach(Array(["D", "S", "T", "Q", "Q", "S", "S"].enumerated()), id: \.offset) { _, d in
                    Text(d).font(.caption.bold()).foregroundStyle(.secondary)
                }
                ForEach(0..<vazios, id: \.self) { _ in Color.clear.frame(height: 36) }
                ForEach(diasDoMes, id: \.self) { data in
                    celula(data)
                }
            }
        }
    }

    private func celula(_ data: Date) -> some View {
        let chave = chaveDoDia(data)
        let feito = loja.dias[chave]?.feitoEm != nil
        let hoje = chave == lembrete.estado.dia
        let futuro = chave > lembrete.estado.dia
        return Button {
            caminho.append(chave)
        } label: {
            Text("\(cal.component(.day, from: data))")
                .frame(maxWidth: .infinity, minHeight: 36)
                .foregroundStyle(feito ? .white : (futuro ? .secondary : .primary))
                .background(feito ? verde : Color.clear, in: Circle())
                .overlay(Circle().stroke(verde, lineWidth: hoje && !feito ? 2 : 0))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(futuro)
    }

    private var sequencias: some View {
        Cartao(titulo: "Sequência") {
            linha("Dias seguidos agora", "\(sequenciaAtual)")
            linha("Maior sequência", "\(maiorSequencia)")
            linha("Total de dias feitos", "\(loja.dias.values.filter { $0.feitoEm != nil }.count)")
        }
    }

    private var doMes: some View {
        let eventos = eventosDoMes
        let naos: Set<String> = ["nao", "dispensada", "sumiu", "clicou"]
        return Cartao(titulo: "Neste mês") {
            linha("Dias feitos", "\(diasDoMes.filter { loja.dias[chaveDoDia($0)]?.feitoEm != nil }.count)")
            linha("Lembretes", "\(eventos.filter { $0.tipo == "exibida" }.count)")
            linha("Adiamentos", "\(eventos.filter { $0.tipo == "adiar" }.count)")
            linha("Respostas \"Não\"", "\(eventos.filter { naos.contains($0.tipo) }.count)")
            linha("Botões extras", "\(eventos.filter { $0.tipo.hasPrefix("extra:") }.count)")
        }
    }

    private var faixas: some View {
        var contagem: [String: Int] = [:]
        for d in loja.dias.values {
            if let f = d.feitoEm, let faixa = loja.config.faixa(em: f) {
                contagem[faixa.nome, default: 0] += 1
            }
        }
        let lista = contagem.sorted { $0.value > $1.value }
        let maior = max(lista.first?.value ?? 1, 1)
        return Cartao(titulo: "Quando você mais faz o devocional") {
            if lista.isEmpty {
                Text("Ainda sem dados.").foregroundStyle(.secondary)
            }
            ForEach(lista, id: \.key) { nome, n in
                HStack {
                    Text(nome).frame(width: 150, alignment: .leading)
                    GeometryReader { g in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(verde)
                            .frame(width: max(4, g.size.width * Double(n) / Double(maior)))
                    }
                    .frame(height: 14)
                    Text("\(n)").monospacedDigit().frame(width: 30, alignment: .trailing)
                }
            }
        }
    }

    private func linha(_ nome: String, _ valor: String) -> some View {
        HStack {
            Text(nome)
            Spacer()
            Text(valor).bold().monospacedDigit()
        }
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

    private var feitos: Set<String> {
        Set(loja.dias.values.filter { $0.feitoEm != nil }.map(\.id))
    }

    private var sequenciaAtual: Int {
        let f = feitos
        guard var data = dataDaChave(lembrete.estado.dia) else { return 0 }
        if !f.contains(chaveDoDia(data)) {
            data = cal.date(byAdding: .day, value: -1, to: data) ?? data
        }
        var n = 0
        while f.contains(chaveDoDia(data)) {
            n += 1
            data = cal.date(byAdding: .day, value: -1, to: data) ?? data
        }
        return n
    }

    private var maiorSequencia: Int {
        let datas = feitos.compactMap(dataDaChave).sorted()
        var maior = 0
        var atual = 0
        var anterior: Date?
        for d in datas {
            if let a = anterior, cal.dateComponents([.day], from: a, to: d).day == 1 {
                atual += 1
            } else {
                atual = 1
            }
            maior = max(maior, atual)
            anterior = d
        }
        return maior
    }

    private func mudarMes(_ n: Int) {
        mes = cal.date(byAdding: .month, value: n, to: mes) ?? mes
    }
}
