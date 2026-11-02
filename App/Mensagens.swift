import SwiftUI

struct Mensagens: View {
    @EnvironmentObject var loja: Loja
    @State private var selecionado: UUID?
    @State private var busca = ""
    @State private var confirmar = false

    private var filtrados: [Versiculo] {
        guard !busca.isEmpty else { return loja.versiculos }
        return loja.versiculos.filter {
            $0.referencia.localizedCaseInsensitiveContains(busca) || $0.texto.localizedCaseInsensitiveContains(busca)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            List(selection: $selecionado) {
                ForEach(filtrados) { v in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(v.referencia.isEmpty ? "Sem autor ou referência" : v.referencia)
                            .font(.headline)
                            .foregroundStyle(v.referencia.isEmpty ? .secondary : .primary)
                        Text(v.texto.isEmpty ? "Sem texto" : v.texto)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                    .tag(v.id)
                    .contextMenu {
                        Button("Apagar", role: .destructive) {
                            loja.versiculos.removeAll { $0.id == v.id }
                            if selecionado == v.id { selecionado = nil }
                        }
                    }
                }
            }
            .frame(minWidth: 260, idealWidth: 320, maxWidth: 380)
            .searchable(text: $busca, placement: .sidebar, prompt: "Buscar mensagem")

            Divider()

            if let id = selecionado, let i = loja.versiculos.firstIndex(where: { $0.id == id }) {
                EditorDeMensagem(versiculo: $loja.versiculos[i])
            } else {
                ContentUnavailableView("Escolha uma mensagem", systemImage: "text.quote", description: Text("Versículos, citações ou mensagens. Uma delas é sorteada em cada lembrete, e outra aparece como mensagem do dia na tela Hoje."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Mensagens")
        .navigationSubtitle("\(loja.versiculos.count) na lista")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    let novo = Versiculo(referencia: "", texto: "")
                    loja.versiculos.insert(novo, at: 0)
                    busca = ""
                    selecionado = novo.id
                } label: {
                    Label("Nova mensagem", systemImage: "plus")
                }
                .help("Nova mensagem")
                Button {
                    if let id = selecionado {
                        loja.versiculos.removeAll { $0.id == id }
                        selecionado = nil
                    }
                } label: {
                    Label("Apagar", systemImage: "trash")
                }
                .disabled(selecionado == nil)
                .help("Apagar a mensagem escolhida")
                Menu {
                    Button("Restaurar as mensagens originais…") { confirmar = true }
                } label: {
                    Label("Mais", systemImage: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("Trocar a lista pelas mensagens que vêm com o app?", isPresented: $confirmar) {
            Button("Restaurar", role: .destructive) {
                loja.versiculos = Arquivos.versiculosDoApp()
                selecionado = nil
            }
        }
    }
}

struct EditorDeMensagem: View {
    @Binding var versiculo: Versiculo

    var body: some View {
        Form {
            Section {
                TextField("Autor ou referência", text: $versiculo.referencia, prompt: Text("Ex.: Salmos 119:105 ou C. S. Lewis"))
                TextField("Detalhe (opcional)", text: $versiculo.versao, prompt: Text("Ex.: ARC"))
            }
            Section("Texto") {
                TextEditor(text: $versiculo.texto)
                    .font(.system(.title3, design: .serif))
                    .lineSpacing(3)
                    .frame(minHeight: 160)
                    .scrollContentBackground(.hidden)
            }
            Section("Como aparece") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(versiculo.texto.isEmpty ? "O texto da mensagem aparece aqui." : versiculo.texto)
                        .font(.system(.body, design: .serif))
                    Text(versiculo.rodape)
                        .font(.caption.weight(.semibold))
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(verdeFundo, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity)
    }
}
