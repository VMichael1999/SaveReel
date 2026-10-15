import UIKit
import UniformTypeIdentifiers

/// Extensión de «Compartir»: recibe el enlace o el texto que otra app comparte
/// hacia SaveReel y abre la app con `savetic://share?text=<texto>`, para que el
/// enlace se ponga solo y se pueda elegir el formato.
class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        let providers = items.flatMap { $0.attachments ?? [] }
        loadText(from: providers, at: 0)
    }

    /// Busca, en orden, un enlace o un texto entre lo que se comparte.
    private func loadText(from providers: [NSItemProvider], at index: Int) {
        guard index < providers.count else {
            finish(with: nil)
            return
        }
        let provider = providers[index]
        let next = { self.loadText(from: providers, at: index + 1) }

        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    self.finish(with: url.absoluteString)
                } else {
                    next()
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                if let text = item as? String {
                    self.finish(with: text)
                } else {
                    next()
                }
            }
        } else {
            next()
        }
    }

    private func finish(with text: String?) {
        DispatchQueue.main.async {
            if let text = text, let url = Self.appURL(for: text) {
                self.openHostApp(url)
            }
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    /// `savetic://share?text=…`, con el texto bien codificado (el `?`, el `&`
    /// y el `=` del propio enlace no deben romper la consulta).
    private static func appURL(for text: String) -> URL? {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+?#")
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: allowed) else {
            return nil
        }
        return URL(string: "savetic://share?text=\(encoded)")
    }

    /// Una extensión no puede usar `UIApplication.shared` ni llamar a `open`
    /// directamente (Xcode lo marca como no disponible). El truco habitual es
    /// recorrer la cadena de respuesta hasta dar con la aplicación y llamar a
    /// `open(_:options:completionHandler:)` por su nombre en tiempo de ejecución.
    @discardableResult
    private func openHostApp(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication {
                return open(url, with: application)
            }
            responder = current.next
        }
        return false
    }

    private func open(_ url: URL, with application: UIApplication) -> Bool {
        let selector = NSSelectorFromString("openURL:options:completionHandler:")
        if application.responds(to: selector) {
            typealias OpenFunction = @convention(c) (
                AnyObject, Selector, URL, [UIApplication.OpenExternalURLOptionsKey: Any], ((Bool) -> Void)?
            ) -> Void
            let implementation = application.method(for: selector)
            let open = unsafeBitCast(implementation, to: OpenFunction.self)
            open(application, selector, url, [:], nil)
            return true
        }
        // Respaldo para versiones de iOS anteriores a la 18.
        let legacy = NSSelectorFromString("openURL:")
        if application.responds(to: legacy) {
            _ = application.perform(legacy, with: url)
            return true
        }
        return false
    }
}
