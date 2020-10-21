//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

public class AppSyncList<ModelType: Model>: List<ModelType>, ModelListDecoder {

    public typealias Page = AppSyncList<ModelType>
    public typealias PageError = APIError

    /// The array of `Element` that backs the custom collection implementation.
    let nextToken: String?
    let document: String?
    let variables: [String: JSONValue]?

    // MARK: - Initializers

    init(_ elements: [Element],
         nextToken: String? = nil,
         document: String? = nil,
         variables: [String: JSONValue]? = nil) {
        self.nextToken = nextToken
        self.document = document
        self.variables = variables
        super.init(elements)
    }

    required convenience public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }

    // MARK: Paginatable

    public override func hasNextPage() -> Bool {
        return nextToken != nil
    }

    func reconstructGraphQLRequestForNextPage(nextToken: String) -> GraphQLRequest<AppSyncList<ModelType>> {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: ModelType.self, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))

        // Since the fidelity of the original request based on `QueryPredicate` is lost when translated
        // to a GraphQLRequest, the following extracts the existing filter from the GraphQLRequest's variables
        // and uses FilterDecorator to recreate the proper document with variable input parameters
        // and variables containing the filter values.
        if let storedVariables = variables,
           let filters = storedVariables["filter"],
           case let .object(filterValue) = filters {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
            guard let filterVariablesData = try? encoder.encode(filterValue),
                  let filterVariablesJSON = try? JSONSerialization.jsonObject(with: filterVariablesData) as? [String: Any] else {
                fatalError("Filter variables is not valid JSON object")
            }
            documentBuilder.add(decorator: FilterDecorator(filter: filterVariablesJSON))
        }

        // Same as the limit, it is stored in the variables and expected to be persisted across multiple `getNextPage`
        // calls, hence we also extract the limit from the variables whenever possible
        if let storedVariables = variables,
           let limit = storedVariables["limit"],
           case let .number(limitValue) = limit {
            documentBuilder.add(decorator: PaginationDecorator(limit: Int(limitValue), nextToken: nextToken))
        } else {
            documentBuilder.add(decorator: PaginationDecorator(nextToken: nextToken))
        }

        let document = documentBuilder.build()

        return GraphQLRequest<AppSyncList<ModelType>>(document: document.stringValue,
                                                      variables: document.variables,
                                                      responseType: AppSyncList<ModelType>.self,
                                                      decodePath: document.name)
    }

    public override func getNextPage() throws -> Page {
        guard let nextToken = nextToken, let document = document else {
            throw APIError.operationError("Missing next Token", "check hasNext()")
        }

        let request = reconstructGraphQLRequestForNextPage(nextToken: nextToken)

        let semaphore = DispatchSemaphore(value: 0)
        var resultValue: Result<AppSyncList<ModelType>, APIError>?
        Amplify.API.query(request: request) { result in
            switch result {
            case .success(let graphQLResponse):
                switch graphQLResponse {
                case .success(let list):
                    resultValue = .success(list)
                case .failure(let graphQLError):
                    resultValue = .failure(APIError(error: graphQLError))
                }
            case .failure(let apiError):
                resultValue = .failure(apiError)
            }
            semaphore.signal()
        }
        semaphore.wait()
        guard let result = resultValue else {
            throw APIError.unknown("Async operation turn sync should always set result to be returned", "")
        }
        switch result {
        case .success(let list):
            return list
        case .failure(let apiError):
            throw apiError
        }
    }

    // MARK: ModelListDecoder

    public static func shouldDecode(decoder: Decoder) -> Bool {
        let json = try? JSONValue(from: decoder)

        if case let .object(jsonObject) = json,
           case .array = jsonObject["items"] {
            return true
        }

        do {
            _ = try AppSyncListPayload.init(from: decoder)
            return true
        } catch {
            return false
        }
    }

    public static func decode<ModelType: Model>(decoder: Decoder,
                                                modelType: ModelType.Type) -> List<ModelType> {
        do {
            return try AppSyncList<ModelType>.init(from: decoder)
        } catch {
            return List([ModelType]())
        }
    }

    // MARK: Codable

    required convenience public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy

        // metadata decoding
        if let payload = try? AppSyncListPayload.init(from: decoder) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            let elements = try payload.getItems().map { (jsonElement) -> ModelType in
                let serializedJSON = try encoder.encode(jsonElement)
                return try decoder.decode(ModelType.self, from: serializedJSON)
            }

            self.init(elements,
                      nextToken: payload.getNextToken(),
                      document: payload.document,
                      variables: payload.variables)
            return
        }

        // base decoding
        guard case let .object(jsonObject) = json,
              case let .array(jsonArray) = jsonObject["items"] else {
            self.init([ModelType]())
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        let elements = try jsonArray.map { (jsonElement) -> ModelType in
            let serializedJSON = try encoder.encode(jsonElement)
            return try decoder.decode(ModelType.self, from: serializedJSON)
        }

        self.init(elements)
    }
}
