import Foundation

@objc class XcodeBotFailedTestLocation: NSObject {
    
    let fileName: String
    let lineNumber: Int
    let message: String
    
    fileprivate init(fileName: String, lineNumber: Int, message: String) {
        self.fileName = fileName
        self.lineNumber = lineNumber
        self.message = message
    }
    
}

@objc class XcodeBotTestResult: NSObject {
    
    typealias Structure = [String : [_TestResultDictionary]]
    
    @objc let name: String
    @objc let numberOfFailed: Int
    @objc let locations: [XcodeBotFailedTestLocation]
    
    @objc
    static func results(fromData data: Data, onlyFailed: Bool = false) -> [XcodeBotTestResult] {
        let decoder = JSONDecoder()
        var tests: [XcodeBotTestResult] = []
        do {
            let entries = try decoder.decode(Structure.self, from: data)
            
            for (key, value) in entries {
                let failed = value.reduce(0) { (failed, entry) in
                    var totalFailed = failed
                    totalFailed += entry.failed
                    return totalFailed
                }
                
                var locations: [XcodeBotFailedTestLocation] = []
                for test in value {
                    if let testSummaries = test.failureSummaries, testSummaries.count > 0 {
                        locations.append(contentsOf: testSummaries.map {
                            return XcodeBotFailedTestLocation(fileName: $0.cleanedFileName, lineNumber: $0.lineNumber, message: $0.message)
                        })
                    }
                }
                
                if !onlyFailed || failed > 0 {
                    tests.append(XcodeBotTestResult(name: key, numberOfFailed: failed, locations: locations))
                }
            }
            
            
        } catch {
            Swift.print(String(describing: error))
        }
        
        return tests
    }
    
    private init(name: String, numberOfFailed: Int, locations: [XcodeBotFailedTestLocation]) {
        self.name = name
        self.numberOfFailed = numberOfFailed
        self.locations = locations
    }
    
    override var debugDescription: String {
        return [super.debugDescription, self.name, "failed:\(self.numberOfFailed)"].joined(separator: ", ")
    }
    
}

struct _TestResultDictionary: Decodable {
    let failed: Int
    let passed: Int
    
    let failureSummaries: [_TestFailureSummary]?
}

struct _TestFailureSummary: Decodable {
    let message: String
    let lineNumber: Int
    let fileName: String
    
    var cleanedFileName: String {
        let components = fileName.components(separatedBy: "/")
        guard let indexOfXCSBuilder = components.firstIndex(of: "XCSBuilder") else { return self.fileName }
        guard components[indexOfXCSBuilder + 1] == "Bots" else { return self.fileName }
        
        let startIndex = indexOfXCSBuilder + 5 // …/XCSBuilder/Bots/98677bd28b34731516fbc5e26d2f70c4/Source/MacDesigner/Common/Unit Tests/…
        return components.dropFirst(startIndex).joined(separator: "/")
    }
}
