import SwiftUI
import UniformTypeIdentifiers

struct Avatar: View {
    @EnvironmentObject var loja: Loja
    var tamanho: CGFloat

    private var iniciais: String {
        loja.perfil.nome.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    var body: some View {
        ZStack {
            if let foto = loja.foto {
                Image(nsImage: foto)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(colors: [verde.mix(with: .white, by: 0.15), verde], startPoint: .top, endPoint: .bottom)
                if iniciais.isEmpty {
                    Image(systemName: "person.fill")
                        .font(.system(size: tamanho * 0.45))
                        .foregroundStyle(.white.opacity(0.9))
                } else {
                    Text(iniciais)
                        .font(.system(size: tamanho * 0.38, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: tamanho, height: tamanho)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.primary.opacity(0.08)))
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            withAnimation(.snappy) { loja.mudarFoto(url) }
            return true
        }
    }
}

func escolherFoto(_ loja: Loja) {
    let painel = NSOpenPanel()
    painel.allowedContentTypes = [.image]
    painel.message = "Escolha uma foto para a sua conta"
    guard painel.runModal() == .OK, let url = painel.url else { return }
    withAnimation(.snappy) { loja.mudarFoto(url) }
}

struct Conta: View {
    @EnvironmentObject var loja: Loja
    @EnvironmentObject var lembrete: Lembrete
    @State private var restaurarDe: URL?
    @State private var aviso: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                cabecalho.entrada(0)
                numeros.entrada(1)
                dados.entrada(2)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Minha conta")
        .confirmationDialog("Restaurar este backup?", isPresented: Binding(get: { restaurarDe != nil }, set: { if !$0 { restaurarDe = nil } })) {
            Button("Restaurar e reabrir", role: .destructive) { restaurar() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Os dados atuais vão para o Lixo e o Altar reabre com os dados do backup.")
        }
        .alert(aviso ?? "", isPresented: Binding(get: { aviso != nil }, set: { if !$0 { aviso = nil } })) {
            Button("OK") {}
        }
    }

    private var desde: String {
        guard let d = loja.primeiroDevocional else { return "Seu primeiro devocional registrado aparece aqui." }
        return "Fazendo devocional desde " + d.formatted(.dateTime.day().month(.wide).year().locale(ptBR))
    }

    private var cabecalho: some View {
        HStack(spacing: 22) {
            Avatar(tamanho: 96)
                .overlay(alignment: .bottomTrailing) {
                    Button { escolherFoto(loja) } label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 30, height: 30)
                            .glassEffect(.regular.interactive(), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Escolher foto")
                    .offset(x: 2, y: 2)
                }
                .contextMenu {
                    Button("Escolher foto…") { escolherFoto(loja) }
                    if loja.foto != nil {
                        Button("Remover foto", role: .destructive) { withAnimation(.snappy) { loja.removerFoto() } }
                    }
                }
            VStack(alignment: .leading, spacing: 6) {
                TextField("Seu nome", text: $loja.perfil.nome)
                    .textFieldStyle(.plain)
                    .font(.system(size: 30, weight: .bold))
                Text(desde)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var numeros: some View {
        let feitos = loja.feitos
        let mesAtual = String(lembrete.estado.dia.prefix(7))
        let plantas = Set(feitos.map { String($0.prefix(7)) }).subtracting([mesAtual]).count
        let notas = loja.dias.values.reduce(0) { $0 + $1.notas.count }
        let oracoes = loja.dias.values.reduce(0) { $0 + $1.oracoes.count }
        return HStack(spacing: 0) {
            Numero(valor: feitos.count, nome: "Devocionais")
                .frame(maxWidth: .infinity, alignment: .leading)
            Divider().frame(height: 40).padding(.horizontal, 18)
            Numero(valor: loja.maiorSequencia, nome: "Maior sequência")
                .frame(maxWidth: .infinity, alignment: .leading)
            Divider().frame(height: 40).padding(.horizontal, 18)
            Numero(valor: notas, nome: "Notas")
                .frame(maxWidth: .infinity, alignment: .leading)
            Divider().frame(height: 40).padding(.horizontal, 18)
            Numero(valor: oracoes, nome: "Orações")
                .frame(maxWidth: .infinity, alignment: .leading)
            Divider().frame(height: 40).padding(.horizontal, 18)
            Numero(valor: plantas, nome: "Plantas colhidas")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .modifier(Superficie())
    }

    private var dados: some View {
        Grupo(titulo: "Seus dados", rodape: "O Altar não tem servidor nem login. Para levar tudo para outro Mac, exporte um backup aqui e restaure lá.") {
            Linha("Neste Mac", "Páginas, orações, mensagens e ajustes ficam em Application Support/Altar.") {
                Button("Mostrar no Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([Arquivos.pasta])
                }
            }
            Divider().padding(.leading, 16)
            Linha("Exportar backup", "Salva tudo num arquivo .zip, inclusive os áudios das orações.") {
                Button("Exportar…", action: exportar)
            }
            Divider().padding(.leading, 16)
            Linha("Restaurar backup", "Troca os dados deste Mac pelos de um backup. Os atuais vão para o Lixo.") {
                Button("Restaurar…") {
                    let painel = NSOpenPanel()
                    painel.allowedContentTypes = [.zip]
                    guard painel.runModal() == .OK else { return }
                    restaurarDe = painel.url
                }
            }
        }
    }

    private func exportar() {
        let painel = NSSavePanel()
        painel.allowedContentTypes = [.zip]
        painel.nameFieldStringValue = "Altar backup \(chaveDoDia(Date())).zip"
        guard painel.runModal() == .OK, let url = painel.url else { return }
        do {
            try Arquivos.exportar(para: url)
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            aviso = "Não deu para salvar o backup."
        }
    }

    private func restaurar() {
        guard let url = restaurarDe else { return }
        do {
            try Arquivos.restaurar(de: url)
        } catch {
            aviso = "Esse arquivo não parece um backup do Altar."
            return
        }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = ["-c", "sleep 1; open \"\(Bundle.main.bundlePath)\" --args -abrirJanela YES"]
        try? p.run()
        NSApp.terminate(nil)
    }
}

struct BoasVindas: View {
    @EnvironmentObject var loja: Loja
    @EnvironmentObject var lembrete: Lembrete
    @Environment(\.dismiss) private var fechar
    @State private var passo = 0
    @State private var avancando = true
    @State private var icone = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Group {
                    switch passo {
                    case 0: apresentacao
                    case 1: nome
                    default: lembretes
                    }
                }
                .id(passo)
                .transition(.asymmetric(
                    insertion: .offset(x: avancando ? 40 : -40).combined(with: .opacity),
                    removal: .opacity.animation(.easeOut(duration: 0.12))
                ))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 48)
            .padding(.top, 40)
            HStack {
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i == passo ? verde : Color.primary.opacity(0.15))
                            .frame(width: i == passo ? 18 : 6, height: 6)
                    }
                }
                Spacer()
                if passo > 0 {
                    Button("Voltar") { ir(passo - 1) }
                        .controlSize(.large)
                }
                Button(passo == 2 ? "Começar" : "Continuar") {
                    if passo == 2 {
                        UserDefaults.standard.set(true, forKey: "boasVindasVista")
                        fechar()
                    } else {
                        ir(passo + 1)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(24)
            .animation(.snappy, value: passo)
        }
        .frame(width: 580, height: 560)
        .interactiveDismissDisabled()
    }

    private func ir(_ p: Int) {
        avancando = p > passo
        withAnimation(.smooth(duration: 0.4)) { passo = p }
    }

    private var apresentacao: some View {
        VStack(spacing: 26) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 92, height: 92)
                .scaleEffect(icone ? 1 : 0.6)
                .opacity(icone ? 1 : 0)
                .onAppear {
                    withAnimation(.spring(duration: 0.7, bounce: 0.4).delay(0.1)) { icone = true }
                }
            VStack(spacing: 8) {
                Text("Bem-vindo ao Altar")
                    .font(.system(size: 30, weight: .bold))
                Text("Um lembrete gentil para o dia não passar sem um tempo com Deus.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 16) {
                Recurso(simbolo: "bell.badge", titulo: "Lembretes no ritmo do seu dia", texto: "Enquanto você usa o Mac, chega uma pergunta com um versículo. Respondeu Sim, ele silencia até amanhã.")
                Recurso(simbolo: "book.pages", titulo: "Uma página para cada dia", texto: "Escreva, dite notas pelo microfone e grave suas orações.")
                Recurso(simbolo: "tree", titulo: "Uma planta por mês", texto: "Cada devocional faz a planta do mês crescer até a colheita.")
                Recurso(simbolo: "lock", titulo: "Tudo fica no seu Mac", texto: "Sem login e sem nuvem.")
            }
            .padding(.top, 4)
            Spacer(minLength: 0)
        }
    }

    private var nome: some View {
        VStack(spacing: 22) {
            Avatar(tamanho: 104)
                .overlay(alignment: .bottomTrailing) {
                    Button { escolherFoto(loja) } label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 32, height: 32)
                            .glassEffect(.regular.interactive(), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 20)
            VStack(spacing: 8) {
                Text("Como você quer ser chamado?")
                    .font(.system(size: 26, weight: .bold))
                Text("O nome e a foto ficam só neste Mac, na sua conta.")
                    .foregroundStyle(.secondary)
            }
            TextField("Seu nome", text: $loja.perfil.nome)
                .textFieldStyle(.plain)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: 320)
                .modifier(Superficie(raio: 12))
            Spacer(minLength: 0)
        }
    }

    private var lembretes: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text(loja.perfil.nome.isEmpty ? "Quase lá" : "Quase lá, \(loja.perfil.nome.split(separator: " ").first.map(String.init) ?? "")")
                    .font(.system(size: 28, weight: .bold))
                Text("O Altar fica no ícone de livro na barra de menus, no alto da tela. Por ali você abre esta janela, pausa ou sai.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: lembrete.estiloAlerta ? "checkmark.circle.fill" : "bell.and.waves.left.and.right")
                        .font(.title2)
                        .foregroundStyle(verde)
                        .frame(width: 30)
                        .contentTransition(.symbolEffect(.replace))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Deixe o lembrete na tela")
                            .font(.headline)
                        Text(lembrete.estiloAlerta ? "Pronto. A notificação fica até você responder." : "Em Notificações > Altar, escolha o estilo Alertas. Assim o lembrete não some sozinho.")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if !lembrete.estiloAlerta {
                            Button("Abrir Ajustes de Notificações") { lembrete.abrirAjustesDeNotificacao() }
                                .padding(.top, 4)
                        }
                    }
                }
                Divider()
                Recurso(simbolo: "mic", titulo: "Microfone só quando você usar", texto: "O macOS pede a permissão na primeira vez que você ditar uma nota ou gravar uma oração.")
            }
            .padding(20)
            .modifier(Superficie())
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Recurso: View {
    let simbolo: String
    let titulo: String
    let texto: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: simbolo)
                .font(.title2)
                .foregroundStyle(verde)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.headline)
                Text(texto)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
