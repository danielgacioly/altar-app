import XCTest

final class ConfigTests: XCTestCase {
    private let config = Config()

    private func data(_ dia: Int, _ hora: Int, _ minuto: Int = 0, mes: Int = 11) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: mes, day: dia, hour: hora, minute: minuto))!
    }

    func testDiaViraAsDuasDaManha() {
        XCTAssertEqual(config.diaLogico(data(3, 1, 59)), "2026-11-02")
        XCTAssertEqual(config.diaLogico(data(3, 2)), "2026-11-03")
    }

    func testFaixaDeCadaHorario() {
        XCTAssertEqual(config.faixa(em: data(2, 0, 30))?.nome, "Antes de dormir")
        XCTAssertEqual(config.faixa(em: data(2, 7))?.nome, "Começo do dia")
        XCTAssertEqual(config.faixa(em: data(2, 12, 59))?.nome, "Antes do almoço")
        XCTAssertEqual(config.faixa(em: data(2, 16))?.nome, "Antes da faculdade")
        XCTAssertEqual(config.faixa(em: data(2, 23, 59))?.nome, "Encerramento")
    }

    func testSemLembretesDasDuasAsSete() {
        XCTAssertFalse(config.silencioso(data(2, 1, 59)))
        XCTAssertTrue(config.silencioso(data(2, 2)))
        XCTAssertTrue(config.silencioso(data(2, 6, 59)))
        XCTAssertFalse(config.silencioso(data(2, 7)))
    }

    func testIntervaloQuePassaDaMeiaNoite() {
        XCTAssertTrue(dentro(30, 22 * 60, 60))
        XCTAssertTrue(dentro(23 * 60, 22 * 60, 60))
        XCTAssertFalse(dentro(12 * 60, 22 * 60, 60))
    }

    func testBotaoDaFaculdade() {
        let segundaDeManha = config.extrasAtivos(em: data(2, 10))
        XCTAssertEqual(segundaDeManha.first?.0.nome, "Estou na faculdade")
        XCTAssertEqual(segundaDeManha.first?.1, data(2, 12))
        XCTAssertTrue(config.extrasAtivos(em: data(3, 10)).isEmpty)
        XCTAssertEqual(config.extrasAtivos(em: data(3, 18)).first?.1, data(3, 21))
        XCTAssertTrue(config.extrasAtivos(em: data(6, 18)).isEmpty)
        XCTAssertTrue(config.extrasAtivos(em: data(2, 21)).isEmpty)
    }

    func testProximaVirada() {
        XCTAssertEqual(config.proximaVirada(depois: data(2, 23)), data(3, 2))
        XCTAssertEqual(config.proximaVirada(depois: data(3, 1)), data(3, 2))
    }

    func testAjustesIncompletosVoltamAoPadrao() throws {
        let vazio = try JSONDecoder().decode(Config.self, from: Data("{}".utf8))
        XCTAssertEqual(vazio, Config())
        let parcial = try JSONDecoder().decode(Config.self, from: Data(#"{"minutosEntreLembretes": 45}"#.utf8))
        XCTAssertEqual(parcial.minutosEntreLembretes, 45)
        XCTAssertEqual(parcial.minutosAdiar, 15)
        XCTAssertEqual(parcial.faixas.count, 7)
    }

    func testTextos() {
        XCTAssertEqual(textoHora(65), "01:05")
        XCTAssertEqual(chaveDoDia(dataDaChave("2026-11-02")!), "2026-11-02")
    }
}

final class ArquivosTests: XCTestCase {
    func testDiaAntigoSemCamposNovos() throws {
        let dia = try Arquivos.decodificador().decode(Dia.self, from: Data(#"{"id": "2026-11-02"}"#.utf8))
        XCTAssertEqual(dia.id, "2026-11-02")
        XCTAssertNil(dia.feitoEm)
        XCTAssertTrue(dia.notas.isEmpty)
        XCTAssertFalse(dia.temConteudo)
    }

    func testPerfilVazio() throws {
        XCTAssertEqual(try JSONDecoder().decode(Perfil.self, from: Data("{}".utf8)).nome, "")
    }

    func testIdaEVoltaDoDia() throws {
        var dia = Dia(id: "2026-11-02", versiculo: Versiculo(referencia: "Salmos 90:14", texto: "Sacia-nos"))
        dia.feitoEm = Date(timeIntervalSince1970: 1_793_600_000)
        dia.notas = [Nota(texto: "Oração: obrigado")]
        let volta = try Arquivos.decodificador().decode(Dia.self, from: Arquivos.codificador().encode(dia))
        XCTAssertEqual(volta.feitoEm, dia.feitoEm)
        XCTAssertEqual(volta.notas.first?.texto, "Oração: obrigado")
        XCTAssertEqual(volta.versiculo?.rodape, "Salmos 90:14 · ARC")
    }
}

final class SequenciaTests: XCTestCase {
    func testSequenciaAtual() {
        let feitos: Set = ["2026-10-31", "2026-11-01", "2026-11-02"]
        XCTAssertEqual(contarSequencia(feitos, ate: "2026-11-02"), 3)
        XCTAssertEqual(contarSequencia(feitos, ate: "2026-11-03"), 3)
        XCTAssertEqual(contarSequencia(feitos, ate: "2026-11-04"), 0)
        XCTAssertEqual(contarSequencia([], ate: "2026-11-02"), 0)
    }

    func testMaiorSequencia() {
        XCTAssertEqual(contarMaiorSequencia(["2026-10-30", "2026-10-31", "2026-11-01", "2026-11-05", "2026-11-06"]), 3)
        XCTAssertEqual(contarMaiorSequencia(["2026-02-28", "2026-03-01"]), 2)
        XCTAssertEqual(contarMaiorSequencia([]), 0)
    }
}

final class PlantasTests: XCTestCase {
    func testUmaArvoreDiferentePorMes() {
        XCTAssertEqual(Arvore.doAno.count, 12)
        XCTAssertEqual(Set(Arvore.doAno.map(\.nome)).count, 12)
        XCTAssertEqual(Arvore.doAno.map(\.id), Array(1...12))
        XCTAssertEqual(Arvore.doMes(6).nome, "Flamboyant")
        XCTAssertEqual(Arvore.doMes(7).nome, "Araucária")
        XCTAssertEqual(Arvore.doMes(12).nome, "Pinheiro")
    }
}
