import Flutter
import UIKit
import SwiftUI

class NativeTabBarFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeTabBarView(
            frame: frame,
            viewId: viewId,
            args: args,
            messenger: messenger
        )
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
}

class NativeTabBarView: NSObject, FlutterPlatformView {
    private let channel: FlutterMethodChannel
    private let container: UIView
    private let model = TabBarModel()
    private var hostingController: UIHostingController<SwiftUITabBarView>?

    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        self.channel = FlutterMethodChannel(name: "NativeTabBar_\(viewId)", binaryMessenger: messenger)
        self.container = UIView(frame: frame)
        self.container.backgroundColor = .clear
        self.container.isOpaque = false
        super.init()

        if let dict = args as? [String: Any] {
            updateModel(with: dict)
        }

        model.onSelect = { [weak self] index in
            self?.channel.invokeMethod("valueChanged", arguments: ["index": index])
        }

        let swiftUIView = SwiftUITabBarView(model: model)
        let hc = UIHostingController(rootView: swiftUIView)
        hc.view.backgroundColor = .clear
        hc.view.isOpaque = false
        
        addChild(hc, to: container)
        self.hostingController = hc
        
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }
    
    private func addChild(_ child: UIViewController, to parentView: UIView) {
        child.view.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            child.view.topAnchor.constraint(equalTo: parentView.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
    }

    func view() -> UIView {
        return container
    }
    
    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "update":
            if let args = call.arguments as? [String: Any] {
                updateModel(with: args)
                result(nil)
            } else {
                result(FlutterError(code: "bad_args", message: "Missing args", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func updateModel(with dict: [String: Any]) {
        if let labels = dict["labels"] as? [String] { model.labels = labels }
        if let symbols = dict["symbols"] as? [String] { model.symbols = symbols }
        if let v = dict["selectedIndex"] as? NSNumber { model.selectedIndex = v.intValue }
        if let v = dict["isDark"] as? NSNumber { model.isDark = v.boolValue }
        if let n = dict["tintColor"] as? NSNumber { model.tintColor = Self.colorFromARGB(n.intValue) }
        if let s = dict["split"] as? NSNumber { model.split = s.boolValue }
        if let rc = dict["rightCount"] as? NSNumber { model.rightCount = rc.intValue }
    }

    private static func colorFromARGB(_ argb: Int) -> Color {
        let a = Double((argb >> 24) & 0xFF) / 255.0
        let r = Double((argb >> 16) & 0xFF) / 255.0
        let g = Double((argb >> 8) & 0xFF) / 255.0
        let b = Double(argb & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}

class TabBarModel: ObservableObject {
    @Published var labels: [String] = []
    @Published var symbols: [String] = []
    @Published var selectedIndex: Int = 0
    @Published var split: Bool = false
    @Published var rightCount: Int = 1
    @Published var tintColor: Color = .blue
    @Published var isDark: Bool = false
    
    var onSelect: ((Int) -> Void)?
}

struct SwiftUITabBarView: View {
    @ObservedObject var model: TabBarModel
    
    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                TabView(selection: selectionBinding) {
                    ForEach(0..<count, id: \.self) { i in
                        let isActionItem = model.split && i >= (count - model.rightCount)
                        Tab(value: i, role: isActionItem ? .search : nil) {
                            Color.clear
                        } label: {
                            if i < model.symbols.count {
                                Image(systemName: model.symbols[i])
                            }
                            if i < model.labels.count {
                                Text(model.labels[i])
                            }
                        }
                    }
                }
                .tint(model.tintColor)
                .environment(\.colorScheme, model.isDark ? .dark : .light)
                .toolbarBackground(.hidden, for: .tabBar)
                .onAppear { updateAppearance() }
            } else {
                // Fallback for older iOS versions if needed, or just empty/error
                Text("Requires iOS 18+")
            }
        }
        .background(Color.clear)
        .contentShape(Rectangle())
    }
    
    var selectionBinding: Binding<Int> {
        Binding(
            get: { model.selectedIndex },
            set: { value in
                let count = max(model.labels.count, model.symbols.count)
                if model.split {
                    let right = model.rightCount
                    let splitIndex = max(0, count - right)
                    if value >= splitIndex {
                        model.onSelect?(value)
                        return
                    }
                }
                model.selectedIndex = value
                model.onSelect?(value)
            }
        )
    }
    
    var count: Int {
        max(model.labels.count, model.symbols.count)
    }
    
    func updateAppearance() {
        // iOS 18+ handled by SwiftUI modifiers
        if #available(iOS 18.0, *) { return }

        let appearance = UITabBarAppearance()
}
}