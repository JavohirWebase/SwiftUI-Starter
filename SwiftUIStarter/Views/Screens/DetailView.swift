import SwiftUI

struct DetailView: View {
    let id: String
    
    var body: some View {
        Text("Detail: \(id)")
            .navigationTitle("Detail")
    }
}
