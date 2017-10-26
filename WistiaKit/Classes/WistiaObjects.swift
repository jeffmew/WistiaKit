//
//  WistiaObjects.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 10/17/17.
//

import Foundation

public protocol WistiaObject: Codable {
    typealias object = Self
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//          Protocols common to Wistia Objects
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

public typealias objectCompletionHandler<T> = ((_ object: T?, _ error: WistiaError?) -> ())
public typealias arrayCompletionHandler<T> = ((_ objects: [T]?, _ error: WistiaError?) -> ())

//MARK: - List
public protocol WistiaClientListable {
    associatedtype object: WistiaObject

    static func list(usingClient: WistiaClient?, _ completionHander: @escaping arrayCompletionHandler<object>)
}
//TOOD: Extension with default implementation of list?

//MARK: - show
public protocol WistiaClientShowable {
    associatedtype object: WistiaObject

    var id: String? {get}
    static var singularPath: String {get}
    func show(usingClient: WistiaClient?, _ completionHander: @escaping objectCompletionHandler<object>)
}

public extension WistiaClientShowable {
    public func show(usingClient: WistiaClient? = nil, _ completionHander: @escaping ((Media?, WistiaError?) -> ())) {
        guard let hashedId = self.id else {
            let errorDescription = "Cannot show without first setting the hashedID"
            assertionFailure(errorDescription)
            completionHander(nil, WistiaError.preconditionFailure(errorDescription))
            return
        }
        let client = usingClient ?? WistiaClient.default
        client.get("\(type(of: self).singularPath)/\(hashedId).json", completionHandler: completionHander)
    }
}

//MARK: - create
public protocol WistiaClientCreatable {
    associatedtype object: WistiaObject

    func create(usingClient: WistiaClient?, _ completionHandler: @escaping objectCompletionHandler<object>)
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//          Codable Extension
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

enum DataWrapperKey: String, CodingKey {
    case data = "data"
}

extension Decoder {
    // Some JSON is wrapped in a data dictionary:  {relationships: {data: {id: "https://wistia.com", name: "Title"}}}
    // The decoding process to flatten that is 1) get container for 'data', 2) get nested container for the actual CodingKeys, 3) decode
    // This method does steps 1 and 2, returning the inner container we can then use to do a flat decoding.
    func dataWrappedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let dataContainer = try self.container(keyedBy: DataWrapperKey.self)
        let container = try dataContainer.nestedContainer(keyedBy: type, forKey: .data)
        return container
    }
}

