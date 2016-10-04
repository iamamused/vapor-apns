//
//  APNSSettings.swift
//  VaporAPNS
//
//  Created by Matthijs Logemann on 17/09/2016.
//
//

import Foundation
import Node

/// Specific configuration options to be passed to `VaporAPNS`
public struct Options: CustomStringConvertible, NodeInitializable {
    public enum Port: Int {
        case p443 = 443, p2197 = 2197
    }
    
    public var topic: String
    public var port: Port = .p443
    
    // Authentication method: certificates
    public var certPath: String?
    public var keyPath: String?
    
    // Authentication method: authentication key
    public var teamId: String?
    public var keyId: String?
    public var authenticationToken: String?
    
    public var usesCertificateAuthentication: Bool {
        return certPath != nil && keyPath != nil
    }
    
    public init(topic: String, certPath: String, keyPath: String, port: Port = .p443) throws {
        self.topic = topic
        self.certPath = certPath
        self.keyPath = keyPath
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: certPath) else {
            throw InitializeError.certificateFileDoesNotExist
        }
        guard fileManager.fileExists(atPath: keyPath) else {
            throw InitializeError.keyFileDoesNotExist
        }
    }
    
    public init(topic: String, teamId: String, keyId: String, keyPath: String, port: Port = .p443) throws {
        self.teamId = teamId
        self.topic = topic
        self.keyId = keyId
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: keyPath) else {
            throw InitializeError.keyFileDoesNotExist
        }
        
        self.authenticationToken = try keyPath.tokenString()
    }
    
    public init(node: Node, in context: Context) throws {
        if let topic = node["topic"]?.string {
            self.topic = topic
        }else {
            throw InitializeError.noTopic
        }
        
        if let portRaw = node["port"]?.int, let port = Port(rawValue: portRaw) {
            self.port = port
        }
        
        var hasAnyAuthentication = false
        var hasBothAuthentication = false

        if let certPath = node["certificatePath"]?.string, let keyPath = node["keyPath"]?.string {
            hasAnyAuthentication = true
            self.certPath = certPath
            self.keyPath = keyPath
            
        }
        
        if let privateKeyLocation = node["keyPath"]?.string, let keyId = node["keyId"]?.string {
            if hasAnyAuthentication { hasBothAuthentication = true }
            hasAnyAuthentication = true
            self.authenticationToken = try privateKeyLocation.tokenString()
            self.keyId = keyId
        }
        
        guard hasAnyAuthentication else {
            throw InitializeError.noAuthentication
        }
        
        if hasBothAuthentication {
            print ("You've seem to have specified both authentication methods, choosing preferred APNS Auth Key method...")
            certPath = nil
            keyPath = nil
        }
    }
    
    public var description: String {
        return
            "Topic \(topic)" +
                "\nPort \(port.rawValue)" +
                "\nPort \(port.rawValue)" +
                "\nCER - Certificate path: \(certPath)" +
                "\nCER - Key path: \(keyPath)" +
                "\nTOK - Key ID: \(keyId)" +
                "\nTOK - Authentication token: \(authenticationToken)"
    }
}
