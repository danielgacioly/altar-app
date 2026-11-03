import SwiftUI

let verde = Color.accentColor
let verdeFundo = Color("VerdeFundo")
let ptBR = Locale(identifier: "pt_BR")

enum Tela: Hashable {
    case hoje, historico, plantas, versiculos, ajustes, conta
}

struct JanelaPrincipal: View {
    @EnvironmentObject var loja: Loja
    @EnvironmentObject var lembrete: Lembrete
    @State private var tela: Tela? = .hoje
    @State private var boasVindas = false

    var body: some View {
        NavigationSplitView {
            List(selection: $tela) {
                Label("Hoje", systemImage: "sun.max").tag(Tela.hoje)
                Label("Histórico", systemImage: "calendar").tag(Tela.historico)
                Label("Plantas", systemImage: "tree").tag(Tela.plantas)
                Label("Mensagens", systemImage: "text.quote").tag(Tela.versiculos)
                Label("Ajustes", systemImage: "gearshape").tag(Tela.ajustes)
            }
            .safeAreaInset(edge: .bottom) { resumo }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 260)
        } detail: {
            switch tela ?? .hoje {
            case .hoje:
                PaginaDoDia(chave: lembrete.estado.dia)
                    .id(lembrete.estado.dia)
            case .plantas:
                Plantas()
            case .historico:
                Historico()
            case .versiculos:
                Mensagens()
            case .ajustes:
                Ajustes()
            case .conta:
                Conta()
            }
        }
        .frame(minWidth: 820, minHeight: 560)
        .environment(\.locale, ptBR)
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate()
            boasVindas = !UserDefaults.standard.bool(forKey: "boasVindasVista")
        }
        .sheet(isPresented: $boasVindas) {
            BoasVindas()
                .environmentObject(loja)
                .environmentObject(lembrete)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private var resumo: some View {
        let n = loja.sequenciaAtual(hoje: lembrete.estado.dia)
        let feito = lembrete.estado.feitoEm != nil
        let nome = loja.perfil.nome.trimmingCharacters(in: .whitespaces)
        return Button {
            tela = .conta
        } label: {
            HStack(spacing: 10) {
                Avatar(tamanho: 34)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: feito ? "checkmark.circle.fill" : "circle.dashed")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(feito ? verde : .secondary)
                            .background(Circle().fill(.background).padding(1))
                            .contentTransition(.symbolEffect(.replace))
                            .offset(x: 3, y: 3)
                    }
                    .help(feito ? "Devocional feito hoje" : "Devocional pendente hoje")
                VStack(alignment: .leading, spacing: 1) {
                    Text(nome.isEmpty ? "Minha conta" : nome)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                    Label(n == 1 ? "1 dia seguido" : "\(n) dias seguidos", systemImage: "flame.fill")
                        .labelStyle(Compacto())
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(n > 0 ? .orange : .secondary)
                        .contentTransition(.numericText(value: Double(n)))
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tela == .conta ? AnyShapeStyle(verde.opacity(0.14)) : AnyShapeStyle(.quaternary.opacity(0.5)), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(Realce(raio: 12))
        .animation(.snappy, value: n)
        .animation(.snappy, value: feito)
        .padding(10)
    }
}

struct Compacto: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

func tituloDoDia(_ chave: String) -> String {
    guard let data = dataDaChave(chave) else { return chave }
    let t = data.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(ptBR))
    return t.prefix(1).uppercased() + t.dropFirst()
}

func duracaoTexto(_ s: Double) -> String {
    let n = Int(s.rounded())
    return String(format: "%d:%02d", n / 60, n % 60)
}

struct Cartao<Conteudo: View, Acoes: View>: View {
    let titulo: String
    var preencher = false
    @ViewBuilder var conteudo: Conteudo
    @ViewBuilder var acoes: Acoes

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(titulo)
                    .font(.headline)
                Spacer()
                acoes
            }
            .frame(minHeight: 22)
            conteudo
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: preencher ? .infinity : nil, alignment: .topLeading)
        .modifier(Superficie())
    }
}

extension Cartao where Acoes == EmptyView {
    init(titulo: String, preencher: Bool = false, @ViewBuilder conteudo: () -> Conteudo) {
        self.init(titulo: titulo, preencher: preencher, conteudo: conteudo, acoes: { EmptyView() })
    }
}

struct Superficie: ViewModifier {
    var raio: CGFloat = 18
    @Environment(\.colorScheme) private var esquema

    func body(content: Content) -> some View {
        let forma = RoundedRectangle(cornerRadius: raio, style: .continuous)
        return content
            .background(.background.secondary, in: forma)
            .overlay(forma.strokeBorder(esquema == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.06), lineWidth: 1))
            .shadow(color: .black.opacity(esquema == .dark ? 0 : 0.04), radius: 10, y: 3)
    }
}

struct Realce: ButtonStyle {
    var raio: CGFloat = 10

    func makeBody(configuration: Configuration) -> some View {
        CorpoDoRealce(configuration: configuration, raio: raio)
    }
}

private struct CorpoDoRealce: View {
    let configuration: ButtonStyleConfiguration
    let raio: CGFloat
    @State private var sobre = false
    @Environment(\.isEnabled) private var ativo

    var body: some View {
        configuration.label
            .background(Color.primary.opacity(configuration.isPressed ? 0.09 : (sobre && ativo ? 0.05 : 0)), in: RoundedRectangle(cornerRadius: raio, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: sobre)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
            .onHover { sobre = $0 }
    }
}

struct Entrada: ViewModifier {
    let ordem: Int
    @State private var visivel = false
    @Environment(\.accessibilityReduceMotion) private var reduzir

    func body(content: Content) -> some View {
        content
            .opacity(visivel ? 1 : 0)
            .offset(y: visivel || reduzir ? 0 : 12)
            .onAppear {
                withAnimation(.smooth(duration: 0.45).delay(Double(ordem) * 0.06)) { visivel = true }
            }
    }
}

extension View {
    func entrada(_ ordem: Int = 0) -> some View {
        modifier(Entrada(ordem: ordem))
    }
}

struct Citacao: View {
    let versiculo: Versiculo
    var tamanho: CGFloat = 22

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(versiculo.texto.isEmpty ? "O texto da mensagem aparece aqui." : versiculo.texto)
                .font(.system(size: tamanho, design: .serif))
                .lineSpacing(tamanho * 0.25)
                .foregroundStyle(versiculo.texto.isEmpty ? .tertiary : .primary)
                .fixedSize(horizontal: false, vertical: true)
            if !versiculo.rodape.isEmpty {
                Text(versiculo.rodape)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 20)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            Capsule().fill(verde).frame(width: 3)
        }
    }
}

struct Vazio: View {
    let texto: String

    var body: some View {
        Text(texto)
            .font(.callout)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Largura: ViewModifier {
    @Binding var largura: CGFloat

    func body(content: Content) -> some View {
        content.onGeometryChange(for: CGFloat.self) { $0.size.width } action: { largura = $0 }
    }
}
