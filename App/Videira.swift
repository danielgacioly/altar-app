import SwiftUI

struct Videira: View {
    @EnvironmentObject var loja: Loja
    @State private var largura: CGFloat = 0
    @State private var aberto = Date()
    @State private var caida: Date?

    private let tipos = TipoDeVideira.todas
    private var total: Int { loja.feitos.count }
    private var indice: Int { (total / 30) % tipos.count }
    private var estagio: Int { total % 30 }
    private var colhidas: Int { min(tipos.count, total / 30) }
    private var atual: TipoDeVideira { tipos[indice] }
    private var proxima: TipoDeVideira { tipos[(indice + 1) % tipos.count] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                destaque
                colecao
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: 1500)
            .frame(maxWidth: .infinity)
            .modifier(Largura(largura: $largura))
        }
        .navigationTitle("Videira")
        .onAppear { aberto = Date() }
    }

    private var destaque: some View {
        let planta = DesenhoDaPlanta(tipo: atual, estagio: Double(estagio), crescerDesde: aberto, caidaDesde: caida)
            .frame(height: 440)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onHover { dentro in
                guard dentro, estagio >= 20 else { return }
                if let caida, Date().timeIntervalSince(caida) < DesenhoDaPlanta.duracaoDaQueda { return }
                caida = Date()
            }
            .overlay(alignment: .bottom) {
                if estagio >= 20 {
                    Label("Passe o mouse na árvore para sacudir", systemImage: "hand.point.up.left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        return Group {
            if largura > 900 {
                HStack(alignment: .center, spacing: 32) {
                    planta
                    informacoes
                        .frame(width: min(420, largura * 0.38))
                }
            } else {
                VStack(spacing: 20) {
                    planta
                    informacoes
                }
            }
        }
        .padding(28)
        .background(
            LinearGradient(colors: [atual.folha.opacity(0.22), atual.folha.opacity(0.04)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(atual.folha.opacity(0.3)))
    }

    private var informacoes: some View {
        VStack(alignment: .leading, spacing: 18) {
            if estagio == 0 && total > 0 {
                let colhida = tipos[(indice + tipos.count - 1) % tipos.count]
                Label("Você colheu a \(colhida.nome)! Ela foi para a sua coleção.", systemImage: "sparkles")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.yellow.opacity(0.18), in: Capsule())
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Crescendo agora")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(atual.nome)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                Text(atual.descricao)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Estágio \(estagio) de 30")
                        .font(.headline)
                    Spacer()
                    Text(estagio == 0 ? "Semente" : (estagio < 10 ? "Broto" : (estagio < 20 ? "Arbusto" : "Árvore")))
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: Double(estagio), total: 30)
                    .tint(atual.folha)
                Text(30 - estagio == 1 ? "Falta 1 devocional para colher." : "Faltam \(30 - estagio) devocionais para colher.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 14) {
                DesenhoDaPlanta(tipo: proxima, estagio: 30, animado: false)
                    .frame(width: 70, height: 70)
                    .grayscale(1)
                    .opacity(0.45)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Próxima")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    Text(proxima.nome)
                        .font(.headline)
                    Text("Libera quando você colher a \(atual.nome).")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 14))
            Text("Cada devocional registrado faz a planta crescer um pouco. Com 30, ela vai para a coleção e uma nova semente começa.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var colecao: some View {
        let colunas = Array(repeating: GridItem(.flexible(), spacing: 14), count: largura > 1200 ? 6 : (largura > 800 ? 4 : 3))
        return Cartao(titulo: "Coleção · \(colhidas) de \(tipos.count)", icone: "leaf.fill") {
            LazyVGrid(columns: colunas, spacing: 14) {
                ForEach(tipos) { tipo in
                    item(tipo)
                }
            }
        }
    }

    @ViewBuilder
    private func item(_ tipo: TipoDeVideira) -> some View {
        let colhida = tipo.id < colhidas
        let ehAtual = tipo.id == indice
        let ehProxima = tipo.id == (indice + 1) % tipos.count && !colhida
        VStack(spacing: 8) {
            ZStack {
                if colhida || ehAtual {
                    DesenhoDaPlanta(tipo: tipo, estagio: ehAtual && !colhida ? Double(estagio) : 30, animado: false)
                } else if ehProxima {
                    DesenhoDaPlanta(tipo: tipo, estagio: 30, animado: false)
                        .grayscale(1)
                        .opacity(0.3)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            Text(colhida || ehAtual || ehProxima ? tipo.nome : "Bloqueada")
                .font(.callout.weight(.semibold))
                .foregroundStyle(colhida || ehAtual ? .primary : .secondary)
                .lineLimit(1)
            Text(colhida ? "Colhida" : (ehAtual ? "\(estagio) de 30" : (ehProxima ? "Próxima" : "Mês \(tipo.id + 1)")))
                .font(.caption)
                .foregroundStyle(colhida ? AnyShapeStyle(verde) : AnyShapeStyle(.secondary))
        }
        .padding(12)
        .background(ehAtual ? AnyShapeStyle(tipo.folha.opacity(0.12)) : AnyShapeStyle(.background), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(ehAtual ? tipo.folha.opacity(0.6) : Color.clear, lineWidth: 1.5))
        .help(colhida || ehAtual || ehProxima ? tipo.descricao : "Continue fazendo o devocional para descobrir.")
    }
}
