//
//  APIService.swift
//  Candlestick
//
//  Created by Brandon Grossnickle on 1/13/25.
//

import Foundation
import Alamofire

class APIService {
    private let baseUrl = "https://doon-labs-api-gateway-v3-90w617fz.wl.gateway.dev"
//    private let baseUrl = "https://rizz-ai-707222528495.us-central1.run.app"
    private let apiKey = "AIzaSyD06A_2fetunsTCkASmkxNfU1Hscc61FZ0"
    private let bundleIdentifier = "com.BrandonGrossnickle.Candlestick"
    
    private let longSession: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 120
        return Session(configuration: configuration)
    }()
    
    func getChartAnalysis(
        tradingStyles: String,
        risk: String,
        exeperience: String,
        base64Image: String,
        completion: @escaping (Result<ChartAnalysis, Error>) -> Void
    ) {
        let url = baseUrl + "/getChartAnalysis"

        var parameters: [String: Any] = [
            "tradingStyles": tradingStyles,
            "risk": risk,
            "experience": exeperience,
            "base64Image": base64Image
        ]

        if let promptPath = Bundle.main.path(forResource: "alpha_prompt", ofType: "txt"),
           let prompt = readStringFromFile(atPath: promptPath) {
            parameters["prompt"] = prompt
        }
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "x-api-key": apiKey,
            "X-Ios-Bundle-Identifier": bundleIdentifier
        ]
        
        longSession.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .validate()
        .responseJSON { response in
            switch response.result {
                case .success(let value):
                    guard var dict = value as? [String: Any] else {
                        completion(.failure(NSError(
                            domain: "",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Response is not valid JSON dictionary."]
                        )))
                        return
                    }
                    dict["articles"] = []
                    do {
                        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
                        let chartAnalysis = try JSONDecoder().decode(ChartAnalysis.self, from: data)
                        completion(.success(chartAnalysis))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    if let data = response.data {
                        do {
                            if let errorJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                if let errorMessage = errorJSON["error"] as? String {
                                    let customError = NSError(
                                        domain: "",
                                        code: response.response?.statusCode ?? 0,
                                        userInfo: [NSLocalizedDescriptionKey: errorMessage]
                                    )
                                    completion(.failure(customError))
                                    return
                                }
                            }
                            else {
                                let fallbackError = NSError(
                                    domain: "",
                                    code: response.response?.statusCode ?? 0,
                                    userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."]
                                )
                                completion(.failure(fallbackError))
                                return
                            }
                        } catch {
                            print("Failed to parse error JSON: \(error.localizedDescription)")
                        }
                    }
                    completion(.failure(error))
            }
        }
    }
    
    func getArticles(
        userPrompt: String,
        completion: @escaping (Result<[Article], Error>) -> Void
    ) {
        let url = baseUrl + "/getArticles"

        var parameters: [String: Any] = [
            "userPrompt": userPrompt
        ]

        if let promptPath = Bundle.main.path(forResource: "perplexity_prompt", ofType: "txt"),
           let prompt = readStringFromFile(atPath: promptPath) {
            parameters["prompt"] = prompt
        }

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "x-api-key": apiKey,
            "X-Ios-Bundle-Identifier": bundleIdentifier
        ]

        longSession.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .validate()
        .responseJSON { response in
            switch response.result {
                case .success(let value):
                    guard let dict = value as? [String: Any] else {
                        completion(.failure(NSError(
                            domain: "",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Response is not valid JSON dictionary."]
                        )))
                        return
                    }
                    do {
                        if let articlesArray = dict["articles"] as? [[String: Any]] {
                            let data = try JSONSerialization.data(withJSONObject: articlesArray, options: [])
                            let articles = try JSONDecoder().decode([Article].self, from: data)
                            completion(.success(articles))
                        } else {
                            completion(.success([]))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                if let data = response.data {
                    do {
                        if let errorJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            if let errorMessage = errorJSON["error"] as? String {
                                let customError = NSError(
                                    domain: "",
                                    code: response.response?.statusCode ?? 0,
                                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                                )
                                completion(.failure(customError))
                                return
                            }
                        }
                        else {
                            let fallbackError = NSError(
                                domain: "",
                                code: response.response?.statusCode ?? 0,
                                userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."]
                            )
                            completion(.failure(fallbackError))
                            return
                        }
                    } catch {
                        print("Failed to parse error JSON: \(error.localizedDescription)")
                    }
                }
                completion(.failure(error))
            }
        }
    }

//    func sendPerplexityRequest(userPrompt: String, completion: @escaping (Result<[Article], Error>) -> Void) {
//        print("SENDING PERPLEXITY REQUEST...")
//        if let filePath = Bundle.main.path(forResource: "perplexity_prompt", ofType: "txt"),
//           let prompt = readStringFromFile(atPath: filePath) {
//            
//            let payload: [String: Any] = [
//                "model": "sonar",
//                "messages": [
//                    ["role": "system", "content": prompt],
//                    ["role": "user", "content": userPrompt]
//                ],
//                "response_format": [
//                    "type": "json_schema",
//                    "json_schema": [
//                        "name": "article_response",
//                        "schema": [
//                            "type": "object",
//                            "properties": [
//                                "articles": [
//                                    "type": "array",
//                                    "description": "List of relevant news articles",
//                                    "items": [
//                                        "type": "object",
//                                        "properties": [
//                                            "title": [
//                                                "type": "string",
//                                                "description": "The headline of the news article"
//                                            ],
//                                            "summary": [
//                                                "type": "string",
//                                                "description": "A brief summary explaining the article's relevance to the chart analysis"
//                                            ],
//                                            "link": [
//                                                "type": "string",
//                                                "format": "uri",
//                                                "description": "The link to the news article"
//                                            ]
//                                        ],
//                                        "required": ["title", "summary", "link"],
//                                        "additionalProperties": false
//                                    ]
//                                ]
//                            ],
//                            "required": ["articles"],
//                            "additionalProperties": false
//                        ]
//                    ]
//                ],
//                "temperature": 0.0,
//                "top_p": 0.9,
//                "search_domain_filter": ["perplexity.ai"],
//                "return_images": false,
//                "return_related_questions": false,
//                "search_recency_filter": "month",
//                "top_k": 0,
//                "stream": false,
//                "presence_penalty": 0,
//                "frequency_penalty": 1
//            ]
//
//            let headers: HTTPHeaders = [
//                "Authorization": "Bearer \(perplexityKey)",
//                "Content-Type": "application/json"
//            ]
//            AF.request(
//                perplexityBaseUrl,
//                method: .post,
//                parameters: payload,
//                encoding: JSONEncoding.default,
//                headers: headers
//            ).responseJSON { response in
//                switch response.result {
//                case .success(let value):
//                    if let json = value as? [String: Any],
//                       let choices = json["choices"] as? [[String: Any]],
//                       let firstChoice = choices.first,
//                       let message = firstChoice["message"] as? [String: Any],
//                       let content = message["content"] as? String {
//                        var cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
//                        cleanedContent = cleanedContent.replacingOccurrences(of: "json", with: "")
//                        cleanedContent = cleanedContent.replacingOccurrences(of: "`", with: "")
//                        if let jsonData = cleanedContent.data(using: .utf8) {
//                            do {
//                                // Decode JSON into a Dictionary first to check "status"
//                                let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
//                                let formattedObject = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
//                                print("ARTICLES =======\n")
//                                print(String(decoding: formattedObject, as: UTF8.self))
////                                print(jsonObject)
//
//                                // Extract "result" from JSON
//                                if let articlesArray = jsonObject?["articles"] {
//                                    let articleData = try JSONSerialization.data(withJSONObject: articlesArray)
//                                    
//                                    // Decode into [Articles]
//                                    do {
//                                        let articles = try JSONDecoder().decode([Article].self, from: articleData)
//                                        print("✅ Successfully decoded Articles")
//                                        completion(.success(articles))
//
//                                    } catch let decodingError as DecodingError {
//                                        switch decodingError {
//                                        case .keyNotFound(let key, let context):
//                                            print("❌ Missing Key: \(key.stringValue) - \(context.debugDescription)")
//                                        case .typeMismatch(let type, let context):
//                                            print("❌ Type Mismatch: \(type) - \(context.debugDescription)")
//                                        case .valueNotFound(let type, let context):
//                                            print("❌ Value Missing: \(type) - \(context.debugDescription)")
//                                        case .dataCorrupted(let context):
//                                            print("❌ Data Corrupted: \(context.debugDescription)")
//                                        default:
//                                            print("❌ Decoding Error: \(decodingError.localizedDescription)")
//                                        }
//                                        completion(.failure(decodingError))
//                                    }
//
//                                } else {
//                                    completion(.failure(NSError(
//                                        domain: "",
//                                        code: 2,
//                                        userInfo: [NSLocalizedDescriptionKey: "Missing 'result' field in JSON."]
//                                    )))
//                                }
//                            } catch {
//                                completion(.failure(NSError(
//                                    domain: "",
//                                    code: 3,
//                                    userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON response."]
//                                )))
//                            }
//                        } else {
//                            completion(.failure(NSError(
//                                domain: "",
//                                code: 4,
//                                userInfo: [NSLocalizedDescriptionKey: "Invalid response format."]
//                            )))
//                        }
//
//                    } else {
//                        let error = NSError(
//                            domain: "",
//                            code: 1,
//                            userInfo: [NSLocalizedDescriptionKey: "Missing 'choices' field in response."]
//                        )
//                        completion(.failure(error)) // ✅ No throw, just return failure
//                    }
//
//                case .failure(let error):
//                    print("❌ Perplexity API Request Failed: \(error.localizedDescription)")
//                    completion(.failure(error)) // ✅ No throw, just return failure
//                }
//            }
//        } else {
//            let error = NSError(
//                domain: "",
//                code: 2,
//                userInfo: [NSLocalizedDescriptionKey: "Failed to load prompt file."]
//            )
//            completion(.failure(error)) // ✅ Handle missing file case
//        }
//    }


    private func readStringFromFile(atPath path: String) -> String? {
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            return content
        } catch {
            print("Error reading file: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func extractTextFromResponse(_ response: String) -> String? {
        guard let data = response.data(using: .utf8) else { return nil }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let content = choices.first?["content"] as? String {
                return content
            }
        } catch {
            print("Error parsing JSON: \(error.localizedDescription)")
        }
        return nil
    }
}

func saveJSONToFile(jsonData: Data, fileName: String) {
    do {
        // Convert the JSON data to a JSON object (e.g. a dictionary)
        if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
            // Optionally, re-serialize the object (this step can also let you format the JSON)
            let formattedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            
            // Get the documents directory URL
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                // Append the desired file name to the directory URL
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                
                // Write the data to the file
                try formattedData.write(to: fileURL, options: .atomic)
                
                print("File saved successfully to: \(fileURL.path)")
            } else {
                print("Could not locate the documents directory.")
            }
        }
    } catch {
        print("Error saving JSON to file: \(error)")
    }
}

class RateLimiter {
    private let maxCalls: Int
    private let interval: TimeInterval
    private let countKey = "RateLimiterCount"
    private let resetKey = "RateLimiterLastReset"
    
    init(maxCalls: Int, interval: TimeInterval) {
        self.maxCalls = maxCalls
        self.interval = interval
        
        // Initialize the window start if not set
        if UserDefaults.standard.double(forKey: resetKey) == 0 {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: resetKey)
        }
    }
    
    /// Determines whether a call is allowed based on the number of calls in the current time window.
    func shouldAllow() -> Bool {
        let now = Date().timeIntervalSince1970
        let lastReset = UserDefaults.standard.double(forKey: resetKey)
        var count = UserDefaults.standard.integer(forKey: countKey)
        
        // If the current window has expired, reset the counter and window start time.
        if now - lastReset > interval {
            UserDefaults.standard.set(now, forKey: resetKey)
            count = 0
        }
        
        // Check if we've reached the maximum number of calls in the current window.
        if count < maxCalls {
            count += 1
            UserDefaults.standard.set(count, forKey: countKey)
            return true
        } else {
            return false
        }
    }
}

