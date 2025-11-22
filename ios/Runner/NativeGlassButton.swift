import Flutter
import UIKit

class GlassButtonFactory: NSObject, FlutterPlatformViewFactory {
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
		return GlassButtonView(
			frame: frame,
			viewIdentifier: viewId,
			arguments: args,
			messenger: messenger
		)
	}

	func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
		return FlutterStandardMessageCodec.sharedInstance()
	}
}



struct GlassButtonConfig: Equatable {
	var iconName: String = "questionmark"
	var iconColor: UIColor = .white
	var tintColor: UIColor = .purple

	init(from dict: [String: Any]?) {
		guard let dict = dict else { return }
		if let icon = dict["icon"] as? String { self.iconName = icon }
		if let colorInt = dict["iconColor"] as? NSNumber {
			self.iconColor = GlassButtonConfig.uiColorFromARGB(colorInt.intValue)
		}
		if let colorInt = dict["tintColor"] as? NSNumber {
			self.tintColor = GlassButtonConfig.uiColorFromARGB(colorInt.intValue)
		}
	}

	private static func uiColorFromARGB(_ argb: Int) -> UIColor {
		let a = CGFloat((argb >> 24) & 0xFF) / 255.0
		let r = CGFloat((argb >> 16) & 0xFF) / 255.0
		let g = CGFloat((argb >> 8) & 0xFF) / 255.0
		let b = CGFloat(argb & 0xFF) / 255.0
		return UIColor(red: r, green: g, blue: b, alpha: a)
	}
}

class GlassButtonContainerView: UIView {
	var onLayoutSubviews: (() -> Void)?

	override func layoutSubviews() {
		super.layoutSubviews()
		onLayoutSubviews?()
	}
}

class GlassButtonView: NSObject, FlutterPlatformView {
	private var _view: GlassButtonContainerView
	private var _channel: FlutterMethodChannel
	private var _config: GlassButtonConfig

	init(
		frame: CGRect,
		viewIdentifier viewId: Int64,
		arguments args: Any?,
		messenger: FlutterBinaryMessenger
	) {
		_view = GlassButtonContainerView(frame: frame)
		_channel = FlutterMethodChannel(
			name: "transito/glass_button_\(viewId)",
			binaryMessenger: messenger
		)
		_config = GlassButtonConfig(from: args as? [String: Any])
		super.init()
		setupView()
	}

	func view() -> UIView {
		return _view
	}

	private func setupView() {
		_view.backgroundColor = .clear

		let button = UIButton(type: .system)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
		
		if	#available(iOS 26.0, *) {
			button.configuration = .prominentGlass()
		}
			
		// Icon Configuration
		let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
		let image = UIImage(systemName: _config.iconName, withConfiguration: symbolConfig)
		button.setImage(image, for: .normal)
		button.tintColor = _config.tintColor
		button.setTitleColor(_config.iconColor, for: .normal)
		button.layer.cornerRadius = button.frame.height / 2

		_view.addSubview(button)

		NSLayoutConstraint.activate([
			button.topAnchor.constraint(equalTo: _view.topAnchor),
			button.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
			button.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
			button.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
		])

		
	}

	@objc func onTap() {
		let generator = UIImpactFeedbackGenerator(style: .light)
		generator.impactOccurred()
		_channel.invokeMethod("onPressed", arguments: nil)
	}
}
