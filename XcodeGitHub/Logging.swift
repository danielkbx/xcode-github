import Foundation

@objc
class Logging: NSObject {
    
    @objc
    static let `default` = Logging()
    
    @objc
    func log(_ message: String, function: String = #function, file: String = #file, line: Int = #line, column: Int = #column) {
        
    }
}
