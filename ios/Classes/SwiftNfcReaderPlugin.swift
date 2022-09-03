import Flutter
import UIKit
import CoreNFC

@available(iOS 13.0, *)
public class SwiftNfcReaderPlugin: NSObject, FlutterPlugin {
    var session: NFCReaderSession?
    var result: FlutterResult?
    var currentArguments: [String: Any?] = [:]
    var methodUse: MethodUse?
    var timeoutTimer: Timer?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "nfc_reader", binaryMessenger: registrar.messenger())
        let instance = SwiftNfcReaderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method{
        case "isNFCAvailable":
            result(NFCReaderSession.readingAvailable)
        case "scanNDEFTag":
            methodUse = .read
            self.openNDefScanPopup(arguments: call.arguments, result: result)
        case "scanTag":
            methodUse = .read
            self.openScanPopup(arguments: call.arguments, result: result)
        case "writeNDEFTag":
            methodUse = .write
            self.openNDefScanPopup(arguments: call.arguments, result: result)
        case "writeTag":
            methodUse = .write
            self.openScanPopup(arguments: call.arguments, result: result)
        case "lockNdefTag":
            methodUse = .writeLock
            self.openNDefScanPopup(arguments: call.arguments, result: result)
        case "lockTag":
            methodUse = .writeLock
            self.openScanPopup(arguments: call.arguments, result: result)
        case "finishCurrentSession":
            if let arguments = call.arguments as? [String: Any?]{
                currentArguments = arguments
            }
            self.finishSession(withErrorMessage: currentArguments["errorMessage"] as? String)
        default:
            return
        }
    }
    
    private func openScanPopup(arguments: Any?, result: @escaping FlutterResult){
        var pollingOptions: NFCTagReaderSession.PollingOption = []
        if let arguments = arguments as? [String: Any?]{
            currentArguments = arguments
            if let pollingOptionsFromArgs = arguments["pollingOptions"] as? [String]{
                if pollingOptionsFromArgs.contains("iso14443"){
                    pollingOptions.insert(.iso14443)
                }
                if pollingOptionsFromArgs.contains("iso15693"){
                    pollingOptions.insert(.iso15693)
                }
                if pollingOptionsFromArgs.contains("iso18092"){
                    pollingOptions.insert(.iso18092)
                }
            }
            
        }
        self.scan(session: NFCTagReaderSession(pollingOption: pollingOptions, delegate: self)!, arguments: currentArguments, result: result)
    }
    
    private func openNDefScanPopup(arguments: Any?, result: @escaping FlutterResult){
        if let arguments = arguments as? [String: Any?]{
            currentArguments = arguments
        }
        self.scan(session: NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: currentArguments["invalidateAfterFirstRead"] as? Bool ?? false), arguments: currentArguments, result: result)
    }
}

//MARK: Handle global methods for both NFCNDEFReaderSession and NFCTagReaderSession
@available(iOS 13, *)
extension SwiftNfcReaderPlugin{
    private func scan(session: NFCReaderSession, arguments: [String: Any?], result: @escaping FlutterResult){
        self.finishSession()
        self.session = session
        if let alertMessage = arguments["defaultAlertMessage"] as? String{
            self.session?.alertMessage = alertMessage
        }
        self.result = result
        session.begin()
        if let timeoutInMillis = arguments["timeoutInMillis"] as? Int{
            timeoutTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeoutInMillis / 1000), repeats: false){ timer in
                timer.invalidate()
                self.finishSession(withErrorMessage: arguments["sessionTimeoutError"] as? String? ?? "Session timeout")
            }
        }
     
    }
    
    private func queryNDefTag(withData sData:[String: Any], tag: NFCNDEFTag){
        var scanData = sData
        tag.queryNDEFStatus{ ndefStatus, capacity, error in
            if error != nil{
                return self.handleNFCError(error: error!, withErrorKey: "queryNDefStatusError", defaultMessage: "Unable to query NDEF status of tag")
            }
            //change support status to true
            scanData["supported"] = true
            switch ndefStatus {
            case .notSupported:
                // if current status is not supported, switch the result supported flag to false
                scanData["supported"] = false
            case .readWrite:
                scanData["writable"] = true
                scanData["readable"] = true
            case .readOnly:
                scanData["readable"] = true
                scanData["writable"] = false
            default:
                break;
            }
            scanData["capacity"] = capacity
            switch self.methodUse{
            case .write:
                if ndefStatus == .readWrite{
                    self.writeNDef(tag: tag)
                } else{
                    return self.handleNFCError(withErrorKey: "tagIsReadOnlyError", defaultMessage: "This NFC Tag is read only")
                }
            case .writeLock:
                if ndefStatus == .readWrite{
                    self.writeNDef(tag: tag)
                } else{
                    return self.handleNFCError(error: error!, withErrorKey: "tagIsReadOnlyError", defaultMessage: "This NFC Tag is read only")
                }
            case .read:
                self.readNDef(data: scanData, tag: tag)
            case .none:
                return
            }
        }
    }
    
    private func readNDef(data: [String: Any?], tag: NFCNDEFTag){
        var scanData = data
        tag.readNDEF{ message, error in
            var statusMessage: String
            if nil != error || nil == message {
                return self.handleNFCError(error: error!, withErrorKey: "readNDefError", defaultMessage: "Fail to read NDEF message from tag")
            }
            statusMessage = self.currentArguments["defaultSuccessMessage"] as? String ?? "Found 1 NDEF message"
            DispatchQueue.main.async {
                // Process detected NFCNDEFMessage objects.
                // TODO
                do {
                    scanData["payloads"] = message?.records.map(self.getPayloadFromRecord)
                    let jsonData = try JSONSerialization.data(withJSONObject: scanData,options: .prettyPrinted)
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    self.result?(jsonString)
                }catch{
                    return self.handleNFCError(error: error, withErrorKey: "parsingDataError", defaultMessage: "Error when parsing data")
                }
            }
            self.session?.alertMessage = statusMessage
            self.finishSession()
        }
    }
    
    private func writeNDef(tag: NFCNDEFTag){
        var recordJson: [[String: Any?]] = []
        if let recordsJsonString = currentArguments["rawRecords"] as? String{
            guard let data = recordsJsonString.data(using: .utf8) else{
                return
            }
            do{
                recordJson = try JSONSerialization.jsonObject(with: data) as? [[String: Any?]] ?? []
            }catch{
                return self.handleNFCError(error: error, withErrorKey: "parsingDataError", defaultMessage: "Error when parsing data")
            }
        }
        tag.writeNDEF(NFCNDEFMessage(records: recordJson.map(getRecordFromRawJson))){error in
            var statusMessage: String
            if error != nil{
                return self.handleNFCError(error: error!, withErrorKey: "cantWriteError", defaultMessage: "Can't write to this tag, please try again")
            }
            statusMessage = self.currentArguments["defaultSuccessMessage"] as? String ?? "Write to tag successfully"
            self.result?(nil)
            self.session?.alertMessage = statusMessage
            self.finishSession()
        }
    }
    
    private func writeLock(tag: NFCNDEFTag){
        tag.writeLock{ error in
            var statusMessage: String
            if error != nil{
                return self.handleNFCError(error: error!, withErrorKey: "cantWriteError", defaultMessage: "Can't write to this tag, please try again")
            }
            statusMessage = self.currentArguments["defaultSuccessMessage"] as? String ?? "This tag has been locked"
            self.session?.alertMessage = statusMessage
            self.finishSession()
        }
    }
    
    private func getRecordFromRawJson(raw: [String: Any?]) -> NFCNDEFPayload {
        let format = NFCTypeNameFormat.init(rawValue: UInt8(raw["format"] as? Int ?? 5)) ?? .unknown
        let identifer = (raw["identifer"] as? String ?? "").data(using: .utf8) ?? Data()
        let type = (raw["type"] as? String ?? "")?.data(using: .utf8) ?? Data()
        let payload = (raw["data"] as? String ?? "")?.data(using: .utf8) ?? Data()
        return NFCNDEFPayload(format: format, type: type, identifier: identifer, payload: payload)
    }
    
    private func getPayloadFromRecord(_ record: NFCNDEFPayload)-> [String: Any]{
        var payload: [String: Any] = [:]
        payload["format"] = record.typeNameFormat.rawValue
        if let identifer = record.identifier.encode(){
            payload["identifer"] = identifer
        }
        if let type = record.type.encode(){
            payload["type"] = type
        }
        
        switch record.typeNameFormat{
        case .nfcWellKnown:
            if let url = record.wellKnownTypeURIPayload(){
                payload["data"] = url.absoluteString
            }else if let text = record.wellKnownTypeTextPayload().0 , let locale = record.wellKnownTypeTextPayload().1 {
                payload["data"] = text
                payload["locale"] = locale.description
            }
        case .absoluteURI:
            if let text = record.payload.encode(){
                payload["data"] = text
            }
        case .media:
            if let type = String(data: record.type, encoding: .utf8){
                payload["data"] = type
            }
        case .nfcExternal, .empty, .unknown, .unchanged:
            fallthrough
        @unknown default:
            if let text = String(data: record.payload, encoding: .utf8){
                payload["data"] = text
            }
        }
        return payload
    }
    
    private func handleNFCError(error: Error? = nil, withErrorKey key: String? = nil, defaultMessage: String? = nil){
        var errorMessage = ""
        if key != nil, let errorMessageFromArgs = (self.currentArguments[key!] as? String){
            errorMessage = errorMessageFromArgs
        }else {
            errorMessage = defaultMessage ?? (self.currentArguments["unknownError"] as? String) ?? "Unknown Error"
        }
     
        self.handleFlutterError(withMessage: errorMessage, withDetails: error?.localizedDescription)
        return
    }
    
    private func handleFlutterError(withErrorCode code: String = "500",withMessage message: String?, withDetails details: Any?){
        self.result?(FlutterError(code: code, message: message ?? (currentArguments["unknownError"] as? String) ?? "Unknown error", details: details))
        self.finishSession(withErrorMessage: message)
    }
}


//MARK: Handle NDEF tags scan + write methods
@available(iOS 13.0, *)
extension SwiftNfcReaderPlugin: NFCNDEFReaderSessionDelegate{
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        var errorMessage = ""
        if error is NFCReaderError{
            errorMessage = "NFC session error"
        } else{
            errorMessage = "Session is invalidated with error"
        }
        self.handleNFCError(error: error, withErrorKey: "sessionError", defaultMessage: errorMessage)
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print(messages)
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        var scanData: [String: Any] = [:]
        // Connect to the found tag and perform NDEF message reading
        let tag = tags.first!
        session.connect(to: tag){error in
            if nil != error {
                return self.handleNFCError(error: error!,withErrorKey: "connectTagError", defaultMessage: "Can't connect to NFC Card")
            }
            scanData["name"] = "NDef"
            scanData["type"] = "ndef"
            scanData["standards"] = ["NFC Data Exchange Format"]
            self.queryNDefTag(withData: scanData, tag: tag)
        }
        
    }
    
    private func finishSession(withErrorMessage errorMessage: String? = nil){
        if errorMessage != nil{
            self.session?.invalidate(errorMessage: errorMessage!)
        }else{
            self.session?.invalidate()
        }
        self.timeoutTimer?.invalidate()
        self.timeoutTimer = nil
        self.result = nil
        self.session = nil
    }
    
    
    
    public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        
    }
}

//MARK: Handle ISO7816, ISO15693, FeliCa, and MIFARE tags scan + write methods
@available(iOS 13.0, *)
extension SwiftNfcReaderPlugin: NFCTagReaderSessionDelegate{
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
   
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        var errorMessage = ""
        if error is NFCReaderError{
            errorMessage = "NFC session error"
        } else{
            errorMessage = "Session is invalidated with error"
        }
        self.handleNFCError(error: error, withErrorKey: "sessionError", defaultMessage: errorMessage)
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        //TODO handle mutiple tags scan
        var scanData: [String: Any] = [:]
        let tag = tags.first!
        
        session.connect(to: tag){error in
            if nil != error {
                session.alertMessage = "Can't connect to NFC Card"
                self.handleFlutterError( withMessage: "Can't connect to NFC Card", withDetails: error?.localizedDescription)
                return
            }
            //convert NFC tag to ndef tag
            if let ndefTag = self.identifyNFCTagAndRetrieveNdefTag(scanData: &scanData, tag: tag){
                self.queryNDefTag(withData: scanData, tag: ndefTag)
            }
        }
    }
    
    private func identifyNFCTagAndRetrieveNdefTag(scanData: inout [String: Any],tag: NFCTag) -> NFCNDEFTag?{
        var ndefTag: NFCNDEFTag?
        switch tag{
        case .feliCa(let felicaTag):
            scanData["name"] = "FeliCa"
            scanData["type"] = "felica"
            scanData["standards"] = ["ISO/IEC 18092"]
            if let systemCode = felicaTag.currentSystemCode.encode(){
                scanData["currentSystemCode"] = systemCode
            }
            if let manufacturerIdentifer = felicaTag.currentIDm.encode(){
                scanData["manufacturerIdentifer"] = manufacturerIdentifer
            }
            ndefTag = felicaTag
        case .miFare(let mifareTag):
            switch mifareTag.mifareFamily{
            case .plus:
                scanData["name"] = "MIFARE Plus"
                scanData["type"] = "mifarePlus"
                scanData["standards"] = ["ISO/IEC 14443 A 1-4", "ISO 7816-4"]
            case .ultralight:
                scanData["name"] = "MIFARE Ultralight"
                scanData["type"] = "mifareUltraLight"
                scanData["standards"] = ["ISO/IEC 14443 A 1-3"]
            case .desfire:
                scanData["name"] = "MIFARE DESFire"
                scanData["type"] = "mifareDesfire"
                scanData["standards"] = ["ISO/IEC 14443 A", "ISO/IEC 7816"]
            case .unknown:
                fallthrough
            default:
                scanData["name"] = "Unknown"
                scanData["type"] = "mifareUnknown"
                scanData["standards"] = ["ISO/IEC 14443 A"]
            }
            if let identifer = mifareTag.identifier.encode(){
                scanData["identifer"] = identifer
            }
            if let historicalBytes = mifareTag.historicalBytes?.encode(){
                scanData["historicalBytes"] = historicalBytes
            }
            ndefTag = mifareTag
        case .iso7816(let iso7816Tag):
            scanData["name"] = "iso7816"
            scanData["type"] = "iso7816"
            scanData["standards"] = ["ISO/IEC 7816"]
            if let identifer = iso7816Tag.identifier.encode(){
                scanData["identifer"] = identifer
            }
            if let historicalBytes = iso7816Tag.historicalBytes?.encode(){
                scanData["historicalBytes"] = historicalBytes
                scanData["standards"] = ["ISO/IEC 14443 A", "ISO/IEC 7816"]
            }else if let applicationData = iso7816Tag.applicationData?.encode(){
                scanData["applicationData"] = applicationData
                scanData["standards"] = ["ISO/IEC 14443 B", "ISO/IEC 7816"]
            }else {
                scanData["standards"] = ["ISO/IEC 14443"]
            }
            scanData["initialSelectedAID"] = iso7816Tag.initialSelectedAID
            ndefTag = iso7816Tag
        case .iso15693(let iso15693Tag):
            scanData["name"] = "iso15693"
            scanData["type"] = "iso15693"
            scanData["standards"] = ["ISO/IEC 15693"]
            if let identifer = iso15693Tag.identifier.encode(){
                scanData["identifer"] = identifer
            }
            scanData["manufacturerIdentifer"] = String(format: "%d", iso15693Tag.icManufacturerCode)
            ndefTag = iso15693Tag
        default:
            scanData["type"] = "unknown"
        }
        return ndefTag
    }
}

