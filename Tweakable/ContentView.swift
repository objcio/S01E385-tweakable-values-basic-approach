//

import SwiftUI

struct TweakablePreference: PreferenceKey {
    static var defaultValue: [String:CGFloat] = [:]
    static func reduce(value: inout [String : CGFloat], nextValue: () -> [String : CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct TweakableValuesKey: EnvironmentKey {
    static var defaultValue: [String:CGFloat] = [:]
}

extension EnvironmentValues {
    var tweakables: TweakableValuesKey.Value {
        get { self[TweakableValuesKey.self] }
        set { self[TweakableValuesKey.self] = newValue }
    }
}

extension View {
    func tweakable<Output: View>(_ label: String, initialValue: CGFloat, @ViewBuilder content: @escaping (AnyView, CGFloat) -> Output) -> some View {
        modifier(Tweakable(label: label, initialValue: initialValue, run: content))
    }
}

struct Tweakable<Output: View>: ViewModifier {
    var label: String
    var initialValue: CGFloat
    @ViewBuilder var run: (AnyView, CGFloat) -> Output
    @Environment(\.tweakables) var tweakables

    func body(content: Content) -> some View {
        run(AnyView(content), tweakables[label] ?? initialValue)
            .transformPreference(TweakablePreference.self) { value in
                value[label] = initialValue
            }
    }
}

struct TweakableGUI: ViewModifier {
    @State private var values: [String: CGFloat] = [:]

    func body(content: Content) -> some View {
        content
            .environment(\.tweakables, values)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Form {
                    ForEach(values.keys.sorted(), id: \.self) { key in
                        let b = Binding($values[key])
                        Slider(value: b!, in: 1...100, label: { Text(key) })
                    }
                }
                .frame(maxHeight: 200)
            }
            .onPreferenceChange(TweakablePreference.self, perform: { value in
                values = value
            })
    }
}

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .tweakable("padding", initialValue: 10) {
                $0.padding($1)
            }
            .tweakable("offset", initialValue: 10) {
                $0.offset(x: $1)
            }
            .background(Color.blue)
            .modifier(TweakableGUI())
    }
}

#Preview {
    ContentView()
}
