import SwiftUI

struct ContentView: View {
    @State private var currentScreen = 0
    
    var body: some View {
        ZStack {
            if currentScreen < 3 {
                OnboardingScreen(
                    screenIndex: currentScreen,
                    onNext: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen += 1
                        }
                    }
                )
            } else {
                WidgetInstructionView()
            }
        }
    }
}

struct OnboardingScreen: View {
    let screenIndex: Int
    let onNext: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Icon
                    Image(systemName: iconName)
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Text content
                    VStack(spacing: 20) {
                        Text(titleText)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .lineLimit(nil)
                    }
                    
                    Spacer()
                    
                    // Button
                    Button(action: onNext) {
                        Text(buttonText)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(buttonTextColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(buttonBackgroundColor)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
        }
    }
    
    private var backgroundGradient: Gradient {
        switch screenIndex {
        case 0:
            return Gradient(colors: [
                Color(red: 0.58, green: 0.4, blue: 0.9),
                Color(red: 0.9, green: 0.5, blue: 0.8)
            ])
        case 1:
            return Gradient(colors: [
                Color(red: 0.9, green: 0.4, blue: 0.6),
                Color(red: 0.4, green: 0.3, blue: 0.8)
            ])
        case 2:
            return Gradient(colors: [
                Color(red: 0.9, green: 0.5, blue: 0.6),
                Color(red: 0.3, green: 0.4, blue: 0.9)
            ])
        default:
            return Gradient(colors: [Color.blue, Color.purple])
        }
    }
    
    private var iconName: String {
        switch screenIndex {
        case 0: return "fork.knife"
        case 1: return "heart.fill"
        case 2: return "clock"
        default: return "questionmark"
        }
    }
    
    private var titleText: String {
        switch screenIndex {
        case 0: return "It may seem strange, but eating six times a day can actually help you feel more in control."
        case 1: return "Regular meals keep your hunger levels steady, so cravings don't take over."
        case 2: return "Over time, this builds trust with your body and brings calm to how you eat."
        default: return ""
        }
    }
    
    private var buttonText: String {
        screenIndex == 2 ? "Start" : "Next"
    }
    
    private var buttonBackgroundColor: Color {
        Color.white.opacity(0.9)
    }
    
    private var buttonTextColor: Color {
        Color.primary
    }
}

struct WidgetInstructionView: View {
    @State private var showBottomSheet = false
    
    var body: some View {
        ZStack {
            // Background image (contains the phone mockup)
            Image("BackgroundImage")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header text
                VStack(spacing: 4) {
                    Text("Add the widget")
                        .font(.title2)
                        .fontWeight(.regular)
                        .foregroundColor(.white)
                    
                    Text("to your homepage")
                        .font(.title2)
                        .fontWeight(.regular)
                        .foregroundColor(.white)
                }
                .padding(.top, 68)
                
                Spacer()
                
                // Features list positioned at bottom
                VStack(alignment: .leading, spacing: 12) {
                    FeatureItem(text: "No streaks")
                    FeatureItem(text: "No calories")
                    FeatureItem(text: "No nonsense")
                }
                .padding(.bottom, 40)
                
                // How button
                Button(action: {
                    showBottomSheet = true
                }) {
                    Text("How?")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 35)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showBottomSheet) {
            BottomSheetView()
        }
    }
}



struct FeatureItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
                .font(.title3)
            
            Text(text)
                .font(.title3)
                .fontWeight(.regular)
                .foregroundColor(.white)
        }
    }
}

struct BottomSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black)
                .frame(width: 154, height: 4)
                .padding(.top, 28)
            
            Spacer().frame(height: 60)
            
            // Title
            Text("How to add the widget")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.black)
                .padding(.bottom, 40)
            
            // Instructions list
            VStack(alignment: .leading, spacing: 20) {
                InstructionItem(number: 1, text: "Long press on your home screen")
                InstructionItem(number: 2, text: "Tap the + button in the top left")
                InstructionItem(number: 3, text: "Search for SixEats in the widget gallery")
                InstructionItem(number: 4, text: "Tap 'Add Widget' and position it on your home screen")
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color.white)
        .cornerRadius(40, corners: [.topLeft, .topRight])
    }
}

struct InstructionItem: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(number).")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.black)
                .frame(width: 20, alignment: .leading)
            
            Text(text)
                .font(.title3)
                .fontWeight(.regular)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

// Extension for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}



#Preview {
    ContentView()
}
