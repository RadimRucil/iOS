import Foundation

struct OrderTemplate: Identifiable, Codable, Hashable, Equatable {
    let id = UUID()
    var name: String
    var duration: Int // v minutách
    var price: Double
    var deposit: Double
    var description: String
    
    static let defaultTemplates = [
        OrderTemplate(name: "Celodenní svatba", duration: 720, price: 18000, deposit: 2000, description: "Kompletní svatební focení od příprav po večerní zábavu"),
        OrderTemplate(name: "Půldenní svatba", duration: 360, price: 14000, deposit: 2000, description: "Svatební focení obřad + oslavy"),
        OrderTemplate(name: "Portrétní focení", duration: 120, price: 5000, deposit: 0, description: "Individuální portrétní focení"),
        OrderTemplate(name: "Rodinné focení", duration: 90, price: 3500, deposit: 0, description: "Rodinné focení v exteriéru"),
        OrderTemplate(name: "Firemní akce", duration: 240, price: 8000, deposit: 1000, description: "Firemní event a teambuilding")
    ]
}
