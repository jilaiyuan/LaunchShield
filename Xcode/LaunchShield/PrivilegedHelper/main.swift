import Foundation

let delegate = HelperListenerDelegate()
let listener = NSXPCListener(machServiceName: XPCConstants.machServiceName)
listener.delegate = delegate
listener.resume()
RunLoop.main.run()
