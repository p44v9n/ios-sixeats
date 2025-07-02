import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "widget.large.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Add the widget...")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                InstructionStep(number: "1", text: "Long press on your home screen")
                InstructionStep(number: "2", text: "Tap the + button in the top left")
                InstructionStep(number: "3", text: "Search for SixEats in the widget gallery")
                InstructionStep(number: "5", text: "Tap 'Add Widget' and position it on your home screen")
            }
            .padding(8)
            
            Text("Your widget is now ready to use!")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct InstructionStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.blue))
            
            Text(text)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
