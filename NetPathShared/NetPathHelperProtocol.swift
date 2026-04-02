import Foundation

@objc public protocol NetPathHelperProtocol {
    func mount(url: String, username: String?, password: String?,
               reply: @escaping (String?, Int32) -> Void)
    func unmount(path: String, reply: @escaping (Bool) -> Void)
    func listMountedShares(reply: @escaping ([String]) -> Void)
    func listSharesOnServer(host: String, username: String?, password: String?,
                            reply: @escaping ([String]?, Int32) -> Void)
}
