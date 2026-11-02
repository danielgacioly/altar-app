import SwiftUI

let verde = Color(red: 0, green: 0x72 / 255.0, blue: 0x3b / 255.0)
let ptBR = Locale(identifier: "pt_BR")

enum Tela: Hashable {
    case hoje, historico, versiculos, ajustes
}

struct JanelaPrincipal: View {
    @EnvironmentObject var lembrete: Lembrete
    @State private var tela: Tela? = .hoje

    var body: some View {
        NavigationSplitView {
            List(selection: $tela) {
                Label("Hoje", systemImage: "sun.max").tag(Tela.hoje)
                Label("Histórico", systemImage: "calendar").tag(Tela.historico)
                Label("Versículos", systemImage: "book").tag(Tela.versiculos)
                Label("Ajustes", systemImage: "gearshape").tag(Tela.ajustes)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            switch tela ?? .hoje {
            case .hoje:
                PaginaDoDia(chave: lembrete.estado.dia)
                    .id(lembrete.estado.dia)
            case .historico:
                Historico()
            case .versiculos:
                Versiculos()
            case .ajustes:
                Ajustes()
            }
        }
        .tint(verde)
        .frame(minWidth: 780, minHeight: 540)
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

struct Cartao<Conteudo: View>: View {
    let titulo: String
    @ViewBuilder var conteudo: Conteudo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titulo)
                .font(.headline)
                .foregroundStyle(verde)
            conteudo
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}
