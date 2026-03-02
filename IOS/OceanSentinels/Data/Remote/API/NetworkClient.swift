import Foundation
import os

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case invalidURL
    case unauthorized
    case forbidden
    case notFound
    case serverError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkUnavailable
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .unauthorized: return "Unauthorized — please login again"
        case .forbidden: return "Access denied"
        case .notFound: return "Resource not found"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown")"
        case .decodingError(let error): return "Data parsing error: \(error.localizedDescription)"
        case .networkUnavailable: return "Network unavailable"
        case .unknown(let error): return error.localizedDescription
        }
    }
}

// MARK: - Network Client

actor NetworkClient {
    static let shared = NetworkClient()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "Network")
    
    private var authToken: String?
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    // MARK: - Auth
    
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    func getAuthToken() -> String? {
        authToken
    }
    
    // MARK: - Request Building
    
    private func buildRequest(
        url: URL,
        method: String = "GET",
        body: Data? = nil,
        headers: [String: String] = [:],
        contentType: String = "application/json",
        requiresAuth: Bool = true
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.httpBody = body
        return request
    }
    
    // MARK: - Core Request
    
    func request<T: Decodable>(
        url: URL,
        method: String = "GET",
        body: (any Encodable)? = nil,
        headers: [String: String] = [:],
        requiresAuth: Bool = true
    ) async throws -> T {
        let bodyData: Data?
        if let body = body {
            bodyData = try encoder.encode(body)
        } else {
            bodyData = nil
        }
        
        let request = buildRequest(
            url: url,
            method: method,
            body: bodyData,
            headers: headers,
            requiresAuth: requiresAuth
        )
        
        logger.debug("\(method) \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(URLError(.badServerResponse))
        }
        
        logger.debug("Response: \(httpResponse.statusCode) (\(data.count) bytes)")
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                logger.error("Decoding error: \(error)")
                throw NetworkError.decodingError(error)
            }
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        default:
            let message = String(data: data, encoding: .utf8)
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }
    
    // MARK: - Form URL Encoded (for login)
    
    func requestFormEncoded<T: Decodable>(
        url: URL,
        formFields: [String: String],
        requiresAuth: Bool = false
    ) async throws -> T {
        let bodyString = formFields.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&")
        let bodyData = bodyString.data(using: .utf8)
        
        let request = buildRequest(
            url: url,
            method: "POST",
            body: bodyData,
            contentType: "application/x-www-form-urlencoded",
            requiresAuth: requiresAuth
        )
        
        logger.debug("POST (form) \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            let message = String(data: data, encoding: .utf8)
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }
    
    // MARK: - Multipart Upload
    
    func uploadMultipart<T: Decodable>(
        url: URL,
        fileData: Data,
        fileName: String,
        mimeType: String,
        fieldName: String = "photo"
    ) async throws -> T {
        let boundary = UUID().uuidString
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        let request = buildRequest(
            url: url,
            method: "POST",
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkError.serverError(statusCode: code, message: nil)
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Fire-and-forget (no response body)
    
    func requestVoid(
        url: URL,
        method: String = "DELETE",
        body: (any Encodable)? = nil,
        requiresAuth: Bool = true
    ) async throws {
        let bodyData: Data?
        if let body = body {
            bodyData = try encoder.encode(body)
        } else {
            bodyData = nil
        }
        
        let request = buildRequest(
            url: url,
            method: method,
            body: bodyData,
            requiresAuth: requiresAuth
        )
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200...299: return
        case 401: throw NetworkError.unauthorized
        case 403: throw NetworkError.forbidden
        case 404: throw NetworkError.notFound
        default:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, message: nil)
        }
    }
}
