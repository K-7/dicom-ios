//
//  DicomNetworkConfig.swift
//  TestDcmtkSwift
//
//  Created by Priyamvada Tiwari on 10/22/18.
//  Copyright © 2018 G Srinivasa. All rights reserved.
//

import Foundation

public enum DICOMNetworkConfigurationMode {
    case local
    case dicomserver_co_uk
}

public struct DICOMNetworkConfiguration {
    let serverAddress: String
    let serverPort: String
    let serverAET: String
    
    let destinationAET: String
    // If empty then the SCP will accept associations for any called AET
    let ourAET: String
    let ourPort: String
    
    init(mode: DICOMNetworkConfigurationMode, serverAddress _serverAddress: String = "192.168.6.193", serverPort _serverPort: String = "4242", serverAET _serverAET: String = "ORTHANC", ourAET _ourAET: String = "PTSCU" ) {
        switch mode {
        case .local:
            self.serverAddress = _serverAddress
            self.serverPort = _serverPort
            self.serverAET = _serverAET
            self.ourAET = _ourAET
        case .dicomserver_co_uk:
            self.serverAddress = "www.dicomserver.co.uk"
            self.serverPort = "11112"
            self.serverAET = "AWSPIXELMEDPUB"
            self.ourAET = ""
        }
        self.destinationAET = "PTSCU"
        self.ourPort = "8089"
    }
}
