//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct ListDecoderRegistry {
    public static var listDecoders: [ListDecoder.Type] = []
    public static func registerDecoder(_ listDecoder: ListDecoder.Type) {
        listDecoders.append(listDecoder)
    }

    static func decode<ModelType: Model>(decoder: Decoder, modelType: ModelType.Type) -> BaseList<ModelType> {
        for listDecoder in Self.listDecoders {
            if listDecoder.shouldDecode(decoder: decoder) {
                return listDecoder.decode(decoder: decoder, modelType: modelType)
            }
        }

        let json = try? JSONValue(from: decoder)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy

        do {
            let encodedData = try encoder.encode(json)
            return try decoder.decode(BaseList<ModelType>.self, from: encodedData)
        } catch {
            return BaseList([ModelType]())
        }
    }
}

public protocol ListDecoder {
    static func shouldDecode(decoder: Decoder) -> Bool
    static func decode<ModelType: Model>(decoder: Decoder, modelType: ModelType.Type) -> BaseList<ModelType>
}
