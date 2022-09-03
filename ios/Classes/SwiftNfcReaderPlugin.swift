import Flutter
import UIKit
import CoreNFC

@available(iOS 13.0, *)
public class SwiftNfcReaderPlugin: NSObject, FlutterPlugin {
    var session: NFCReaderSession?
    var result: FlutterResult?
    var currentArguments: [String: Any?] = [:]
    
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
            if let arguments = call.arguments as? [String: Any?]{
                currentArguments = arguments
            }
            self.scan(session: NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: currentArguments["invalidateAfterFirstRead"] as? Bool ?? false), arguments: currentArguments, result: result)
        case "scanTag":
            var pollingOptions: NFCTagReaderSession.PollingOption = []
            if let arguments = call.arguments as? [String: Any?]{
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
        case "finishCurrentSession":
            if let arguments = call.arguments as? [String: Any?]{
                currentArguments = arguments
            }
            self.finishSession(withErrorMessage: currentArguments["errorMessage"] as? String)
        default:
            return
        }
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
            Timer.scheduledTimer(withTimeInterval: TimeInterval(timeoutInMillis / 1000), repeats: false){ timer in
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
            default:
                break;
            }
            scanData["capacity"] = capacity
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
                        scanData["payloads"] = message?.records.map(self.parsePayload)
                        let jsonData = try JSONSerialization.data(withJSONObject: scanData,options: .prettyPrinted)
                        let jsonString = String(data: jsonData, encoding: .utf8)
                        self.result?(jsonString)
                    }catch{
                        self.handleNFCError(error: error, withErrorKey: "parsingDataError", defaultMessage: "Error when parsing data")
                    }
                    self.session?.alertMessage = statusMessage
                    self.finishSession()
                }
                
            }
        }
    }
    
    private func parsePayload(_ record: NFCNDEFPayload)-> [String: Any]{
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
    
    private func handleNFCError(error: Error, withErrorKey key: String? = nil, defaultMessage: String? = nil){
        var errorMessage = ""
        if key != nil, let errorMessageFromArgs = (self.currentArguments[key!] as? String){
            errorMessage = errorMessageFromArgs
        }else {
            errorMessage = defaultMessage ?? (self.currentArguments["unknownError"] as? String) ?? "Unknown Error"
        }
        self.handleFlutterError(withMessage: errorMessage, withDetails: error.localizedDescription)
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

