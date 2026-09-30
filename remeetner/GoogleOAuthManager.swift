//
//  GoogleOAuthManager.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import AppAuth
import Foundation
import AppKit

struct CalendarEvent: Decodable {
    struct EventDateTime: Decodable {
        let dateTime: String?
        let date: String?
    }

    let id: String
    let summary: String?
    let description: String?
    let start: EventDateTime
    let end: EventDateTime
    let hangoutLink: String?
}

struct CalendarEventListResponse: Decodable {
    let items: [CalendarEvent]?
}

/// Error body returned by Google APIs, e.g. `{"error": {"code": 403, "message": "...", "errors": [{"reason": "..."}]}}`
struct GoogleAPIErrorResponse: Decodable {
    struct Body: Decodable {
        struct Detail: Decodable {
            let reason: String?
        }

        let code: Int?
        let message: String?
        let status: String?
        let errors: [Detail]?
        let details: [Detail]?
    }

    let error: Body

    var reasons: [String] {
        ((error.errors ?? []) + (error.details ?? [])).compactMap(\.reason)
    }
}

class GoogleOAuthManager: NSObject {
    @Published private(set) var isAuthenticated: Bool = false

    static let shared = GoogleOAuthManager()
    private let authStateKey = AppConfiguration.StorageKeys.authState

    private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private(set) var authState: OIDAuthState?

    private let clientID = AppConfiguration.clientID
    private let redirectURI = URL(string: AppConfiguration.redirectURIString)!
    private let issuer = URL(string: AppConfiguration.issuerURLString)!

    private static let calendarScope = "https://www.googleapis.com/auth/calendar.readonly"

    private let scopes = [
        OIDScopeOpenID,
        OIDScopeProfile,
        calendarScope
    ]
    
    override init() {
        super.init()
        loadAuthState()
    }
    
    func saveAuthState() {
        guard let authState = authState else { return }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: authStateKey)
        } catch {
            print("Error al guardar authState: \(error)")
        }
    }

    func loadAuthState() {
        if let data = UserDefaults.standard.data(forKey: authStateKey) {
            do {
                let restoredState = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data)
                self.authState = restoredState
                self.isAuthenticated = true
            } catch {
                print("Error al deserializar authState: \(error)")
            }
        }
    }

    func startAuthorization(presentingWindow: NSWindow, completion: @escaping (Bool) -> Void) {
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { config, error in
            guard let config = config else {
                print("Error discovering config: \(error?.localizedDescription ?? "unknown")")
                completion(false)
                return
            }

            let request = OIDAuthorizationRequest(
                configuration: config,
                clientId: self.clientID,
                scopes: self.scopes,
                redirectURL: self.redirectURI,
                responseType: OIDResponseTypeCode,
                // Always show the consent screen so the user can grant the calendar scope again
                additionalParameters: ["prompt": "consent"]
            )

            self.currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: request,
                presenting: presentingWindow
            ) { authState, error in
                if let authState = authState {
                    self.authState = authState
                    self.isAuthenticated = true
                    self.saveAuthState()
                    completion(true)
                } else {
                    print("OAuth error: \(error?.localizedDescription ?? "unknown")")
                    completion(false)
                }
            }
        }
    }

    func handleRedirectURL(_ url: URL) -> Bool {
        if let currentFlow = currentAuthorizationFlow,
           currentFlow.resumeExternalUserAgentFlow(with: url) {
            currentAuthorizationFlow = nil
            return true
        }
        return false
    }

    func getAccessToken() -> String? {
        return authState?.lastTokenResponse?.accessToken
    }
    
    func clearAuthState() {
        self.authState = nil
        self.isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: authStateKey)
    }
    
    /// Whether the last token response includes the calendar scope. Google lets the user
    /// uncheck it on the consent screen, so being authenticated doesn't imply calendar access.
    /// Returns nil when the granted scopes are unknown.
    var hasCalendarScope: Bool? {
        guard let scope = authState?.lastTokenResponse?.scope ?? authState?.scope else { return nil }
        return scope.split(separator: " ").contains { $0 == Self.calendarScope }
    }

    func ensureFreshToken(completion: @escaping (Result<String, RemeetnerError>) -> Void) {
        guard let authState = authState else {
            completion(.failure(.sessionExpired))
            return
        }

        authState.performAction { accessToken, _, error in
            if let accessToken = accessToken {
                completion(.success(accessToken))
            } else if let error = error as NSError?, error.domain == NSURLErrorDomain {
                completion(.failure(.networkError(error)))
            } else {
                print("Error al obtener token válido:", error?.localizedDescription ?? "unknown")
                completion(.failure(.sessionExpired))
            }
        }
    }
    
    func fetchTodayEvents(completion: @escaping (Result<[CalendarEvent], RemeetnerError>) -> Void) {
        ensureFreshToken { tokenResult in
            let token: String
            switch tokenResult {
            case .success(let value):
                token = value
            case .failure(let error):
                completion(.failure(error))
                return
            }

            if self.hasCalendarScope == false {
                completion(.failure(.calendarPermissionMissing))
                return
            }
            
            var components = URLComponents(string: "\(AppConfiguration.calendarAPIBaseURL)/calendars/primary/events")!

            let today = Date()
            let currentHour = Calendar.current.component(.hour, from: today)
            let sinceNow = Calendar.current.date(bySettingHour: currentHour, minute: 00, second: 00, of: today)!
            let now = ISO8601DateFormatter().string(from: today)
            
            // ISO 8601 de fin del día
            let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: today)!
            let end = ISO8601DateFormatter().string(from: endOfDay)
            
            components.queryItems = [
                URLQueryItem(name: "timeMin", value: now),
                URLQueryItem(name: "timeMax", value: end),
                URLQueryItem(name: "singleEvents", value: "true"),
                URLQueryItem(name: "orderBy", value: "startTime")
            ]
            
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(.networkError(error)))
                    return
                }

                guard let data, let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.eventsFetchFailed))
                    return
                }

                guard (200..<300).contains(httpResponse.statusCode) else {
                    completion(.failure(Self.classifyAPIError(statusCode: httpResponse.statusCode, data: data)))
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(CalendarEventListResponse.self, from: data)
                    completion(.success(decoded.items ?? []))
                } catch {
                    print("Error decoding events: \(error)")
                    completion(.failure(.eventsFetchFailed))
                }
            }.resume()
        }
    }

    private static func classifyAPIError(statusCode: Int, data: Data) -> RemeetnerError {
        let apiError = try? JSONDecoder().decode(GoogleAPIErrorResponse.self, from: data)
        let reasons = apiError?.reasons ?? []
        let message = apiError?.error.message ?? HTTPURLResponse.localizedString(forStatusCode: statusCode)
        print("Google Calendar API error \(statusCode): \(message) \(reasons)")

        if statusCode == 401 {
            return .sessionExpired
        }
        if reasons.contains(where: { ["accessNotConfigured", "SERVICE_DISABLED"].contains($0) }) {
            return .calendarAPIDisabled
        }
        if reasons.contains(where: { ["insufficientPermissions", "ACCESS_TOKEN_SCOPE_INSUFFICIENT"].contains($0) }) {
            return .calendarPermissionMissing
        }
        return .googleAPIError("\(statusCode) — \(message)")
    }
}
