//
//  ModelBuilder.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 5/4/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//
//  Converts JSON-like Hashes to Structs

import Foundation

internal class ModelBuilder {

    internal static let RFC3339DateFormatter: NSDateFormatter = {
        let df = NSDateFormatter()
        df.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return df
    }()

    internal static func accountFromHash(accountHash:[String: AnyObject]) -> WistiaAccount? {

        if let
            //required
            accountID = accountHash["id"] as? Int,
            name = accountHash["name"] as? String,
            accountURLString = accountHash["url"] as? String,
            mediaCount = accountHash["mediaCount"] as? Int {

            return WistiaAccount(accountID: accountID, name: name, accountURLString: accountURLString, mediaCount: mediaCount)
        } else {
            return nil
        }

    }

    internal static func projectFromHash(projectHash:[String: AnyObject]) -> WistiaProject? {
        if let
            //required
            projectID = projectHash["id"] as? Int {
            //required and annoying
            let hashedID: String
            if let hid = projectHash["hashed_id"] as? String {
                hashedID = hid
            } else if let hid = projectHash["hashedId"] as? String {
                hashedID = hid
            } else {
                return nil
            }
            //optional
            let name = projectHash["name"] as? String
            let description = projectHash["description"] as? String
            let mediaCount = projectHash["mediaCount"] as? Int

            var medias:[WistiaMedia]? = nil
            if let mediasHashArray = projectHash["medias"] as? [[String:AnyObject]] {
                medias = mediasFromHashArray(mediasHashArray)
            }

            return WistiaProject(projectID: projectID, name: name, description: description, mediaCount: mediaCount, hashedID: hashedID, medias: medias)
        }
        
        return nil
    }

    internal static func mediasFromHashArray(mediasHashArray:[[String:AnyObject]]) -> [WistiaMedia] {
        var medias = [WistiaMedia]()
        for mediaHash in mediasHashArray {
            if let media = mediaFromHash(mediaHash) {
                medias.append(media)
            }
        }
        return medias
    }

    internal static func mediaFromHash(mediaHash:[String: AnyObject]) -> WistiaMedia? {
        if let
            //required
            duration = mediaHash["duration"] as? Float {
            let status:WistiaObjectStatus
            if let statusString = mediaHash["status"] as? String {
                status = WistiaObjectStatus(failsafeFromRawString: statusString)
            } else if let statusInt = mediaHash["status"] as? Int {
                status = WistiaObjectStatus(failsafeFromRaw: statusInt)
            } else {
                status = WistiaObjectStatus.Failed
            }
            //required and annoying
            let hashedID: String
            if let hid = mediaHash["hashedId"] as? String {
                hashedID = hid
            } else if let hid = mediaHash["hashed_id"] as? String {
                hashedID = hid
            } else {
                return nil
            }
            //optional
            let mediaID = mediaHash["id"] as? Int
            let name = mediaHash["name"] as? String
            let description = mediaHash["description"] as? String
            var created: NSDate? = nil
            if let c = mediaHash["created"] as? String {
                created = RFC3339DateFormatter.dateFromString(c)
            }
            var updated: NSDate? = nil
            if let u = mediaHash["updated"] as? String {
                updated = RFC3339DateFormatter.dateFromString(u)
            }
            let spherical = (mediaHash["spherical"] as? Bool) ?? false
            let thumbnail:(String, Int, Int)?
            if let thumbnailHash = mediaHash["thumbnail"] as? [String: AnyObject],
                thumbnailURLString = thumbnailHash["url"] as? String,
                thumbnailWidth = thumbnailHash["width"] as? Int,
                thumbnailHeight = thumbnailHash["height"] as? Int {

                thumbnail = (url: thumbnailURLString, width: thumbnailWidth, height: thumbnailHeight)
            } else {
                thumbnail = nil
            }
            let distilleryURLString = mediaHash["distilleryUrl"] as? String
            let accountKey = mediaHash["accountKey"] as? String
            let mediaKey = mediaHash["mediaKey"] as? String
            let embedOptions = mediaHash["embed_options"] as? [String:AnyObject]
            let mediaEmbedOptions = ModelBuilder.embedOptionsFromHash(embedOptions)

            var wMedia = WistiaMedia(mediaID: mediaID, name: name, status: status, thumbnail: thumbnail, duration: duration, created: created, updated: updated, assets: [WistiaAsset](), description: description, hashedID: hashedID, embedOptions: mediaEmbedOptions, distilleryURLString: distilleryURLString, accountKey: accountKey, mediaKey: mediaKey, spherical: spherical)

            // -- Assets (are optional) --
            if let assets = mediaHash["assets"] as? [[String:AnyObject]] {
                wMedia.assets = wistiaAssetsFromHash(assets, forMedia:wMedia)
            }

            return wMedia
        }
        return nil
    }

    internal static func wistiaAssetsFromHash(assetsHashArray:[[String:AnyObject]], forMedia media:WistiaMedia) -> [WistiaAsset] {
        var wistiaAssets = [WistiaAsset]()
        for rawAsset in assetsHashArray {
            if let
                //requried
                width = rawAsset["width"] as? Int,
                height = rawAsset["height"] as? Int,
                type = rawAsset["type"] as? String,
                urlString = rawAsset["url"] as? String {
                //required and annoying
                var size:Int64? = nil
                if let s = rawAsset["size"] as? Int {
                    size = Int64(s)
                } else if let s = rawAsset["filesize"] as? Int {
                    size = Int64(s)
                }
                //optional attribrutes
                let displayName = rawAsset["display_name"] as? String
                let container = rawAsset["container"] as? String
                let codec = rawAsset["codec"] as? String
                let ext = rawAsset["ext"] as? String
                var bitrate: Int64? = nil
                if let b = rawAsset["bitrate"] as? Int {
                    bitrate = Int64(b)
                }
                var status:WistiaObjectStatus? = nil
                if let assetStatus = rawAsset["status"] as? Int {
                    status = WistiaObjectStatus(failsafeFromRaw: assetStatus)
                }
                let slug = rawAsset["slug"] as? String

                let wistiaAsset = WistiaAsset(media: media, urlString: urlString, width: Int64(width), height: Int64(height), size: size, type: type, status: status, slug: slug, displayName: displayName, container: container, codec: codec, ext: ext, bitrate: bitrate)

                wistiaAssets.append(wistiaAsset)
            }
        }
        return wistiaAssets
    }

    internal static func embedOptionsFromHash(mediaEmbedOptionsHash:[String:AnyObject]?) -> WistiaMediaEmbedOptions? {
        guard let embedOptionsHash = mediaEmbedOptionsHash else { return nil }

        //init with defaults
        var mediaEmbedOptions = WistiaMediaEmbedOptions()

        //...override with custom attributes, if specified
        if let playerColor = embedOptionsHash["playerColor"] as? String {
            mediaEmbedOptions.playerColor = UIColor.wk_fromHexString(playerColor)
        }

        if let bigPlayButton = embedOptionsHash["playButton"] as? NSString {
            mediaEmbedOptions.bigPlayButton = bigPlayButton.boolValue
        }

        if let smallPlayButton = embedOptionsHash["smallPlayButton"] as? NSString {
            mediaEmbedOptions.smallPlayButton = smallPlayButton.boolValue
        }

        if let playbar = embedOptionsHash["playbar"] as? NSString {
            mediaEmbedOptions.playbar = playbar.boolValue
        }

        if let fullscreenButton = embedOptionsHash["fullscreenButton"] as? NSString {
            mediaEmbedOptions.fullscreenButton = fullscreenButton.boolValue
        }

        if let controlsVisibleOnLoad = embedOptionsHash["controlsVisibleOnLoad"] as? NSString {
            mediaEmbedOptions.controlsVisibleOnLoad = controlsVisibleOnLoad.boolValue
        }

        if let autoplay = embedOptionsHash["autoPlay"] as? NSString {
            mediaEmbedOptions.autoplay = autoplay.boolValue
        }

        if let endVideoBehavior = embedOptionsHash["endVideoBehavior"] as? String {
            mediaEmbedOptions.endVideoBehaviorString = endVideoBehavior
        }

        if let stillURLString = embedOptionsHash["stillUrl"] as? String, stillURL = NSURL(string: stillURLString) {
            mediaEmbedOptions.stillURL = stillURL
        }

        if let plugin = embedOptionsHash["plugin"] as? [String:AnyObject] {
            if let _ = plugin["socialbar-v1"] {
                mediaEmbedOptions.actionButton = true
            }
            if let captionsHash = plugin["captions-v1"] as? [String:AnyObject],
                captionsOn = captionsHash["onByDefault"] as? NSString {
                mediaEmbedOptions.captions = captionsOn.boolValue
            }
        }
        
        return mediaEmbedOptions
    }
}