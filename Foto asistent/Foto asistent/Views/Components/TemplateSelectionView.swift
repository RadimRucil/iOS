import SwiftUI

struct TemplateSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let onTemplateSelected: (OrderTemplate) -> Void
    
    private let templates = OrderTemplate.defaultTemplates
    
    var body: some View {
        NavigationView {
            List {
                Section("Přednastavené šablony") {
                    ForEach(templates) { template in
                        Button(action: {
                            onTemplateSelected(template)
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("\(Int(template.price)) Kč")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                        
                                        if template.deposit > 0 {
                                            Text("Záloha: \(Int(template.deposit)) Kč")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                
                                Text(template.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
                                Text("Délka: \(formatDuration(template.duration))")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Šablony zakázek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zrušit") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 && remainingMinutes > 0 {
            return "\(hours)h \(remainingMinutes)min"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)min"
        }
    }
}
