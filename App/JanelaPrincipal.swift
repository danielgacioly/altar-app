import SwiftUI

let verde = Color.accentColor
let verdeFundo = Color("VerdeFundo")
let ptBR = Locale(identifier: "pt_BR")

enum Tela: Hashable {
    case hoje, historico, videira, versiculos, ajustes
}

struct JanelaPrincipal: View {
    @EnvironmentObject var loja: Loja
    @EnvironmentObject var lembrete: Lembrete
    @State private var tela: Tela? = .hoje

    var body: some View {
        NavigationSplitView {
            List(selection: $tela) {
                Label("Hoje", systemImage: "sun.max").tag(Tela.hoje)
                Label("Histórico", systemImage: "calendar").tag(Tela.historico)
                Label("Videira", systemImage: "leaf").tag(Tela.videira)
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
            case .videira:
                Videira()
            case .historico:
                Historico()
            case .versiculos:
                Mensagens()
            case .ajustes:
                Ajustes()
            }
        }
        .frame(minWidth: 820, minHeight: 560)
        .environment(\.locale, ptBR)
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate()
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private var resumo: some View {
        let n = loja.sequenciaAtual(hoje: lembrete.estado.dia)
        let feito = lembrete.estado.feitoEm != nil
        return VStack(alignment: .leading, spacing: 6) {
            Label(n == 1 ? "1 dia seguido" : "\(n) dias seguidos", systemImage: "flame.fill")
                .foregroundStyle(n > 0 ? .orange : .secondary)
                .font(.callout.weight(.semibold))
            Label(feito ? "Feito hoje" : "Pendente hoje", systemImage: feito ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(feito ? verde : .secondary)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
        .padding(10)
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
    let icone: String
    var preencher = false
    @ViewBuilder var conteudo: Conteudo
    @ViewBuilder var acoes: Acoes

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label {
                    Text(titulo)
                } icon: {
                    Image(systemName: icone).foregroundStyle(verde)
                }
                .font(.headline)
                Spacer()
                acoes
            }
            conteudo
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: preencher ? .infinity : nil, alignment: .topLeading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.separator.opacity(0.6)))
    }
}

extension Cartao where Acoes == EmptyView {
    init(titulo: String, icone: String, preencher: Bool = false, @ViewBuilder conteudo: () -> Conteudo) {
        self.init(titulo: titulo, icone: icone, preencher: preencher, conteudo: conteudo, acoes: { EmptyView() })
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
