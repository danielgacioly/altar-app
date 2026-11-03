import SwiftUI

enum Copa {
    case redonda, nuvens, oval, cone, camadas, coluna, candelabro, guardaChuva, palmeira

    var altura: CGFloat {
        switch self {
        case .redonda: 0.36
        case .nuvens: 0.34
        case .oval: 0.34
        case .cone: 0.36
        case .camadas: 0.46
        case .coluna: 0.3
        case .candelabro: 0.44
        case .guardaChuva: 0.4
        case .palmeira: 0.44
        }
    }

    var raio: CGFloat {
        switch self {
        case .oval: 0.16
        case .coluna: 0.12
        case .guardaChuva: 0.19
        default: 0.2
        }
    }
}

struct Arvore: Identifiable {
    let id: Int
    let nome: String
    let descricao: String
    let copa: Color
    let folha: Color
    let caule: Color
    let vaso: Color
    let forma: Copa
    let rosto: (Olho, Boca)

    static func cor(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    static func doMes(_ mes: Int) -> Arvore {
        doAno[(mes - 1 + 12) % 12]
    }

    static let doAno: [Arvore] = [
        Arvore(id: 1, nome: "Ipê-amarelo", descricao: "Floresce no fim da seca e pinta a rua inteira de amarelo.", copa: cor(0xF2C12E), folha: cor(0x5E9A3A), caule: cor(0x6B4E36), vaso: cor(0x3F7FBF), forma: .redonda, rosto: (.brilho, .sorriso)),
        Arvore(id: 2, nome: "Palmeira", descricao: "\"O justo florescerá como a palmeira.\" Salmos 92:12", copa: cor(0x4E9A4A), folha: cor(0x4E9A4A), caule: cor(0x9C7A55), vaso: cor(0xE8C468), forma: .palmeira, rosto: (.felizes, .aberta)),
        Arvore(id: 3, nome: "Oliveira", descricao: "Árvore da paz, firme e paciente. Vive centenas de anos.", copa: cor(0x8FA67E), folha: cor(0x7E9970), caule: cor(0x6D5D4B), vaso: cor(0xC9B79C), forma: .nuvens, rosto: (.sono, .sorriso)),
        Arvore(id: 4, nome: "Cerejeira", descricao: "Uma nuvem de flores cor-de-rosa que dura poucos dias.", copa: cor(0xF2A7C3), folha: cor(0x6DAE5B), caule: cor(0x5D4037), vaso: cor(0xF5F0E6), forma: .redonda, rosto: (.grandes, .o)),
        Arvore(id: 5, nome: "Cedro do Líbano", descricao: "\"Crescerá como o cedro no Líbano.\" Galhos largos em andares.", copa: cor(0x2E6B3F), folha: cor(0x3C7A4A), caule: cor(0x5D4632), vaso: cor(0x78909C), forma: .camadas, rosto: (.pontos, .deLado)),
        Arvore(id: 6, nome: "Flamboyant", descricao: "Copa larga e flores vermelhas como fogo.", copa: cor(0xE2552C), folha: cor(0x5E9A3A), caule: cor(0x6D4C2F), vaso: cor(0xE8E1D3), forma: .guardaChuva, rosto: (.piscadinha, .lingua)),
        Arvore(id: 7, nome: "Araucária", descricao: "A árvore do pinhão. Abre os galhos como um candelabro no frio.", copa: cor(0x2F5D3A), folha: cor(0x3F7A4A), caule: cor(0x6B4A35), vaso: cor(0x9C7AD1), forma: .candelabro, rosto: (.pontos, .gato)),
        Arvore(id: 8, nome: "Ipê-roxo", descricao: "As flores chegam antes das folhas, no meio do inverno.", copa: cor(0xB46FC9), folha: cor(0x5E9A3A), caule: cor(0x5B4433), vaso: cor(0x4DB6AC), forma: .nuvens, rosto: (.felizes, .gato)),
        Arvore(id: 9, nome: "Jacarandá", descricao: "Copa larga e flores azuladas no começo da primavera.", copa: cor(0x8E83E0), folha: cor(0x5E9A55), caule: cor(0x5F4B3A), vaso: cor(0xF2A65A), forma: .guardaChuva, rosto: (.brilho, .aberta)),
        Arvore(id: 10, nome: "Cipreste", descricao: "Alto e reto, sempre apontando para cima.", copa: cor(0x3C7A4A), folha: cor(0x468A55), caule: cor(0x5E4632), vaso: cor(0xD9774B), forma: .coluna, rosto: (.sono, .deLado)),
        Arvore(id: 11, nome: "Figueira", descricao: "Folhas grandes e uma sombra boa para sentar e ler.", copa: cor(0x4F9F45), folha: cor(0x4F9F45), caule: cor(0x80603F), vaso: cor(0x26A69A), forma: .oval, rosto: (.grandes, .sorriso)),
        Arvore(id: 12, nome: "Pinheiro", descricao: "A árvore do Natal. Verde até o último dia do ano.", copa: cor(0x2F7D4F), folha: cor(0x3B8A55), caule: cor(0x6A4A32), vaso: cor(0xB5654A), forma: .cone, rosto: (.piscadinha, .aberta))
    ]
}

enum Olho { case brilho, pontos, felizes, sono, grandes, piscadinha }
enum Boca { case sorriso, aberta, o, gato, lingua, deLado }

struct DesenhoDaPlanta: View {
    let arvore: Arvore
    let estagio: Double
    var animado = true
    var crescerDesde: Date?
    var sacudidaDesde: Date?

    static func duracao(_ estagio: Double) -> Double {
        0.5 + min(1, estagio / 30) * 2.3
    }

    var body: some View {
        if animado {
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { linha in
                Canvas { ctx, tamanho in
                    desenhar(&ctx, tamanho, linha.date)
                }
            }
        } else {
            Canvas { ctx, tamanho in
                desenhar(&ctx, tamanho, nil)
            }
        }
    }

    private func faixa(_ x: Double, _ a: Double, _ b: Double) -> Double {
        let k = min(1, max(0, (x - a) / (b - a)))
        return k * k * (3 - 2 * k)
    }

    private func desenhar(_ ctx: inout GraphicsContext, _ tamanho: CGSize, _ agora: Date?) {
        let t = agora?.timeIntervalSinceReferenceDate ?? 0
        var e = estagio
        if let crescerDesde, let agora {
            let k = min(1, max(0, agora.timeIntervalSince(crescerDesde) / Self.duracao(estagio)))
            e = estagio * (k < 0.5 ? 2 * k * k : 1 - pow(-2 * k + 2, 2) / 2)
        }
        let p = min(1, max(0, e / 30))
        let m = min(tamanho.width, tamanho.height)
        let cx = tamanho.width / 2
        let chao = tamanho.height * 0.74
        let forma = arvore.forma

        vaso(&ctx, cx: cx, chao: chao, m: m, t: t)

        let base = CGPoint(x: cx, y: chao - m * 0.03)
        let semente = 1 - faixa(p, 0, 0.05)
        let broto = faixa(p, 0.005, 0.06)
        guard broto > 0.01 else {
            desenharSemente(&ctx, base: base, m: m, t: t)
            return
        }

        let crescida = 1 - pow(1 - p, 2)
        let altura = m * 0.05 * broto + (m * forma.altura - m * 0.05) * crescida
        var vento = sin(t * 1.3) * (0.035 + 0.025 * p) + sin(t * 2.3 + 1) * 0.008
        if let sacudidaDesde, let agora {
            let q = agora.timeIntervalSince(sacudidaDesde)
            if q >= 0 && q < 0.9 { vento += sin(q * 30) * (1 - q / 0.9) * 0.06 }
        }
        let curva = forma == .palmeira ? m * 0.05 * p : 0
        let topo = CGPoint(x: cx + vento * altura + curva, y: base.y - altura)
        let meio = CGPoint(x: cx + vento * altura * 0.3 + curva * 1.4, y: base.y - altura * 0.5)
        func ponto(_ u: Double) -> CGPoint {
            let a = (1 - u) * (1 - u), b = 2 * (1 - u) * u, c = u * u
            return CGPoint(x: a * base.x + b * meio.x + c * topo.x, y: a * base.y + b * meio.y + c * topo.y)
        }

        let verdeNovo = arvore.folha.mix(with: .black, by: 0.15)
        let madeira = verdeNovo.mix(with: arvore.caule, by: faixa(p, 0.25, 0.6))
        let grossura = max(1.5, m * ((forma == .palmeira || forma == .coluna ? 0.008 : 0.01) + 0.026 * p)) * broto
        let k = min(1, max(0, (p - 0.28) / 0.72))
        let crescimento = 1 - pow(1 - k, 2)
        let raio = m * forma.raio * crescimento

        var galhos: [CGPoint] = []
        switch forma {
        case .nuvens:
            let pontas: [(Double, CGFloat, CGFloat)] = [(0.5, -1.05, 0.55), (0.6, 1.0, 0.3), (0.72, -0.75, -0.15), (0.8, 0.7, -0.35)]
            for (u, x, y) in pontas {
                let inicio = ponto(u)
                let fim = CGPoint(x: topo.x + x * raio * 1.1, y: topo.y + y * raio)
                galho(&ctx, de: inicio, para: fim, cor: madeira, largura: grossura * 0.6)
                galhos.append(fim)
            }
        case .guardaChuva:
            for x: CGFloat in [-0.95, 0.95] {
                let inicio = ponto(0.6)
                let fim = CGPoint(x: topo.x + x * raio, y: topo.y + raio * 0.15)
                galho(&ctx, de: inicio, para: fim, cor: madeira, largura: grossura * 0.65)
            }
        case .candelabro:
            let bracos: [(Double, CGFloat, CGFloat, CGFloat)] = [(0.6, -1, 1.25, 0.2), (0.6, 1, 1.25, 0.2), (0.73, -1, 0.95, -0.12), (0.73, 1, 0.95, -0.12), (0.86, -1, 0.6, -0.42), (0.86, 1, 0.6, -0.42)]
            for (u, lado, dx, dy) in bracos {
                let inicio = ponto(u)
                let fim = CGPoint(x: topo.x + lado * dx * raio, y: topo.y + dy * raio)
                var g = Path()
                g.move(to: inicio)
                g.addQuadCurve(to: fim, control: CGPoint(x: fim.x - lado * raio * 0.1, y: inicio.y))
                ctx.stroke(g, with: .color(madeira), style: StrokeStyle(lineWidth: grossura * 0.45, lineCap: .round))
                galhos.append(fim)
            }
        case .redonda, .oval:
            for (i, x) in [-0.7, 0.65].enumerated() {
                let inicio = ponto(0.55 + 0.1 * Double(i))
                let fim = CGPoint(x: topo.x + x * raio, y: topo.y + raio * 0.1)
                galho(&ctx, de: inicio, para: fim, cor: madeira, largura: grossura * 0.55)
            }
        case .camadas:
            for i in 0..<3 {
                let lado: CGFloat = i % 2 == 0 ? -1 : 1
                let y = topo.y + raio * (1.86 - 0.62 * CGFloat(i))
                let inicio = ponto(min(0.95, max(0.3, Double((base.y - y) / max(1, altura)))))
                galho(&ctx, de: inicio, para: CGPoint(x: topo.x + lado * raio * (1.3 - 0.25 * CGFloat(i)), y: y), cor: madeira, largura: grossura * 0.55)
            }
        default:
            break
        }

        tronco(&ctx, base: base, meio: meio, topo: topo, grossura: grossura, cor: madeira, afinar: forma == .palmeira ? 0.3 : 0.6)
        if forma == .palmeira && p > 0.3 {
            let aneis = Int(4 + 8 * p)
            for i in 1..<aneis {
                let u = Double(i) / Double(aneis)
                let c = ponto(u)
                var anel = Path()
                anel.move(to: CGPoint(x: c.x - grossura * 0.5, y: c.y))
                anel.addQuadCurve(to: CGPoint(x: c.x + grossura * 0.5, y: c.y), control: CGPoint(x: c.x, y: c.y + grossura * 0.35))
                ctx.stroke(anel, with: .color(arvore.caule.mix(with: .black, by: 0.3).opacity(faixa(p, 0.3, 0.5))), lineWidth: max(0.6, m * 0.003))
            }
        }

        terra(&ctx, cx: cx, chao: chao, m: m)
        if semente > 0.01 {
            var c = ctx
            c.opacity = semente
            desenharSemente(&c, base: base, m: m, t: t)
        }

        let some = 1 - faixa(p, 0.42, 0.62)
        if some > 0.01 {
            for i in 0..<6 {
                let inicio = 0.03 + 0.05 * Double(i)
                let tam = m * 0.05 * faixa(p, inicio, inicio + 0.07) * some
                guard tam > 0.5 else { continue }
                let u = 0.3 + 0.1 * Double(i)
                let lado: Double = i % 2 == 0 ? -1 : 1
                let balanco = sin(t * 1.8 + Double(i) * 0.9) * 0.15
                folha(&ctx, em: ponto(u), angulo: -.pi / 2 + lado * 0.95 + balanco, tamanho: tam, cor: i % 2 == 0 ? arvore.folha : arvore.folha.mix(with: .white, by: 0.1))
            }
            folha(&ctx, em: topo, angulo: -.pi / 2 - 0.25 + sin(t * 2) * 0.1, tamanho: m * 0.045 * broto * some, cor: arvore.folha.mix(with: .white, by: 0.2))
            folha(&ctx, em: topo, angulo: -.pi / 2 + 0.35 + sin(t * 2.2) * 0.1, tamanho: m * 0.04 * broto * some, cor: arvore.folha)
        }

        guard raio > 0.5 else { return }
        let mexe = sin(t * 1.4) * raio * 0.03
        let centro = CGPoint(x: topo.x + mexe, y: topo.y + raio * 0.3)

        switch forma {
        case .redonda:
            nuvem(&ctx, [(0, 0, 1), (-0.75, 0.25, 0.75), (0.75, 0.25, 0.75), (-0.45, -0.45, 0.72), (0.45, -0.45, 0.72), (0, -0.62, 0.6), (-1.05, 0.5, 0.5), (1.05, 0.5, 0.5), (0, 0.55, 0.7)], centro: centro, raio: raio, t: t)
        case .oval:
            nuvem(&ctx, [(0, 0.8, 0.55), (0, 0.2, 0.85), (-0.5, 0.5, 0.6), (0.5, 0.5, 0.6), (-0.45, -0.25, 0.65), (0.45, -0.25, 0.65), (0, -0.7, 0.7), (-0.3, -1.15, 0.5), (0.3, -1.15, 0.5), (0, -1.45, 0.45)], centro: CGPoint(x: centro.x, y: topo.y + raio * 0.2), raio: raio, t: t)
        case .coluna:
            nuvem(&ctx, [(0, 0.9, 0.55), (0.2, 0.6, 0.45), (-0.15, 0.35, 0.6), (0.15, -0.2, 0.58), (-0.2, -0.5, 0.45), (-0.12, -0.75, 0.55), (0.1, -1.3, 0.5), (-0.05, -1.8, 0.42), (0, -2.2, 0.32)], centro: CGPoint(x: centro.x, y: topo.y + raio * 0.5), raio: raio, t: t)
        case .nuvens:
            let tufo: [(Double, Double, Double)] = [(0, 0.2, 0.75), (-0.7, 0.25, 0.7), (0.7, 0.25, 0.7), (-0.35, -0.3, 0.75), (0.35, -0.3, 0.75), (0, -0.55, 0.6)]
            for ponta in galhos + [CGPoint(x: topo.x, y: topo.y - raio * 0.2)] {
                nuvem(&ctx, tufo, centro: CGPoint(x: ponta.x + mexe, y: ponta.y), raio: raio * 0.55, t: t)
            }
        case .guardaChuva:
            nuvem(&ctx, [(-1.45, 0.25, 0.42), (1.45, 0.25, 0.42), (-1.1, -0.1, 0.48), (1.1, -0.1, 0.48), (-0.75, 0.15, 0.55), (0.75, 0.15, 0.55), (0, 0.05, 0.7), (-0.4, -0.3, 0.55), (0.4, -0.3, 0.55), (0, -0.42, 0.45)], centro: CGPoint(x: centro.x, y: topo.y), raio: raio, t: t, achatar: 0.68)
        case .cone:
            pinheiro(&ctx, topo: CGPoint(x: topo.x + mexe, y: topo.y), raio: raio, t: t)
        case .camadas:
            cedro(&ctx, topo: CGPoint(x: topo.x + mexe, y: topo.y), raio: raio, t: t)
        case .candelabro:
            for ponta in galhos + [CGPoint(x: topo.x, y: topo.y - raio * 0.15)] {
                tufo(&ctx, em: CGPoint(x: ponta.x + mexe, y: ponta.y), raio: raio)
            }
        case .palmeira:
            palmeira(&ctx, topo: topo, raio: raio, m: m, t: t)
        }

    }

    private func galho(_ ctx: inout GraphicsContext, de inicio: CGPoint, para fim: CGPoint, cor: Color, largura: CGFloat) {
        var g = Path()
        g.move(to: inicio)
        g.addQuadCurve(to: fim, control: CGPoint(x: inicio.x + (fim.x - inicio.x) * 0.3, y: fim.y + (inicio.y - fim.y) * 0.15))
        ctx.stroke(g, with: .color(cor), style: StrokeStyle(lineWidth: largura, lineCap: .round))
    }

    private func nuvem(_ ctx: inout GraphicsContext, _ bolhas: [(Double, Double, Double)], centro: CGPoint, raio: CGFloat, t: Double, achatar: CGFloat = 1) {
        let fundo = arvore.folha.mix(with: .black, by: 0.3)
        for (camada, cor) in [(0.12, fundo), (0.0, arvore.copa)] {
            for (i, b) in bolhas.enumerated() {
                let r = raio * b.2
                let mexe = sin(t * 1.4 + Double(i)) * raio * 0.025
                let c = CGPoint(x: centro.x + b.0 * raio + mexe, y: centro.y + (b.1 + camada) * raio * achatar)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r * achatar, width: r * 2, height: r * 2 * achatar)), with: .color(cor))
            }
        }
        for (i, b) in bolhas.enumerated() where b.1 < 0.3 {
            let r = raio * b.2 * 0.32
            let c = CGPoint(x: centro.x + b.0 * raio - r * 0.7 + sin(t * 1.4 + Double(i)) * raio * 0.025, y: centro.y + b.1 * raio * achatar - r * 1.2 * achatar)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r * 0.8, width: r * 2, height: r * 1.6)), with: .color(.white.opacity(0.16)))
        }
    }

    private func pinheiro(_ ctx: inout GraphicsContext, topo: CGPoint, raio: CGFloat, t: Double) {
        for i in 0..<4 {
            let largura = raio * (1.15 - 0.22 * CGFloat(i))
            let base = topo.y + raio * (1.55 - 0.6 * CGFloat(i))
            let alto = raio * 0.95
            let mexe = sin(t * 1.2 + Double(i) * 0.4) * raio * 0.03
            for (deslocamento, cor) in [(raio * 0.08, arvore.copa.mix(with: .black, by: 0.3)), (0, arvore.copa)] {
                var tri = Path()
                tri.move(to: CGPoint(x: topo.x - largura + mexe, y: base + deslocamento))
                tri.addQuadCurve(to: CGPoint(x: topo.x + largura + mexe, y: base + deslocamento), control: CGPoint(x: topo.x + mexe, y: base + deslocamento + raio * 0.18))
                tri.addLine(to: CGPoint(x: topo.x + mexe * 1.5, y: base - alto + deslocamento))
                tri.closeSubpath()
                ctx.fill(tri, with: .color(cor))
            }
        }
    }

    private func cedro(_ ctx: inout GraphicsContext, topo: CGPoint, raio: CGFloat, t: Double) {
        for i in 0..<4 {
            let y = topo.y + raio * (1.86 - 0.62 * CGFloat(i))
            let largura = raio * (1.45 - 0.3 * CGFloat(i))
            let espessura = raio * (0.3 - 0.03 * CGFloat(i))
            let mexe = sin(t * 1.3 + Double(i)) * raio * 0.035
            for (deslocamento, cor) in [(espessura * 0.35, arvore.copa.mix(with: .black, by: 0.3)), (0, arvore.copa)] {
                for (x, escala) in [(-0.55, 0.6), (0.55, 0.6), (0.0, 0.75)] as [(CGFloat, CGFloat)] {
                    let w = largura * escala
                    let c = CGPoint(x: topo.x + x * largura + mexe, y: y + deslocamento)
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - w, y: c.y - espessura, width: w * 2, height: espessura * 2)), with: .color(cor))
                }
            }
            let r = espessura * 0.5
            ctx.fill(Path(ellipseIn: CGRect(x: topo.x - largura * 0.4 + mexe, y: y - espessura * 0.9, width: largura * 0.5, height: r)), with: .color(.white.opacity(0.14)))
        }
    }

    private func palmeira(_ ctx: inout GraphicsContext, topo: CGPoint, raio: CGFloat, m: CGFloat, t: Double) {
        let angulos: [Double] = [8, 32, 62, 92, 122, 150, 174]
        for (i, graus) in angulos.enumerated() {
            let a = (graus + sin(t * 1.3 + Double(i)) * 4) * .pi / 180
            let comprimento = raio * (1.45 - 0.25 * abs(cos(a * 2)) * 0.5)
            let direcao = CGPoint(x: cos(a), y: -sin(a))
            let fim = CGPoint(x: topo.x + direcao.x * comprimento, y: topo.y + direcao.y * comprimento * 0.55 + comprimento * 0.4)
            let controle = CGPoint(x: topo.x + direcao.x * comprimento * 0.55, y: topo.y + direcao.y * comprimento * 0.75 - comprimento * 0.1)
            let normal = CGPoint(x: -direcao.y, y: direcao.x)
            let w = comprimento * 0.13
            var frondes = Path()
            frondes.move(to: topo)
            frondes.addQuadCurve(to: fim, control: CGPoint(x: controle.x + normal.x * w, y: controle.y + normal.y * w))
            frondes.addQuadCurve(to: topo, control: CGPoint(x: controle.x - normal.x * w, y: controle.y - normal.y * w))
            let cor = i % 2 == 0 ? arvore.copa : arvore.copa.mix(with: .black, by: 0.18)
            ctx.fill(frondes, with: .color(cor))
            var nervura = Path()
            nervura.move(to: topo)
            nervura.addQuadCurve(to: fim, control: controle)
            ctx.stroke(nervura, with: .color(arvore.copa.mix(with: .black, by: 0.35)), lineWidth: max(0.6, m * 0.003))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: topo.x - raio * 0.12, y: topo.y - raio * 0.1, width: raio * 0.24, height: raio * 0.2)), with: .color(arvore.copa.mix(with: .black, by: 0.3)))
    }

    private func vaso(_ ctx: inout GraphicsContext, cx: CGFloat, chao: CGFloat, m: CGFloat, t: Double) {
        let alto = m * 0.2
        let cima = m * 0.17
        let baixo = m * 0.125
        ctx.fill(Path(ellipseIn: CGRect(x: cx - cima * 1.1, y: chao + alto - m * 0.015, width: cima * 2.2, height: m * 0.045)), with: .color(.black.opacity(0.12)))
        var corpo = Path()
        corpo.move(to: CGPoint(x: cx - cima, y: chao))
        corpo.addLine(to: CGPoint(x: cx + cima, y: chao))
        corpo.addLine(to: CGPoint(x: cx + baixo, y: chao + alto - m * 0.02))
        corpo.addQuadCurve(to: CGPoint(x: cx - baixo, y: chao + alto - m * 0.02), control: CGPoint(x: cx, y: chao + alto + m * 0.015))
        corpo.closeSubpath()
        ctx.fill(corpo, with: .linearGradient(Gradient(colors: [arvore.vaso.mix(with: .white, by: 0.15), arvore.vaso.mix(with: .black, by: 0.12)]), startPoint: CGPoint(x: cx - cima, y: chao), endPoint: CGPoint(x: cx + cima, y: chao + alto)))
        let borda = Path(roundedRect: CGRect(x: cx - cima * 1.08, y: chao - m * 0.035, width: cima * 2.16, height: m * 0.05), cornerRadius: m * 0.015)
        ctx.fill(borda, with: .color(arvore.vaso.mix(with: .black, by: 0.08)))
        ctx.fill(Path(ellipseIn: CGRect(x: cx - cima * 0.95, y: chao - m * 0.045, width: cima * 1.9, height: m * 0.03)), with: .color(Color(red: 0.36, green: 0.25, blue: 0.2)))

        rosto(&ctx, cx: cx, olhoY: chao + alto * 0.42, m: m, t: t)
    }

    private func terra(_ ctx: inout GraphicsContext, cx: CGFloat, chao: CGFloat, m: CGFloat) {
        let cima = m * 0.17
        var c = ctx
        c.clip(to: Path(CGRect(x: cx - cima, y: chao - m * 0.034, width: cima * 2, height: m * 0.03)))
        c.fill(Path(ellipseIn: CGRect(x: cx - cima * 0.95, y: chao - m * 0.045, width: cima * 1.9, height: m * 0.03)), with: .color(Color(red: 0.36, green: 0.25, blue: 0.2)))
    }

    private func tronco(_ ctx: inout GraphicsContext, base: CGPoint, meio: CGPoint, topo: CGPoint, grossura: CGFloat, cor: Color, afinar: CGFloat) {
        let n = 14
        var esquerda: [CGPoint] = []
        var direita: [CGPoint] = []
        var centro: [CGPoint] = []
        for i in 0...n {
            let u = Double(i) / Double(n)
            let a = (1 - u) * (1 - u), b = 2 * (1 - u) * u, c = u * u
            let p = CGPoint(x: a * base.x + b * meio.x + c * topo.x, y: a * base.y + b * meio.y + c * topo.y)
            let dx = 2 * (1 - u) * (meio.x - base.x) + 2 * u * (topo.x - meio.x)
            let dy = 2 * (1 - u) * (meio.y - base.y) + 2 * u * (topo.y - meio.y)
            let len = max(0.001, sqrt(dx * dx + dy * dy))
            let raiz = u < 0.12 ? 1 + 0.6 * pow((0.12 - u) / 0.12, 2) : 1
            let w = grossura * 0.5 * (1 - afinar * CGFloat(u)) * raiz
            esquerda.append(CGPoint(x: p.x - dy / len * w, y: p.y + dx / len * w))
            direita.append(CGPoint(x: p.x + dy / len * w, y: p.y - dx / len * w))
            centro.append(p)
        }
        var corpo = Path()
        corpo.move(to: esquerda[0])
        for q in esquerda.dropFirst() { corpo.addLine(to: q) }
        let ponta = grossura * 0.5 * (1 - afinar)
        corpo.addQuadCurve(to: direita[n], control: CGPoint(x: topo.x, y: topo.y - ponta))
        for q in direita.reversed().dropFirst() { corpo.addLine(to: q) }
        corpo.closeSubpath()
        ctx.fill(corpo, with: .linearGradient(Gradient(colors: [cor.mix(with: .white, by: 0.16), cor, cor.mix(with: .black, by: 0.22)]), startPoint: CGPoint(x: base.x - grossura * 0.6, y: base.y), endPoint: CGPoint(x: base.x + grossura * 0.6, y: base.y)))
        guard grossura > 4 else { return }
        var luz = Path()
        luz.move(to: CGPoint(x: (esquerda[1].x * 2 + centro[1].x) / 3, y: centro[1].y))
        for i in 2..<(n - 1) {
            luz.addLine(to: CGPoint(x: (esquerda[i].x * 2 + centro[i].x) / 3, y: (esquerda[i].y * 2 + centro[i].y) / 3))
        }
        ctx.stroke(luz, with: .color(.white.opacity(0.14)), style: StrokeStyle(lineWidth: grossura * 0.12, lineCap: .round))
        for i in stride(from: 3, to: n - 2, by: 3) {
            var casca = Path()
            let q = centro[i]
            casca.move(to: CGPoint(x: (q.x + direita[i].x) / 2, y: q.y))
            casca.addQuadCurve(to: CGPoint(x: (q.x + direita[i].x) / 2 + grossura * 0.05, y: q.y - grossura * 0.5), control: CGPoint(x: (q.x + direita[i].x) / 2 + grossura * 0.12, y: q.y - grossura * 0.2))
            ctx.stroke(casca, with: .color(.black.opacity(0.12)), style: StrokeStyle(lineWidth: max(0.6, grossura * 0.06), lineCap: .round))
        }
    }

    private func tufo(_ ctx: inout GraphicsContext, em p: CGPoint, raio: CGFloat) {
        let w = raio * 0.36
        let h = raio * 0.14
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - w, y: p.y - h + h * 0.5, width: w * 2, height: h * 2)), with: .color(arvore.copa.mix(with: .black, by: 0.3)))
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - w, y: p.y - h, width: w * 2, height: h * 2)), with: .color(arvore.copa))
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - w * 0.6, y: p.y - h * 1.7, width: w * 1.2, height: h * 1.6)), with: .color(arvore.copa.mix(with: .white, by: 0.08)))
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - w * 0.45, y: p.y - h * 1.5, width: w * 0.5, height: h * 0.5)), with: .color(.white.opacity(0.14)))
    }

    private func rosto(_ ctx: inout GraphicsContext, cx: CGFloat, olhoY: CGFloat, m: CGFloat, t: Double) {
        let tinta = Color.black.opacity(0.75)
        let linha = StrokeStyle(lineWidth: max(1, m * 0.006), lineCap: .round)
        let piscando = t.truncatingRemainder(dividingBy: 4.2) > 4.07
        func arco(_ x: CGFloat, _ curva: CGFloat) {
            var p = Path()
            p.move(to: CGPoint(x: x - m * 0.013, y: olhoY + m * 0.003))
            p.addQuadCurve(to: CGPoint(x: x + m * 0.013, y: olhoY + m * 0.003), control: CGPoint(x: x, y: olhoY + curva))
            ctx.stroke(p, with: .color(tinta), style: linha)
        }
        for lado: CGFloat in [-1, 1] {
            let x = cx + lado * m * 0.045
            var olho = arvore.rosto.0
            if olho == .piscadinha { olho = lado < 0 ? .brilho : .felizes }
            let aberto = olho == .brilho || olho == .pontos || olho == .grandes
            if piscando && aberto {
                arco(x, m * 0.003)
            } else {
                switch olho {
                case .brilho, .piscadinha:
                    let r = m * 0.012
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: olhoY - r * 1.2, width: r * 2, height: r * 2.4)), with: .color(tinta))
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r * 0.2, y: olhoY - r * 0.9, width: r * 0.8, height: r * 0.8)), with: .color(.white))
                case .pontos:
                    let r = m * 0.009
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: olhoY - r, width: r * 2, height: r * 2)), with: .color(tinta))
                case .felizes:
                    arco(x, -m * 0.014)
                case .sono:
                    arco(x, m * 0.012)
                case .grandes:
                    let r = m * 0.016
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: olhoY - r * 1.15, width: r * 2, height: r * 2.3)), with: .color(tinta))
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r * 0.1, y: olhoY - r * 0.85, width: r * 0.75, height: r * 0.75)), with: .color(.white))
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r * 0.55, y: olhoY + r * 0.25, width: r * 0.35, height: r * 0.35)), with: .color(.white.opacity(0.8)))
                }
            }
            ctx.fill(Path(ellipseIn: CGRect(x: x + lado * m * 0.022 - m * 0.016, y: olhoY + m * 0.022, width: m * 0.032, height: m * 0.016)), with: .color(Color.pink.opacity(0.45)))
        }
        let y = olhoY + m * 0.03
        let rosa = Color(red: 0.95, green: 0.45, blue: 0.5)
        switch arvore.rosto.1 {
        case .sorriso:
            var b = Path()
            b.move(to: CGPoint(x: cx - m * 0.02, y: y))
            b.addQuadCurve(to: CGPoint(x: cx + m * 0.02, y: y), control: CGPoint(x: cx, y: y + m * 0.025))
            ctx.stroke(b, with: .color(tinta), style: linha)
        case .aberta:
            var b = Path()
            b.move(to: CGPoint(x: cx - m * 0.02, y: y - m * 0.002))
            b.addQuadCurve(to: CGPoint(x: cx + m * 0.02, y: y - m * 0.002), control: CGPoint(x: cx, y: y + m * 0.04))
            b.closeSubpath()
            ctx.fill(b, with: .color(tinta))
            var c = ctx
            c.clip(to: b)
            c.fill(Path(ellipseIn: CGRect(x: cx - m * 0.011, y: y + m * 0.009, width: m * 0.022, height: m * 0.016)), with: .color(rosa))
        case .o:
            ctx.fill(Path(ellipseIn: CGRect(x: cx - m * 0.007, y: y, width: m * 0.014, height: m * 0.016)), with: .color(tinta))
        case .gato:
            var b = Path()
            b.move(to: CGPoint(x: cx - m * 0.02, y: y + m * 0.003))
            b.addQuadCurve(to: CGPoint(x: cx, y: y + m * 0.003), control: CGPoint(x: cx - m * 0.01, y: y + m * 0.02))
            b.addQuadCurve(to: CGPoint(x: cx + m * 0.02, y: y + m * 0.003), control: CGPoint(x: cx + m * 0.01, y: y + m * 0.02))
            ctx.stroke(b, with: .color(tinta), style: linha)
        case .lingua:
            ctx.fill(Path(roundedRect: CGRect(x: cx + m * 0.001, y: y + m * 0.008, width: m * 0.014, height: m * 0.017), cornerRadius: m * 0.007), with: .color(rosa))
            var b = Path()
            b.move(to: CGPoint(x: cx - m * 0.02, y: y))
            b.addQuadCurve(to: CGPoint(x: cx + m * 0.02, y: y), control: CGPoint(x: cx, y: y + m * 0.022))
            ctx.stroke(b, with: .color(tinta), style: linha)
        case .deLado:
            var b = Path()
            b.move(to: CGPoint(x: cx - m * 0.012, y: y + m * 0.006))
            b.addQuadCurve(to: CGPoint(x: cx + m * 0.02, y: y - m * 0.002), control: CGPoint(x: cx + m * 0.008, y: y + m * 0.016))
            ctx.stroke(b, with: .color(tinta), style: linha)
        }
    }

    private func desenharSemente(_ ctx: inout GraphicsContext, base: CGPoint, m: CGFloat, t: Double) {
        let pulo = abs(sin(t * 2)) * m * 0.006
        let r = m * 0.03
        let c = CGPoint(x: base.x, y: base.y - r * 0.35 - pulo)
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r * 0.7, width: r * 2, height: r * 1.4)), with: .color(arvore.caule.mix(with: .white, by: 0.15)))
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.5, y: c.y - r * 0.5, width: r * 0.6, height: r * 0.4)), with: .color(.white.opacity(0.35)))
    }

    private func folha(_ ctx: inout GraphicsContext, em ponto: CGPoint, angulo: Double, tamanho: CGFloat, cor: Color) {
        var c = ctx
        c.translateBy(x: ponto.x, y: ponto.y)
        c.rotate(by: .radians(angulo))
        var p = Path()
        p.move(to: .zero)
        p.addQuadCurve(to: CGPoint(x: tamanho, y: 0), control: CGPoint(x: tamanho * 0.5, y: -tamanho * 0.42))
        p.addQuadCurve(to: .zero, control: CGPoint(x: tamanho * 0.5, y: tamanho * 0.42))
        c.fill(p, with: .color(cor))
        var nervura = Path()
        nervura.move(to: CGPoint(x: tamanho * 0.1, y: 0))
        nervura.addLine(to: CGPoint(x: tamanho * 0.8, y: 0))
        c.stroke(nervura, with: .color(.white.opacity(0.35)), lineWidth: max(0.6, tamanho * 0.04))
    }
}
