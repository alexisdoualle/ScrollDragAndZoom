//
//  ContentView.swift
//  ScrollDragAndZoom
//
//  Created by Alexis Doualle on 08/05/2024.
//

import SwiftUI
import UIKit  // Import UIKit to use haptic feedback


struct ItemView: View {
    let index: Int
    @ObservedObject var model: DragStateModel
    @GestureState private var dragState = CGSize.zero  // Local drag state for ongoing gesture

    var body: some View {
        let longPressThenDrag = LongPressGesture(minimumDuration: 0.1)
            .sequenced(before: DragGesture())
            .updating($dragState) { value, state, transaction in
                print(value, state, transaction)
                switch value {
//                case .first(true):
                case .second(true, let drag):
                    state = drag?.translation ?? .zero
                    DispatchQueue.main.async {
                        if !(self.model.isPressing[index] ?? false) {
                            self.triggerHapticFeedback()
                        }
                        
                        self.model.isPressing[index] = true
                        
                    }
                default:
                    break
                }
            }
            .onEnded { value in
                DispatchQueue.main.async {
                    self.model.isPressing[index] = false
                }
                switch value {
                case .second(true, let drag):
                    // Combine new drag translation with existing state
                    let existingTranslation = self.model.dragStates[index] ?? .zero
                    self.model.dragStates[index] = CGSize(width: existingTranslation.width + (drag?.translation.width ?? 0),
                                                          height: existingTranslation.height + (drag?.translation.height ?? 0))
                default:
                    break
                }
            }

        return Text("Item \(index)")
            .frame(width: 100, height: 100)
            .background(self.model.isPressing[index] ?? false ? Color.red : Color.blue)
            .cornerRadius(10)
            .offset(x: (model.dragStates[index]?.width ?? 0) + dragState.width,
                    y: (model.dragStates[index]?.height ?? 0) + dragState.height)
//            .allowsHitTesting(/*@START_MENU_TOKEN@*/false/*@END_MENU_TOKEN@*/)
//            .onTapGesture {} // Fixes scrolling
            .delaysTouches(for: 0.1) {}
            .gesture(longPressThenDrag)
    }
    
    // Function to trigger haptic feedback
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}

class DragStateModel: ObservableObject {
    @Published var dragStates = [Int: CGSize]()
    @Published var isPressing = [Int: Bool]()
}

struct ContentView: View {
    @StateObject private var model = DragStateModel()
    let itemCount = 30

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack {
                ForEach(0..<itemCount, id: \.self) { index in
                    ItemView(index: index, model: model)
                        .frame(width: 200, height: 600)
                        .padding()
                }
                .border(.white)
            }
        }
    }
}


extension View {
    func delaysTouches(for duration: TimeInterval = 0.25, action: @escaping () -> Void = {}) -> some View {
        modifier(DelaysTouches(duration: duration, action: action))
    }
}

fileprivate struct DelaysTouches: ViewModifier {
    @State private var disabled = false
    private let duration: TimeInterval
    private let action: () -> Void

    init(duration: TimeInterval, action: @escaping () -> Void) {
        self.duration = duration
        self.action = action
    }

    func body(content: Content) -> some View {
        Button(action: action) {
            content
        }
        .buttonStyle(DelaysTouchesButtonStyle(
            disabled: $disabled,
            duration: duration
        ))
        .disabled(disabled)
    }
}

fileprivate struct DelaysTouchesButtonStyle: ButtonStyle {
    @Binding private var disabled: Bool
    @State private var touchDownDate: Date?
    private let duration: TimeInterval

    init(disabled: Binding<Bool>, duration: TimeInterval) {
        _disabled = disabled
        self.duration = duration
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                handleIsPressed(isPressed: isPressed)
            }
    }

    private func handleIsPressed(isPressed: Bool) {
        if isPressed {
            let date = Date()
            touchDownDate = date

            DispatchQueue.main.asyncAfter(deadline: .now() + max(duration, 0)) {
                if date == touchDownDate {
                    disabled = true

                    DispatchQueue.main.async {
                        disabled = false
                    }
                }
            }
        } else {
            touchDownDate = nil
            disabled = false
        }
    }
}


#Preview {
    ContentView()
}
