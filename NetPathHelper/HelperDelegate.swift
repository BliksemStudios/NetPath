import Foundation

final class HelperDelegate: NSObject, NSXPCListenerDelegate {
    private let mountService = MountService()

    func listener(_ listener: NSXPCListener,
                  shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: NetPathHelperProtocol.self)
        newConnection.exportedObject = mountService
        newConnection.invalidationHandler = {}
        newConnection.resume()
        return true
    }
}
