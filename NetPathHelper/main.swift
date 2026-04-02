import Foundation

class HelperDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        return true
    }
}

let delegate = HelperDelegate()
let listener = NSXPCListener(machServiceName: "com.bliksem.netpath.helper")
listener.delegate = delegate
listener.resume()
RunLoop.current.run()
