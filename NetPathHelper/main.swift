import Foundation

let delegate = HelperDelegate()
let listener = NSXPCListener(machServiceName: "com.bliksem.netpath.helper")
listener.delegate = delegate
listener.resume()
RunLoop.current.run()
