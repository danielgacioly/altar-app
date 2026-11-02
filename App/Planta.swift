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
    var caidaDesde: Date?
    var instante: Date?

    static let duracaoDaQueda = 4.4

    var body: some View {
        if animado {
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { linha in
                Canvas { ctx, tamanho in
                    desenhar(&ctx, tamanho, linha.date)
                }
            }
        } else {
            Canvas { ctx, tamanho in
                desenhar(&ctx, tamanho, instante)
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
        var queda: Double?
        if let caidaDesde, let agora {
            let q = agora.timeIntervalSince(caidaDesde)
            if q >= 0 && q < Self.duracaoDaQueda { queda = q }
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

        let altura = m * (0.1 + 0.38 * (1 - pow(1 - p, 2)))
        var vento = sin(t * 1.3) * (0.025 + 0.02 * p)
        if let q = queda, q < 0.7 {
            vento += sin(q * 38) * (1 - q / 0.7) * 0.06
        }
        let topo = CGPoint(x: cx + vento * altura, y: base.y - altura)
        let meio = CGPoint(x: cx - vento * altura * 0.3, y: base.y - altura * 0.5)
        func ponto(_ u: Double) -> CGPoint {
            let a = (1 - u) * (1 - u), b = 2 * (1 - u) * u, c = u * u
            return CGPoint(x: a * base.x + b * meio.x + c * topo.x, y: a * base.y + b * meio.y + c * topo.y)
        }

        let madeira = p < 0.4 ? tipo.folha.mix(with: .black, by: 0.2) : tipo.folha.mix(with: .black, by: 0.2).mix(with: tipo.caule, by: min(1, (p - 0.4) / 0.35))
        let grossura = max(2.5, m * (0.012 + 0.03 * p))

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
        let raio = m * (0.07 + 0.135 * q)
        let centro = CGPoint(x: topo.x, y: topo.y + raio * 0.3)
        let pousoNaTerra = chao - m * 0.045
        let pousoNoChao = chao + m * 0.185
        let larguraDoVaso = m * 0.16

        if tipo.forma == .pinha {
            pinheiro(&ctx, topo: topo, raio: raio, m: m, t: t)
        } else {
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
        }

        if p >= 0.66 {
            let vagas: [(Double, Double)] = tipo.forma == .pinha
                ? [(-0.62, 1.05), (0.6, 1.0), (-0.42, 0.42), (0.4, 0.38), (-0.22, -0.18), (0.24, -0.2), (0, 0.75), (0.02, 0.15)]
                : [(-0.5, 0.32), (0.48, 0.28), (0.02, 0.6), (-0.15, -0.12), (0.4, -0.38), (-0.78, -0.02), (0.82, 0.12), (-0.42, -0.5)]
            let n = min(vagas.count, 1 + Int((e - 20) * Double(vagas.count - 1) / 10))
            let mexe = sin(t * 1.4) * raio * 0.025
            for i in 0..<n {
                let origem = CGPoint(x: centro.x + vagas[i].0 * raio + mexe, y: centro.y + vagas[i].1 * raio)
                var pos = origem
                var escala: CGFloat = 1
                var alfa = 1.0
                var giro = sin(t * 1.6 + Double(i)) * 0.08
                if let qd = queda {
                    let atraso = 0.3 + Double(i % 4) * 0.12 + Double(i / 4) * 0.07
                    let d = qd - atraso
                    if qd >= 3.6 {
                        let k = min(1, (qd - 3.6) / 0.6)
                        let s = 1.70158
                        escala = CGFloat(1 + (s + 1) * pow(k - 1, 3) + s * pow(k - 1, 2))
                    } else if d > 0 {
                        let dentroDoVaso = abs(origem.x - cx) < larguraDoVaso * 0.85
                        let chaoY = dentroDoVaso ? pousoNaTerra : pousoNoChao
                        let g = Double(m) * 3.4
                        let h = max(1, Double(chaoY - origem.y))
                        let tf = sqrt(2 * h / g)
                        let lado: Double = origem.x < cx ? -1 : 1
                        if d < tf {
                            pos.y = origem.y + CGFloat(0.5 * g * d * d)
                            giro += d * 2.5 * lado
                        } else {
                            let t2 = d - tf
                            let v = g * tf * 0.3
                            pos.y = chaoY - CGFloat(max(0, v * t2 - 0.5 * g * t2 * t2))
                            pos.x = origem.x + CGFloat(lado * Double(m) * (dentroDoVaso ? 0.015 : 0.05) * min(1, t2 / 0.9))
                            giro += (tf * 2.5 + min(t2, 0.9) * 3.5) * lado
                        }
                        alfa = d > 2.3 ? max(0, 1 - (d - 2.3) / 0.6) : 1
                    }
                }
                if escala > 0.02 && alfa > 0.02 {
                    var c = ctx
                    c.opacity = alfa
                    fruto(&c, em: pos, m: m, escala: escala, giro: giro)
                }
            }
        }

        if p >= 0.99 {
            for i in 0..<7 {
                let ang = Double(i) / 7 * .pi * 2 + t * 0.15
                let pos = CGPoint(x: centro.x + cos(ang) * raio * 1.7, y: centro.y + sin(ang) * raio * 1.35)
                let brilho = 0.5 + 0.5 * sin(t * 3 + Double(i) * 1.3)
                estrela(&ctx, em: pos, tamanho: m * 0.016 * (0.6 + brilho * 0.6), cor: Color.yellow.opacity(0.4 + brilho * 0.6))
            }
        }
    }

    private func pinheiro(_ ctx: inout GraphicsContext, topo: CGPoint, raio: CGFloat, m: CGFloat, t: Double) {
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

    private func fruto(_ ctx: inout GraphicsContext, em p: CGPoint, m: CGFloat, escala: CGFloat, giro: Double) {
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .radians(giro))
        c.scaleBy(x: escala, y: escala)
        let contorno = tipo.fruto.mix(with: .black, by: 0.4)
        let linha = max(0.8, m * 0.0035)
        func bago(_ centro: CGPoint, _ r: CGFloat) {
            let corpo = Path(ellipseIn: CGRect(x: centro.x - r, y: centro.y - r, width: r * 2, height: r * 2))
            c.fill(corpo, with: .radialGradient(Gradient(colors: [tipo.fruto.mix(with: .white, by: 0.4), tipo.fruto, tipo.fruto.mix(with: .black, by: 0.2)]), center: CGPoint(x: centro.x - r * 0.35, y: centro.y - r * 0.4), startRadius: 0, endRadius: r * 1.4))
            c.stroke(corpo, with: .color(contorno), lineWidth: linha)
            c.fill(Path(ellipseIn: CGRect(x: centro.x - r * 0.5, y: centro.y - r * 0.55, width: r * 0.42, height: r * 0.3)), with: .color(.white.opacity(0.75)))
        }

        switch tipo.forma {
        case .bola:
            let r = m * 0.028
            var cabo = Path()
            cabo.move(to: CGPoint(x: 0, y: -r * 0.75))
            cabo.addQuadCurve(to: CGPoint(x: r * 0.18, y: -r * 1.45), control: CGPoint(x: -r * 0.12, y: -r * 1.15))
            c.stroke(cabo, with: .color(tipo.caule), style: StrokeStyle(lineWidth: max(1, r * 0.2), lineCap: .round))
            folha(&c, em: CGPoint(x: r * 0.12, y: -r * 1.25), angulo: -0.35, tamanho: r * 1.05, cor: tipo.folha.mix(with: .white, by: 0.15))
            c.fill(Path(ellipseIn: CGRect(x: -r * 0.85, y: -r * 0.6, width: r * 2, height: r * 1.8)), with: .color(.black.opacity(0.12)))
            bago(.zero, r)
        case .uva:
            let r = m * 0.0135
            var cabo = Path()
            cabo.move(to: CGPoint(x: 0, y: -r * 1.6))
            cabo.addLine(to: CGPoint(x: r * 0.2, y: -r * 2.9))
            c.stroke(cabo, with: .color(tipo.caule), style: StrokeStyle(lineWidth: max(1, r * 0.35), lineCap: .round))
            folha(&c, em: CGPoint(x: r * 0.2, y: -r * 2.6), angulo: -0.4, tamanho: r * 2, cor: tipo.folha.mix(with: .white, by: 0.15))
            let fileiras: [(CGFloat, [CGFloat])] = [(-0.9, [-1.85, 0, 1.85]), (0.75, [-0.95, 0.95]), (2.35, [0])]
            for (y, xs) in fileiras {
                for x in xs { bago(CGPoint(x: x * r, y: y * r), r) }
            }
        case .flor:
            let r = m * 0.015
            for k in 0..<5 {
                var petala = c
                petala.rotate(by: .radians(Double(k) / 5 * .pi * 2))
                let forma = Path(ellipseIn: CGRect(x: -r * 0.7, y: -r * 2.1, width: r * 1.4, height: r * 1.9))
                petala.fill(forma, with: .linearGradient(Gradient(colors: [tipo.fruto.mix(with: .white, by: 0.45), tipo.fruto]), startPoint: CGPoint(x: 0, y: -r * 2.1), endPoint: CGPoint(x: 0, y: 0)))
                petala.stroke(forma, with: .color(contorno.opacity(0.6)), lineWidth: linha)
            }
            let miolo = Path(ellipseIn: CGRect(x: -r * 0.7, y: -r * 0.7, width: r * 1.4, height: r * 1.4))
            c.fill(miolo, with: .color(Color(red: 1, green: 0.78, blue: 0.2)))
            c.stroke(miolo, with: .color(Color(red: 0.85, green: 0.5, blue: 0.1)), lineWidth: linha)
        case .pinha:
            let r = m * 0.018
            let corpo = Path(ellipseIn: CGRect(x: -r, y: -r * 1.45, width: r * 2, height: r * 2.9))
            c.fill(Path(ellipseIn: CGRect(x: -r * 0.85, y: -r * 1.2, width: r * 2, height: r * 2.9)), with: .color(.black.opacity(0.12)))
            c.fill(corpo, with: .linearGradient(Gradient(colors: [tipo.fruto.mix(with: .white, by: 0.25), tipo.fruto.mix(with: .black, by: 0.15)]), startPoint: CGPoint(x: -r, y: -r), endPoint: CGPoint(x: r, y: r * 1.4)))
            for k in 0..<4 {
                let y = -r * 0.9 + CGFloat(k) * r * 0.65
                var escama = Path()
                escama.move(to: CGPoint(x: -r * 0.75, y: y))
                escama.addQuadCurve(to: CGPoint(x: r * 0.75, y: y), control: CGPoint(x: 0, y: y + r * 0.45))
                c.stroke(escama, with: .color(contorno.opacity(0.7)), lineWidth: linha)
            }
            c.stroke(corpo, with: .color(contorno), lineWidth: linha)
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
