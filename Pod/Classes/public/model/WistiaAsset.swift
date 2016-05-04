//
//  WistiaAsset.swift
//  Stargazer
//
//  Created by Daniel Spinosa on 1/25/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation

public struct WistiaAsset {

    public var media: WistiaMedia
    public var type: String
    public var displayName: String?
    public var container: String?
    var codec: String?
    public var width: Int64
    public var height: Int64
    public var size: Int64?
    var ext: String?
    var bitrate: Int64?
    public var status: WistiaObjectStatus?
    public var urlString: String
    var slug: String?

    public var url:NSURL {
        get {
            return NSURL(string: self.urlString)!
        }
    }
}