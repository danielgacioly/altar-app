import AppKit
import Combine
import IOKit
import UserNotifications

final class Lembrete: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published private(set) var estado: Estado
    @Published private(set) var estiloAlerta = true

    let loja: Loja
    private let central = UNUserNotificationCenter.current()
    private let minuto: Double
    private var timer: Timer?
    private var ultimoTique = Date()
    private var bloqueado = false
    private var dormindo = false
    private var observando: AnyCancellable?

    init(loja: Loja) {
        self.loja = loja
        estado = Arquivos.ler(Estado.self, de: Arquivos.estadoURL) ?? Estado()
        let teste = UserDefaults.standard.double(forKey: "segundosPorMinuto")
        minuto = teste > 0 ? teste : 60
        super.init()

        central.delegate = self
        registrarCategorias(loja.config)
        observando = loja.$config.dropFirst().sink { [weak self] c in self?.registrarCategorias(c) }
        central.requestAuthorization(options: [.alert]) { _, _ in
            self.conferirEstilo()
            if UserDefaults.standard.bool(forKey: "notificacaoDeTeste") {
                DispatchQueue.main.async { self.notificarTeste() }
            }
        }
        observarSistema()
        virarDiaSePreciso(Date())

        let t = Timer(timeInterval: min(60, minuto), repeats: true) { [weak self] _ in self?.tique() }
        t.tolerance = min(15, minuto / 4)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private var config: Config { loja.config }

    var status: String {
        let agora = Date()
        if let feito = estado.feitoEm {
            return "Devocional feito às \(horaTexto(feito))"
        }
        if estado.pausado { return "Lembretes pausados" }
        if config.silencioso(agora) { return "Sem lembretes até as \(textoHora(config.fimSilencio))" }
        if let ate = estado.silencioAte, ate > agora { return "Silenciado até \(horaTexto(ate))" }
        if estado.aguardando != nil { return "Esperando sua resposta" }
        let faltam = max(0, Int(((alvo - estado.segundosAtivos) / minuto).rounded(.up)))
        return "Próximo lembrete em \(faltam) min de uso"
    }

    private var alvo: Double {
        estado.alvoMinutos * minuto
    }

    func alternarPausa() {
        estado.pausado.toggle()
        ultimoTique = Date()
        salvar()
    }

    func marcarFeito(_ chave: String, em data: Date?) {
        loja.mudar(chave) { $0.feitoEm = data }
        guard chave == estado.dia else { return }
        estado.feitoEm = data
        if data != nil {
            if let id = estado.aguardando {
                central.removeDeliveredNotifications(withIdentifiers: [id])
            }
            estado.aguardando = nil
            estado.aguardandoDesde = nil
            registrar("sim-no-app")
        } else {
            estado.segundosAtivos = 0
            estado.alvoMinutos = Double(config.minutosEntreLembretes)
        }
        salvar()
    }

    func abrirAjustesDeNotificacao() {
        let id = Bundle.main.bundleIdentifier ?? ""
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(id)") {
            NSWorkspace.shared.open(url)
        }
    }

    private func tique() {
        let agora = Date()
        let passou = min(agora.timeIntervalSince(ultimoTique), min(60, minuto) * 1.5)
        ultimoTique = agora

        virarDiaSePreciso(agora)
        conferirEstilo()

        if estado.feitoEm != nil || estado.pausado || bloqueado || dormindo || config.silencioso(agora) { return }
        if let ate = estado.silencioAte {
            if ate > agora { return }
            estado.silencioAte = nil
            salvar()
        }
        if estado.aguardando != nil {
            conferirSeSumiu(agora)
            return
        }

        if segundosOcioso() < Double(config.minutosOcioso * 60) {
            estado.segundosAtivos += passou
            if estado.segundosAtivos >= alvo {
                notificar(agora)
            }
            salvar()
        }
    }

    private func notificar(_ agora: Date) {
        guard let faixa = config.faixa(em: agora), !faixa.frases.isEmpty else { return }
        let opcoes = faixa.frases.filter { $0 != estado.ultimaFrase }
        let frase = opcoes.randomElement() ?? faixa.frases[0]
        let versiculo = loja.versiculos.randomElement()

        let conteudo = UNMutableNotificationContent()
        conteudo.title = frase
        if let v = versiculo {
            conteudo.body = "\(v.texto)\n\(v.referencia)"
        }
        conteudo.categoryIdentifier = "lembrete"
        if let (extra, fim) = config.extrasAtivos(em: agora).first {
            conteudo.categoryIdentifier = "extra-" + extra.id.uuidString
            conteudo.userInfo = ["fim": fim.timeIntervalSince1970]
        }

        let id = UUID().uuidString
        estado.aguardando = id
        estado.aguardandoDesde = agora
        estado.ultimaFrase = frase
        estado.segundosAtivos = 0
        central.add(UNNotificationRequest(identifier: id, content: conteudo, trigger: nil))
        registrar("exibida", versiculo: versiculo?.referencia)
    }

    func notificarTeste() {
        let faixa = config.faixa(em: Date()) ?? config.faixas.first
        let conteudo = UNMutableNotificationContent()
        conteudo.title = faixa?.frases.randomElement() ?? "Já fez o devocional hoje?"
        if let v = loja.versiculos.randomElement() {
            conteudo.body = "\(v.texto)\n\(v.referencia)"
        }
        conteudo.categoryIdentifier = "lembrete"
        central.add(UNNotificationRequest(identifier: "teste-" + UUID().uuidString, content: conteudo, trigger: nil))
    }

    private func responder(_ acao: String, id: String, fim: Date?) {
        if id.hasPrefix("teste-") { return }
        guard id == estado.aguardando else {
            registrar(acao + "-antiga")
            return
        }
        let agora = Date()
        estado.aguardando = nil
        estado.aguardandoDesde = nil
        estado.segundosAtivos = 0
        estado.alvoMinutos = Double(config.minutosEntreLembretes)
        ultimoTique = agora

        var tipo = acao
        if acao == "sim" {
            estado.feitoEm = agora
            loja.mudar(estado.dia) { $0.feitoEm = agora }
        } else if acao == "adiar" {
            estado.alvoMinutos = Double(config.minutosAdiar)
        } else if acao.hasPrefix("extra:"), let extra = config.extras.first(where: { "extra:" + $0.id.uuidString == acao }) {
            tipo = "extra:" + extra.nome
            switch extra.efeito {
            case .ateFimDoHorario: estado.silencioAte = fim
            case .porMinutos: estado.silencioAte = agora.addingTimeInterval(Double(extra.minutos) * minuto)
            case .ateVirarODia: estado.silencioAte = config.proximaVirada(depois: agora)
            }
        }
        registrar(tipo)
        salvar()
    }

    private func conferirSeSumiu(_ agora: Date) {
        guard let id = estado.aguardando,
              let desde = estado.aguardandoDesde,
              agora.timeIntervalSince(desde) > 120 else { return }
        central.getDeliveredNotifications { entregues in
            guard !entregues.contains(where: { $0.request.identifier == id }) else { return }
            DispatchQueue.main.async {
                self.responder("sumiu", id: id, fim: nil)
            }
        }
    }

    private func virarDiaSePreciso(_ agora: Date) {
        let hoje = config.diaLogico(agora)
        guard estado.dia != hoje else { return }
        if let id = estado.aguardando {
            central.removeDeliveredNotifications(withIdentifiers: [id])
        }
        let pausado = estado.pausado
        let ultima = estado.ultimaFrase
        estado = Estado()
        estado.dia = hoje
        estado.pausado = pausado
        estado.ultimaFrase = ultima
        estado.alvoMinutos = Double(config.minutosEntreLembretes)
        estado.feitoEm = loja.dias[hoje]?.feitoEm
        if loja.dias[hoje] == nil {
            loja.salvar(loja.dia(hoje))
        }
        salvar()
    }

    private func registrarCategorias(_ c: Config) {
        let sim = UNNotificationAction(identifier: "sim", title: "Sim")
        let nao = UNNotificationAction(identifier: "nao", title: "Não")
        let adiar = UNNotificationAction(identifier: "adiar", title: "Me lembra em \(c.minutosAdiar) min")
        var categorias: Set<UNNotificationCategory> = [
            UNNotificationCategory(identifier: "lembrete", actions: [sim, nao, adiar], intentIdentifiers: [], options: [.customDismissAction])
        ]
        for extra in c.extras where !extra.nome.isEmpty {
            let botao = UNNotificationAction(identifier: "extra:" + extra.id.uuidString, title: extra.nome)
            categorias.insert(UNNotificationCategory(identifier: "extra-" + extra.id.uuidString, actions: [sim, nao, adiar, botao], intentIdentifiers: [], options: [.customDismissAction]))
        }
        central.setNotificationCategories(categorias)
    }

    private func conferirEstilo() {
        central.getNotificationSettings { ajustes in
            let ok = ajustes.alertStyle == .alert
            DispatchQueue.main.async {
                if self.estiloAlerta != ok { self.estiloAlerta = ok }
            }
        }
    }

    private func observarSistema() {
        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.dormindo = true
        }
        ws.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.dormindo = false
            self?.ultimoTique = Date()
        }
        ws.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.bloqueado = true
        }
        ws.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.bloqueado = false
            self?.ultimoTique = Date()
        }
        let dn = DistributedNotificationCenter.default()
        dn.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
            self?.bloqueado = true
        }
        dn.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            self?.bloqueado = false
            self?.ultimoTique = Date()
        }
    }

    private func segundosOcioso() -> Double {
        var iterador: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"), &iterador) == KERN_SUCCESS else { return 0 }
        defer { IOObjectRelease(iterador) }
        let entrada = IOIteratorNext(iterador)
        guard entrada != 0 else { return 0 }
        defer { IOObjectRelease(entrada) }
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(entrada, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dic = props?.takeRetainedValue() as? [String: Any],
              let ns = dic["HIDIdleTime"] as? NSNumber else { return 0 }
        return ns.doubleValue / 1_000_000_000
    }

    private func registrar(_ tipo: String, versiculo: String? = nil) {
        let agora = Date()
        loja.registrar(Evento(data: agora, dia: config.diaLogico(agora), faixa: config.faixa(em: agora)?.nome, tipo: tipo, versiculo: versiculo))
    }

    private func salvar() {
        Arquivos.gravar(estado, em: Arquivos.estadoURL)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = response.notification.request.identifier
        let info = response.notification.request.content.userInfo
        let fim = (info["fim"] as? Double).map { Date(timeIntervalSince1970: $0) }
        let acao: String
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier: acao = "dispensada"
        case UNNotificationDefaultActionIdentifier: acao = "clicou"
        default: acao = response.actionIdentifier
        }
        DispatchQueue.main.async {
            self.responder(acao, id: id, fim: fim)
            completionHandler()
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list])
    }
}
