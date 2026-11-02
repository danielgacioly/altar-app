import SwiftUI

enum Fruto {
    case uva, bola, flor, pinha
}

struct TipoDeVideira: Identifiable {
    let id: Int
    let nome: String
    let descricao: String
    let folha: Color
    let caule: Color
    let fruto: Color
    let forma: Fruto
    let vaso: Color
    let folhaLonga: Bool

    static func cor(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    static let todas: [TipoDeVideira] = [
        TipoDeVideira(id: 0, nome: "Videira", descricao: "\"Eu sou a videira, vós, as varas.\" A primeira de todas.", folha: cor(0x4CAF50), caule: cor(0x7A5230), fruto: cor(0x7B3FA0), forma: .uva, vaso: cor(0xD9774B), folhaLonga: false),
        TipoDeVideira(id: 1, nome: "Oliveira", descricao: "Árvore da paz, firme e paciente.", folha: cor(0x8DA47E), caule: cor(0x6D5D4B), fruto: cor(0x4E5D2A), forma: .bola, vaso: cor(0xC9B79C), folhaLonga: true),
        TipoDeVideira(id: 2, nome: "Figueira", descricao: "Folhas grandes e figos doces.", folha: cor(0x3E8E41), caule: cor(0x80603F), fruto: cor(0x8E4585), forma: .bola, vaso: cor(0x5C8DD6), folhaLonga: false),
        TipoDeVideira(id: 3, nome: "Romãzeira", descricao: "Cheia de sementes, cheia de vida.", folha: cor(0x5BA55B), caule: cor(0x7B4A2E), fruto: cor(0xD7263D), forma: .bola, vaso: cor(0xE8C468), folhaLonga: true),
        TipoDeVideira(id: 4, nome: "Amendoeira", descricao: "A primeira a florescer depois do inverno.", folha: cor(0x6DBE6D), caule: cor(0x6B4F3A), fruto: cor(0xF7C6D9), forma: .flor, vaso: cor(0x9C7AD1), folhaLonga: true),
        TipoDeVideira(id: 5, nome: "Macieira", descricao: "Maçãs vermelhas para colher no fim.", folha: cor(0x43A047), caule: cor(0x795035), fruto: cor(0xE53935), forma: .bola, vaso: cor(0x4DB6AC), folhaLonga: false),
        TipoDeVideira(id: 6, nome: "Laranjeira", descricao: "Perfume de flor e frutos dourados.", folha: cor(0x2E7D32), caule: cor(0x6D4C2F), fruto: cor(0xFB8C00), forma: .bola, vaso: cor(0x3F7FBF), folhaLonga: false),
        TipoDeVideira(id: 7, nome: "Cerejeira", descricao: "Uma nuvem de flores cor-de-rosa.", folha: cor(0x66BB6A), caule: cor(0x5D4037), fruto: cor(0xF48FB1), forma: .flor, vaso: cor(0xF5F0E6), folhaLonga: false),
        TipoDeVideira(id: 8, nome: "Limoeiro", descricao: "Limões amarelos como o sol da manhã.", folha: cor(0x388E3C), caule: cor(0x6E5233), fruto: cor(0xFDD835), forma: .bola, vaso: cor(0x26A69A), folhaLonga: true),
        TipoDeVideira(id: 9, nome: "Mirtilo", descricao: "Cachos azuis, pequenos e preciosos.", folha: cor(0x4E9A6A), caule: cor(0x5F4B3A), fruto: cor(0x3F51B5), forma: .uva, vaso: cor(0xF2A65A), folhaLonga: false),
        TipoDeVideira(id: 10, nome: "Acácia", descricao: "Madeira da arca, flores de ouro.", folha: cor(0x7CB342), caule: cor(0x8D6E4A), fruto: cor(0xFFEB3B), forma: .flor, vaso: cor(0xB5654A), folhaLonga: true),
        TipoDeVideira(id: 11, nome: "Cedro do Líbano", descricao: "Forte e alto. A coroa da coleção.", folha: cor(0x1B5E20), caule: cor(0x5D4632), fruto: cor(0x8D6E63), forma: .pinha, vaso: cor(0x78909C), folhaLonga: true)
    ]
}

struct DesenhoDaPlanta: View {
    let tipo: TipoDeVideira
    let estagio: Double
    var animado = true
    var crescerDesde: Date?

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

    private func desenhar(_ ctx: inout GraphicsContext, _ tamanho: CGSize, _ agora: Date?) {
        let t = agora?.timeIntervalSinceReferenceDate ?? 0
        var e = estagio
        if let crescerDesde, let agora, estagio >= 1 {
            let k = min(1, max(0, agora.timeIntervalSince(crescerDesde) / 1.8))
            e = estagio - 1 + (1 - pow(1 - k, 3))
        }
        let p = min(1, max(0, e / 30))
        let m = min(tamanho.width, tamanho.height)
        let cx = tamanho.width / 2
        let chao = tamanho.height * 0.74

        vaso(&ctx, cx: cx, chao: chao, m: m, t: t)

        let base = CGPoint(x: cx, y: chao - m * 0.03)
        if e < 0.5 {
            semente(&ctx, base: base, m: m, t: t)
            return
        }

        let altura = m * (0.1 + 0.52 * (1 - pow(1 - p, 2)))
        let vento = sin(t * 1.3) * (0.025 + 0.02 * p)
        let topo = CGPoint(x: cx + vento * altura, y: base.y - altura)
        let meio = CGPoint(x: cx - vento * altura * 0.3, y: base.y - altura * 0.5)
        func ponto(_ u: Double) -> CGPoint {
            let a = (1 - u) * (1 - u), b = 2 * (1 - u) * u, c = u * u
            return CGPoint(x: a * base.x + b * meio.x + c * topo.x, y: a * base.y + b * meio.y + c * topo.y)
        }

        let madeira = p < 0.4 ? tipo.folha.mix(with: .black, by: 0.2) : tipo.folha.mix(with: .black, by: 0.2).mix(with: tipo.caule, by: min(1, (p - 0.4) / 0.35))
        let grossura = max(2.5, m * (0.012 + 0.032 * p))

        if p > 0.35 {
            let n = min(4, Int((p - 0.35) / 0.12) + 1)
            for i in 0..<n {
                let lado: CGFloat = i % 2 == 0 ? -1 : 1
                let inicio = ponto(0.42 + 0.13 * Double(i))
                let comprimento = altura * (0.25 + 0.12 * p) * (1 - 0.12 * CGFloat(i))
                let fim = CGPoint(x: inicio.x + lado * comprimento * 0.85 + vento * comprimento, y: inicio.y - comprimento * 0.6)
                let controle = CGPoint(x: inicio.x + lado * comprimento * 0.35, y: inicio.y - comprimento * 0.05)
                var galho = Path()
                galho.move(to: inicio)
                galho.addQuadCurve(to: fim, control: controle)
                ctx.stroke(galho, with: .color(madeira), style: StrokeStyle(lineWidth: grossura * 0.55, lineCap: .round))
                if p < 0.75 {
                    folha(&ctx, em: fim, angulo: Double(lado) * -0.6 - .pi / 2 + sin(t * 1.7 + Double(i)) * 0.12, tamanho: m * 0.06, cor: tipo.folha)
                    folha(&ctx, em: fim, angulo: Double(lado) * 0.4 - .pi / 2 + sin(t * 1.5 + Double(i)) * 0.12, tamanho: m * 0.05, cor: tipo.folha.mix(with: .white, by: 0.12))
                }
            }
        }

        var caule = Path()
        caule.move(to: base)
        caule.addQuadCurve(to: topo, control: meio)
        ctx.stroke(caule, with: .color(madeira), style: StrokeStyle(lineWidth: grossura, lineCap: .round))

        let folhas = 2 + Int(p * 10)
        for i in 0..<folhas {
            let u = 0.18 + 0.78 * Double(i + 1) / Double(folhas + 1)
            if p > 0.6 && u > 0.6 { continue }
            let lado: Double = i % 2 == 0 ? -1 : 1
            let balanco = sin(t * 1.8 + Double(i) * 0.9) * 0.15
            let tam = m * (0.05 + 0.035 * p) * (i == folhas - 1 ? 0.75 : 1)
            folha(&ctx, em: ponto(u), angulo: -.pi / 2 + lado * 0.95 + balanco, tamanho: tam, cor: i % 2 == 0 ? tipo.folha : tipo.folha.mix(with: .white, by: 0.1))
        }
        if p <= 0.6 {
            folha(&ctx, em: topo, angulo: -.pi / 2 - 0.25 + sin(t * 2) * 0.1, tamanho: m * 0.045, cor: tipo.folha.mix(with: .white, by: 0.2))
            folha(&ctx, em: topo, angulo: -.pi / 2 + 0.35 + sin(t * 2.2) * 0.1, tamanho: m * 0.04, cor: tipo.folha)
        }

        guard p > 0.5 else { return }
        let q = (p - 0.5) / 0.5
        let raio = m * (0.07 + 0.17 * q)
        let centro = CGPoint(x: topo.x, y: topo.y + raio * 0.3)
        if tipo.forma == .pinha {
            pinheiro(&ctx, topo: topo, raio: raio, m: m, t: t, p: p)
            return
        }
        let bolhas: [(Double, Double, Double)] = [(0, 0, 1), (-0.75, 0.25, 0.75), (0.75, 0.25, 0.75), (-0.45, -0.45, 0.72), (0.45, -0.45, 0.72), (0, -0.62, 0.6), (-1.05, 0.5, 0.5), (1.05, 0.5, 0.5), (0, 0.55, 0.7)]
        for (camada, cor) in [(0.12, tipo.folha.mix(with: .black, by: 0.25)), (0.0, tipo.folha)] {
            for (i, b) in bolhas.enumerated() {
                let r = raio * b.2
                let mexe = sin(t * 1.4 + Double(i)) * raio * 0.025
                let c = CGPoint(x: centro.x + b.0 * raio + mexe, y: centro.y + b.1 * raio + camada * raio)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(cor))
            }
        }
        for (i, b) in bolhas.prefix(5).enumerated() {
            let r = raio * b.2 * 0.35
            let c = CGPoint(x: centro.x + b.0 * raio - r * 0.6 + sin(t * 1.4 + Double(i)) * raio * 0.025, y: centro.y + b.1 * raio - r * 0.9)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 1.6)), with: .color(.white.opacity(0.18)))
        }

        if p >= 0.66 {
            let n = min(10, 1 + Int((p - 0.66) / 0.034))
            for i in 0..<n {
                let ang = Double(i) * 2.39996 + 0.6
                let dist = raio * (0.3 + 0.55 * (Double(i) * 0.618).truncatingRemainder(dividingBy: 1))
                let pos = CGPoint(x: centro.x + cos(ang) * dist + sin(t * 1.4) * raio * 0.025, y: centro.y + sin(ang) * dist * 0.8 + raio * 0.1)
                fruto(&ctx, em: pos, m: m, t: t, i: i)
            }
        }

        if p >= 0.99 {
            for i in 0..<7 {
                let ang = Double(i) / 7 * .pi * 2 + t * 0.15
                let pos = CGPoint(x: centro.x + cos(ang) * raio * 1.55, y: centro.y + sin(ang) * raio * 1.25)
                let brilho = 0.5 + 0.5 * sin(t * 3 + Double(i) * 1.3)
                estrela(&ctx, em: pos, tamanho: m * 0.018 * (0.6 + brilho * 0.6), cor: Color.yellow.opacity(0.4 + brilho * 0.6))
            }
        }
    }

    private func pinheiro(_ ctx: inout GraphicsContext, topo: CGPoint, raio: CGFloat, m: CGFloat, t: Double, p: Double) {
        let mexe = sin(t * 1.2) * raio * 0.03
        for (i, nivel) in [(0, 1.0), (1, 0.78), (2, 0.56)] {
            let largura = raio * 1.25 * nivel
            let alto = raio * 0.95
            let base = topo.y + raio * 1.2 - CGFloat(i) * raio * 0.62
            for (deslocamento, cor) in [(raio * 0.08, tipo.folha.mix(with: .black, by: 0.3)), (0, tipo.folha)] {
                var tri = Path()
                tri.move(to: CGPoint(x: topo.x - largura + mexe, y: base + deslocamento))
                tri.addQuadCurve(to: CGPoint(x: topo.x + largura + mexe, y: base + deslocamento), control: CGPoint(x: topo.x + mexe, y: base + deslocamento + raio * 0.18))
                tri.addLine(to: CGPoint(x: topo.x + mexe * 1.5, y: base - alto + deslocamento))
                tri.closeSubpath()
                ctx.fill(tri, with: .color(cor))
            }
        }
        if p >= 0.66 {
            let n = min(8, 1 + Int((p - 0.66) / 0.04))
            for i in 0..<n {
                let lado: CGFloat = i % 2 == 0 ? -1 : 1
                let nivel = CGFloat(i / 2 % 3)
                let pos = CGPoint(x: topo.x + lado * raio * (0.45 - nivel * 0.1) + mexe, y: topo.y + raio * 1.0 - nivel * raio * 0.62)
                fruto(&ctx, em: pos, m: m, t: t, i: i)
            }
        }
        if p >= 0.99 {
            for i in 0..<7 {
                let ang = Double(i) / 7 * .pi * 2 + t * 0.15
                let pos = CGPoint(x: topo.x + cos(ang) * raio * 1.5, y: topo.y + sin(ang) * raio * 1.2)
                let brilho = 0.5 + 0.5 * sin(t * 3 + Double(i) * 1.3)
                estrela(&ctx, em: pos, tamanho: m * 0.018 * (0.6 + brilho * 0.6), cor: Color.yellow.opacity(0.4 + brilho * 0.6))
            }
        }
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
        ctx.fill(corpo, with: .linearGradient(Gradient(colors: [tipo.vaso.mix(with: .white, by: 0.15), tipo.vaso.mix(with: .black, by: 0.12)]), startPoint: CGPoint(x: cx - cima, y: chao), endPoint: CGPoint(x: cx + cima, y: chao + alto)))
        let borda = Path(roundedRect: CGRect(x: cx - cima * 1.08, y: chao - m * 0.035, width: cima * 2.16, height: m * 0.05), cornerRadius: m * 0.015)
        ctx.fill(borda, with: .color(tipo.vaso.mix(with: .black, by: 0.08)))
        ctx.fill(Path(ellipseIn: CGRect(x: cx - cima * 0.95, y: chao - m * 0.045, width: cima * 1.9, height: m * 0.03)), with: .color(Color(red: 0.36, green: 0.25, blue: 0.2)))

        let olhoY = chao + alto * 0.42
        let piscando = t.truncatingRemainder(dividingBy: 4.2) > 4.07
        for lado: CGFloat in [-1, 1] {
            let x = cx + lado * m * 0.045
            if piscando {
                var p = Path()
                p.move(to: CGPoint(x: x - m * 0.012, y: olhoY))
                p.addLine(to: CGPoint(x: x + m * 0.012, y: olhoY))
                ctx.stroke(p, with: .color(.black.opacity(0.75)), style: StrokeStyle(lineWidth: max(1, m * 0.006), lineCap: .round))
            } else {
                let r = m * 0.012
                ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: olhoY - r * 1.2, width: r * 2, height: r * 2.4)), with: .color(.black.opacity(0.75)))
                ctx.fill(Path(ellipseIn: CGRect(x: x - r * 0.2, y: olhoY - r * 0.9, width: r * 0.8, height: r * 0.8)), with: .color(.white))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: x + lado * m * 0.022 - m * 0.016, y: olhoY + m * 0.022, width: m * 0.032, height: m * 0.016)), with: .color(Color.pink.opacity(0.45)))
        }
        var boca = Path()
        boca.move(to: CGPoint(x: cx - m * 0.02, y: olhoY + m * 0.03))
        boca.addQuadCurve(to: CGPoint(x: cx + m * 0.02, y: olhoY + m * 0.03), control: CGPoint(x: cx, y: olhoY + m * 0.055))
        ctx.stroke(boca, with: .color(.black.opacity(0.7)), style: StrokeStyle(lineWidth: max(1, m * 0.006), lineCap: .round))
    }

    private func semente(_ ctx: inout GraphicsContext, base: CGPoint, m: CGFloat, t: Double) {
        let pulo = abs(sin(t * 2)) * m * 0.006
        let r = m * 0.03
        let c = CGPoint(x: base.x, y: base.y - r * 0.35 - pulo)
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r * 0.7, width: r * 2, height: r * 1.4)), with: .color(tipo.caule.mix(with: .white, by: 0.15)))
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.5, y: c.y - r * 0.5, width: r * 0.6, height: r * 0.4)), with: .color(.white.opacity(0.35)))
        folha(&ctx, em: CGPoint(x: c.x, y: c.y - r * 0.6), angulo: -.pi / 2 + 0.5 + sin(t * 2) * 0.15, tamanho: m * 0.03, cor: tipo.folha)
    }

    private func folha(_ ctx: inout GraphicsContext, em ponto: CGPoint, angulo: Double, tamanho: CGFloat, cor: Color) {
        var c = ctx
        c.translateBy(x: ponto.x, y: ponto.y)
        c.rotate(by: .radians(angulo))
        let largura = tipo.folhaLonga ? 0.28 : 0.5
        var p = Path()
        p.move(to: .zero)
        p.addQuadCurve(to: CGPoint(x: tamanho, y: 0), control: CGPoint(x: tamanho * 0.5, y: -tamanho * largura))
        p.addQuadCurve(to: .zero, control: CGPoint(x: tamanho * 0.5, y: tamanho * largura))
        c.fill(p, with: .color(cor))
        var nervura = Path()
        nervura.move(to: CGPoint(x: tamanho * 0.1, y: 0))
        nervura.addLine(to: CGPoint(x: tamanho * 0.8, y: 0))
        c.stroke(nervura, with: .color(.white.opacity(0.35)), lineWidth: max(0.6, tamanho * 0.04))
    }

    private func fruto(_ ctx: inout GraphicsContext, em p: CGPoint, m: CGFloat, t: Double, i: Int) {
        switch tipo.forma {
        case .uva:
            let r = m * 0.013
            for (dx, dy) in [(-1.0, 0.0), (1.0, 0.0), (0.0, 0.0), (-0.5, 0.85), (0.5, 0.85), (0.0, 1.7)] {
                let c = CGPoint(x: p.x + dx * r * 1.1, y: p.y + dy * r * 1.1)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(tipo.fruto))
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.5, y: c.y - r * 0.6, width: r * 0.6, height: r * 0.5)), with: .color(.white.opacity(0.35)))
            }
        case .bola:
            let r = m * 0.022
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(tipo.fruto))
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r * 0.55, y: p.y - r * 0.6, width: r * 0.6, height: r * 0.45)), with: .color(.white.opacity(0.45)))
            folha(&ctx, em: CGPoint(x: p.x, y: p.y - r * 0.9), angulo: -.pi / 2 + 0.7, tamanho: r * 0.9, cor: tipo.folha.mix(with: .white, by: 0.15))
        case .flor:
            let r = m * 0.012
            let gira = sin(t * 0.8 + Double(i)) * 0.2
            for k in 0..<5 {
                let a = Double(k) / 5 * .pi * 2 + gira
                let c = CGPoint(x: p.x + cos(a) * r * 1.1, y: p.y + sin(a) * r * 1.1)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(tipo.fruto))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r * 0.7, y: p.y - r * 0.7, width: r * 1.4, height: r * 1.4)), with: .color(Color(red: 1, green: 0.8, blue: 0.25)))
        case .pinha:
            let r = m * 0.016
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r * 1.5, width: r * 2, height: r * 3)), with: .color(tipo.fruto))
            for k in 0..<3 {
                var l = Path()
                let y = p.y - r * 0.8 + CGFloat(k) * r * 0.8
                l.move(to: CGPoint(x: p.x - r * 0.8, y: y))
                l.addLine(to: CGPoint(x: p.x + r * 0.8, y: y + r * 0.3))
                ctx.stroke(l, with: .color(.black.opacity(0.25)), lineWidth: max(0.5, r * 0.15))
            }
        }
    }

    private func estrela(_ ctx: inout GraphicsContext, em p: CGPoint, tamanho s: CGFloat, cor: Color) {
        var e = Path()
        e.move(to: CGPoint(x: p.x, y: p.y - s * 2))
        e.addQuadCurve(to: CGPoint(x: p.x + s * 2, y: p.y), control: p)
        e.addQuadCurve(to: CGPoint(x: p.x, y: p.y + s * 2), control: p)
        e.addQuadCurve(to: CGPoint(x: p.x - s * 2, y: p.y), control: p)
        e.addQuadCurve(to: CGPoint(x: p.x, y: p.y - s * 2), control: p)
        ctx.fill(e, with: .color(cor))
    }
}
