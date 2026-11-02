import ServiceManagement
import SwiftUI

@main
struct AltarApp: App {
    @StateObject private var loja: Loja
    @StateObject private var lembrete: Lembrete

    init() {
        let l = Loja()
        _loja = StateObject(wrappedValue: l)
        _lembrete = StateObject(wrappedValue: Lembrete(loja: l))
        if Bundle.main.bundlePath.hasPrefix("/Applications/"), !UserDefaults.standard.bool(forKey: "loginConfigurado") {
            try? SMAppService.mainApp.register()
            UserDefaults.standard.set(true, forKey: "loginConfigurado")
        }
    }

    var body: some Scene {
        MenuBarExtra(nomeDoApp, image: lembrete.estado.feitoEm == nil ? "Barra" : "BarraFeito") {
            MenuDoApp()
                .environmentObject(lembrete)
        }

        Window(nomeDoApp, id: "principal") {
            JanelaPrincipal()
                .environmentObject(loja)
                .environmentObject(lembrete)
        }
        .defaultLaunchBehavior(UserDefaults.standard.bool(forKey: "abrirJanela") ? .presented : .suppressed)
        .defaultSize(width: 920, height: 680)
    }

    private var nomeDoApp: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Altar"
    }
}

struct MenuDoApp: View {
    @EnvironmentObject var lembrete: Lembrete
    @Environment(\.openWindow) private var abrirJanela

    var body: some View {
        Text(lembrete.status)
        Divider()
        Button("Abrir o Altar") {
            abrirJanela(id: "principal")
            NSApp.activate()
        }
        .keyboardShortcut("o")
        Button(lembrete.estado.pausado ? "Retomar lembretes" : "Pausar lembretes") {
            lembrete.alternarPausa()
        }
        if !lembrete.estiloAlerta {
            Button("Deixar a notificação na tela…") {
                lembrete.abrirAjustesDeNotificacao()
            }
        }
        Divider()
        Button("Sair") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
