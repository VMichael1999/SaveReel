import Flutter
import Network
import UIKit

/// Vigila el tipo de red: `isExpensive` es cierto con datos móviles o con un
/// punto de acceso del teléfono, y `isConstrained` con el modo de datos reducidos.
final class NetworkMonitor {
  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "savetic.network")
  private var metered = false

  var isMetered: Bool { queue.sync { metered } }

  init() {
    monitor.pathUpdateHandler = { [weak self] path in
      self?.metered = path.isExpensive || path.isConstrained
    }
    monitor.start(queue: queue)
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let networkMonitor = NetworkMonitor()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    FlutterMethodChannel(
      name: "savetic/network",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setMethodCallHandler { [weak self] call, result in
      if call.method == "isMetered" {
        result(self?.networkMonitor.isMetered ?? false)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
