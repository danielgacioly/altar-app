import SwiftUI

struct Versiculos: View {
    @EnvironmentObject var loja: Loja
    @State private var confirmar = false

    var body: some View {
        Form {
            Section {
                Text("Um destes versículos é sorteado em cada lembrete, e um fica como versículo de cada dia.")
                    .foregroundStyle(.secondary)
            }
            ForEach($loja.versiculos) { $v in
                Section {
                    HStack {
                        TextField("Referência", text: $v.referencia)
                        TextField("Versão", text: $v.versao)
                            .frame(width: 80)
                        Button {
                            loja.versiculos.removeAll { $0.id == v.id }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Apagar versículo")
                    }
                    TextField("Texto", text: $v.texto, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Versículos (\(loja.versiculos.count))")
        .toolbar {
            ToolbarItem {
                Button {
                    loja.versiculos.insert(Versiculo(referencia: "", texto: ""), at: 0)
                } label: {
                    Label("Novo versículo", systemImage: "plus")
                }
            }
            ToolbarItem {
                Button("Restaurar originais") { confirmar = true }
            }
        }
        .confirmationDialog("Trocar a lista pelos versículos que vêm com o app?", isPresented: $confirmar) {
            Button("Restaurar", role: .destructive) { loja.versiculos = Arquivos.versiculosDoApp() }
        }
    }
}
