import SwiftUI

struct GradeDoAno: View {
    let ano: Int
    let feitos: Set<String>
    let hoje: String
    let abrir: (String) -> Void

    @State private var sobre: String?

    private let rotulo: CGFloat = 30
    private let topo: CGFloat = 18
    private let espaco: CGFloat = 3
    private let celulas: [(chave: String, coluna: Int, linha: Int)]
    private let colunas: Int
    private let meses: [(nome: String, coluna: Int)]

    init(ano: Int, feitos: Set<String>, hoje: String, abrir: @escaping (String) -> Void) {
        self.ano = ano
        self.feitos = feitos
        self.hoje = hoje
        self.abrir = abrir
        let cal = Calendar.current
        var lista: [(String, Int, Int)] = []
        var meses: [(String, Int)] = []
        let nomes = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
        if let inicio = cal.date(from: DateComponents(year: ano, month: 1, day: 1)) {
            let deslocamento = cal.component(.weekday, from: inicio) - 1
            var d = inicio
            var i = 0
            while cal.component(.year, from: d) == ano {
                let pos = i + deslocamento
                let c = cal.dateComponents([.month, .day], from: d)
                if c.day == 1, let m = c.month { meses.append((nomes[m - 1], pos / 7)) }
                lista.append((chaveDoDia(d), pos / 7, pos % 7))
                i += 1
                d = cal.date(byAdding: .day, value: 1, to: d) ?? d.addingTimeInterval(86400)
            }
        }
        celulas = lista
        colunas = (lista.last?.1 ?? 52) + 1
        self.meses = meses
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { g in
                let lado = tamanho(g.size)
                Canvas { ctx, _ in
                    for m in meses {
                        ctx.draw(Text(m.nome).font(.caption2).foregroundStyle(.secondary), at: CGPoint(x: x(m.coluna, lado), y: 0), anchor: .topLeading)
                    }
                    for (i, nome) in ["seg", "qua", "sex"].enumerated() {
                        ctx.draw(Text(nome).font(.system(size: 9)).foregroundStyle(.secondary), at: CGPoint(x: 0, y: y(1 + i * 2, lado) + lado / 2), anchor: .leading)
                    }
                    for c in celulas {
                        let r = CGRect(x: x(c.coluna, lado), y: y(c.linha, lado), width: lado, height: lado)
                        let forma = Path(roundedRect: r, cornerRadius: min(3, lado / 4))
                        let cor: Color = feitos.contains(c.chave) ? verdeFundo : Color.secondary.opacity(c.chave > hoje ? 0.05 : 0.14)
                        ctx.fill(forma, with: .color(cor))
                        if c.chave == hoje {
                            ctx.stroke(forma, with: .color(verde), lineWidth: 1.5)
                        } else if c.chave == sobre {
                            ctx.stroke(forma, with: .color(.primary.opacity(0.5)), lineWidth: 1)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onContinuousHover { fase in
                    switch fase {
                    case .active(let p): sobre = chave(em: p, lado: lado)
                    case .ended: sobre = nil
                    }
                }
                .onTapGesture { p in
                    if let k = chave(em: p, lado: lado), k <= hoje { abrir(k) }
                }
            }
            .aspectRatio((rotulo + CGFloat(colunas) * 17) / (topo + 7 * 17), contentMode: .fit)

            HStack {
                if let sobre, let data = dataDaChave(sobre) {
                    Text(data.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(ptBR)))
                    Text(feitos.contains(sobre) ? "· devocional registrado" : (sobre > hoje ? "" : "· sem registro"))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Passe o mouse num dia para ver a data. Clique para abrir a página dele.")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
        }
    }

    private func tamanho(_ s: CGSize) -> CGFloat {
        let n = CGFloat(colunas)
        let pelaLargura = (s.width - rotulo - espaco * (n - 1)) / n
        let pelaAltura = (s.height - topo - espaco * 6) / 7
        return max(4, min(pelaLargura, pelaAltura))
    }

    private func x(_ coluna: Int, _ lado: CGFloat) -> CGFloat {
        rotulo + CGFloat(coluna) * (lado + espaco)
    }

    private func y(_ linha: Int, _ lado: CGFloat) -> CGFloat {
        topo + CGFloat(linha) * (lado + espaco)
    }

    private func chave(em p: CGPoint, lado: CGFloat) -> String? {
        let coluna = Int((p.x - rotulo) / (lado + espaco))
        let linha = Int((p.y - topo) / (lado + espaco))
        guard p.x >= rotulo, p.y >= topo, linha < 7 else { return nil }
        return celulas.first { $0.coluna == coluna && $0.linha == linha }?.chave
    }
}
