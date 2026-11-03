import Foundation

func contarSequencia(_ feitos: Set<String>, ate hoje: String) -> Int {
    let cal = Calendar.current
    guard var data = dataDaChave(hoje) else { return 0 }
    if !feitos.contains(hoje) {
        data = cal.date(byAdding: .day, value: -1, to: data) ?? data
    }
    var n = 0
    while feitos.contains(chaveDoDia(data)) {
        n += 1
        data = cal.date(byAdding: .day, value: -1, to: data) ?? data
    }
    return n
}

func contarMaiorSequencia(_ feitos: Set<String>) -> Int {
    let cal = Calendar.current
    var maior = 0
    var atual = 0
    var anterior: Date?
    for d in feitos.compactMap(dataDaChave).sorted() {
        if let a = anterior, let seguinte = cal.date(byAdding: .day, value: 1, to: a), cal.isDate(seguinte, inSameDayAs: d) {
            atual += 1
        } else {
            atual = 1
        }
        maior = max(maior, atual)
        anterior = d
    }
    return maior
}
