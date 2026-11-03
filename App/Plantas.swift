import SwiftUI

private let calendario: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.locale = ptBR
    return c
}()

func nomeDoMes(_ mes: Int) -> String {
    let s = calendario.standaloneMonthSymbols[(mes - 1 + 12) % 12]
    return s.prefix(1).uppercased() + s.dropFirst()
}

struct Plantas: View {
    @EnvironmentObject var loja: Loja
    @EnvironmentObject var lembrete: Lembrete
    @State private var largura: CGFloat = 0
    @State private var ano = 0
    @State private var mes = 0
    @State private var crescer = Date()
    @State private var sacudida: Date?
    @State private var barra = false
    @State private var colheita: (Arvore, Int, Int)?

    private enum Situacao { case colhida, crescendo, bloqueada }

    private var hoje: Date { dataDaChave(lembrete.estado.dia) ?? Date() }
    private var anoAtual: Int { calendario.component(.year, from: hoje) }
    private var mesAtual: Int { calendario.component(.month, from: hoje) }
    private var anoVisto: Int { ano == 0 ? anoAtual : ano }
    private var mesVisto: Int { mes == 0 ? mesAtual : mes }
    private var primeiroAno: Int { min(anoAtual, loja.feitos.compactMap { Int($0.prefix(4)) }.min() ?? anoAtual) }

    private func contagem() -> [String: Int] {
        Dictionary(grouping: loja.feitos, by: { String($0.prefix(7)) }).mapValues(\.count)
    }

    private func chave(_ a: Int, _ m: Int) -> String {
        String(format: "%04d-%02d", a, m)
    }

    private func situacao(_ a: Int, _ m: Int) -> Situacao {
        if a < anoAtual || (a == anoAtual && m < mesAtual) { return .colhida }
        if a == anoAtual && m == mesAtual { return .crescendo }
        return .bloqueada
    }

    private func diasNoMes(_ a: Int, _ m: Int) -> Int {
        guard let d = calendario.date(from: DateComponents(year: a, month: m, day: 1)) else { return 30 }
        return calendario.range(of: .day, in: .month, for: d)?.count ?? 30
    }

    private func estagio(_ a: Int, _ m: Int, _ n: Int) -> Double {
        if situacao(a, m) == .bloqueada { return 30 }
        return min(30, Double(n) / Double(diasNoMes(a, m)) * 30)
    }

    var body: some View {
        let c = contagem()
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                destaque(c).entrada(0)
                meses(c).entrada(1)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: 1500)
            .frame(maxWidth: .infinity)
            .modifier(Largura(largura: $largura))
        }
        .navigationTitle("Plantas")
        .onAppear(perform: conferirColheita)
    }

    private func conferirColheita() {
        let a = mesAtual == 1 ? anoAtual - 1 : anoAtual
        let m = mesAtual == 1 ? 12 : mesAtual - 1
        let k = chave(a, m)
        guard UserDefaults.standard.string(forKey: "colheitaVista") != k else { return }
        UserDefaults.standard.set(k, forKey: "colheitaVista")
        let n = contagem()[k] ?? 0
        if n > 0 { colheita = (Arvore.doMes(m), m, n) }
    }

    private func selecionar(_ m: Int) {
        guard m != mesVisto else { return }
        withAnimation(.smooth(duration: 0.35)) { mes = m }
        crescer = Date()
        barra = false
        withAnimation(.smooth(duration: 0.9).delay(0.2)) { barra = true }
    }

    private func mudarAno(_ delta: Int) {
        withAnimation(.smooth(duration: 0.35)) { ano = anoVisto + delta }
        crescer = Date()
    }

    private func destaque(_ c: [String: Int]) -> some View {
        let a = anoVisto, m = mesVisto
        let arvore = Arvore.doMes(m)
        let s = situacao(a, m)
        let n = c[chave(a, m)] ?? 0
        let bloqueada = s == .bloqueada
        let tom = bloqueada ? Color.gray : arvore.copa
        let planta = DesenhoDaPlanta(arvore: arvore, estagio: estagio(a, m, n), crescerDesde: crescer, sacudidaDesde: sacudida)
            .grayscale(bloqueada ? 1 : 0)
            .opacity(bloqueada ? 0.6 : 1)
            .frame(height: 440)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onHover { dentro in
                guard dentro, !bloqueada else { return }
                if let sacudida, Date().timeIntervalSince(sacudida) < 0.9 { return }
                sacudida = Date()
            }
        return Group {
            if largura > 900 {
                HStack(alignment: .center, spacing: 32) {
                    planta
                    informacoes(arvore, s, n, a, m)
                        .frame(width: min(420, largura * 0.38))
                }
            } else {
                VStack(spacing: 20) {
                    planta
                    informacoes(arvore, s, n, a, m)
                }
            }
        }
        .padding(28)
        .background(
            LinearGradient(colors: [tom.opacity(0.2), tom.opacity(0.03)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(tom.opacity(0.22)))
        .animation(.smooth(duration: 0.35), value: m)
    }

    private func informacoes(_ arvore: Arvore, _ s: Situacao, _ n: Int, _ a: Int, _ m: Int) -> some View {
        let dias = diasNoMes(a, m)
        let mesTexto = nomeDoMes(m).lowercased()
        return VStack(alignment: .leading, spacing: 18) {
            if s == .crescendo, let c = colheita {
                Label("Você colheu \(artigo(c.0)) \(c.0.nome) de \(nomeDoMes(c.1).lowercased()) com \(c.2 == 1 ? "1 devocional" : "\(c.2) devocionais").", systemImage: "sparkles")
                    .font(.callout.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.opacity)
            }
            VStack(alignment: .leading, spacing: 6) {
                Group {
                    switch s {
                    case .crescendo: Text("Crescendo em \(mesTexto)")
                    case .colhida: Text("Colhida em \(mesTexto) de \(String(a))")
                    case .bloqueada: Label("Planta de \(mesTexto)", systemImage: "lock.fill")
                    }
                }
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                Text(arvore.nome)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                Text(arvore.descricao)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if s == .bloqueada {
                Text("Desbloqueia em 1º de \(mesTexto)\(a == anoAtual ? "" : " de \(String(a))"). Os devocionais desse mês fazem ela crescer.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(n == 1 ? "1 devocional" : "\(n) devocionais")
                            .font(.headline)
                            .contentTransition(.numericText(value: Double(n)))
                        Spacer()
                        Text("de \(dias) dias")
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(min(n, dias)) * (barra ? 1 : 0), total: Double(dias))
                        .tint(arvore.copa.mix(with: .black, by: 0.1))
                        .onAppear {
                            withAnimation(.smooth(duration: 0.9).delay(0.3)) { barra = true }
                        }
                    Text(rodape(arvore, s, n))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .id("\(a)-\(m)")
        .transition(.opacity.combined(with: .offset(y: 6)))
    }

    private func rodape(_ arvore: Arvore, _ s: Situacao, _ n: Int) -> String {
        if s == .colhida {
            return n == 0 ? "Nenhum devocional neste mês. A semente ficou guardada no vaso." : "Ela foi colhida do tamanho que chegou no fim do mês."
        }
        let proximo = nomeDoMes(mesAtual % 12 + 1).lowercased()
        return "Cada devocional deste mês faz \(artigo(arvore)) \(arvore.nome) crescer. No dia 1º de \(proximo), a planta é colhida do tamanho que estiver."
    }

    private func artigo(_ arvore: Arvore) -> String {
        ["Palmeira", "Oliveira", "Cerejeira", "Figueira", "Araucária"].contains(arvore.nome) ? "a" : "o"
    }

    private func meses(_ c: [String: Int]) -> some View {
        let colunas = Array(repeating: GridItem(.flexible(), spacing: 12), count: largura > 1200 ? 6 : (largura > 760 ? 4 : 3))
        let colhidas = (1...12).filter { situacao(anoVisto, $0) == .colhida && (c[chave(anoVisto, $0)] ?? 0) > 0 }.count
        return Cartao(titulo: "\(String(anoVisto)) · \(colhidas == 1 ? "1 planta colhida" : "\(colhidas) plantas colhidas")") {
            LazyVGrid(columns: colunas, spacing: 12) {
                ForEach(1...12, id: \.self) { m in
                    item(m, c[chave(anoVisto, m)] ?? 0)
                }
            }
            .id(anoVisto)
            .transition(.opacity)
        } acoes: {
            if primeiroAno < anoAtual {
                HStack(spacing: 4) {
                    Button { mudarAno(-1) } label: { Image(systemName: "chevron.left") }
                        .disabled(anoVisto <= primeiroAno)
                    Button { mudarAno(1) } label: { Image(systemName: "chevron.right") }
                        .disabled(anoVisto >= anoAtual)
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private func item(_ m: Int, _ n: Int) -> some View {
        let arvore = Arvore.doMes(m)
        let s = situacao(anoVisto, m)
        let escolhido = m == mesVisto
        return Button { selecionar(m) } label: {
            VStack(spacing: 4) {
                DesenhoDaPlanta(arvore: arvore, estagio: estagio(anoVisto, m, n), animado: false)
                    .grayscale(s == .bloqueada ? 1 : 0)
                    .opacity(s == .bloqueada ? 0.45 : 1)
                    .frame(height: 118)
                    .frame(maxWidth: .infinity)
                Text(nomeDoMes(m))
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(arvore.nome)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(s == .bloqueada ? .secondary : .primary)
                    .lineLimit(1)
                Group {
                    switch s {
                    case .colhida: Text(n == 1 ? "1 devocional" : "\(n) devocionais")
                    case .crescendo: Text("Crescendo · \(n)").foregroundStyle(verde)
                    case .bloqueada: Label("Bloqueada", systemImage: "lock.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
            .background(escolhido ? AnyShapeStyle((s == .bloqueada ? Color.gray : arvore.copa).opacity(0.13)) : AnyShapeStyle(.clear), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(escolhido ? (s == .bloqueada ? Color.gray : arvore.copa).opacity(0.55) : .clear, lineWidth: 1.5))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(Realce(raio: 14))
        .animation(.snappy(duration: 0.2), value: escolhido)
    }
}
