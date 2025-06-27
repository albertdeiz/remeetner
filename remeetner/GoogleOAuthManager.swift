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
    let items: [CalendarEvent]
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

    private let scopes = [
        OIDScopeOpenID,
        OIDScopeProfile,
        "https://www.googleapis.com/auth/calendar.readonly"
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
                additionalParameters: nil
            )

            self.currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: request,
                presenting: presentingWindow
            ) { authState, error in
                if let authState = authState {
                    self.authState = authState
                    self.isAuthenticated = true
                    self.saveAuthState()
                    print("Access Token: \(authState.lastTokenResponse?.accessToken ?? "none")")
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
    
    func ensureFreshToken(completion: @escaping (String?) -> Void) {
        authState?.performAction { accessToken, idToken, error in
            if let error = error {
                print("Error al obtener token válido:", error.localizedDescription)
                completion(nil)
            } else {
                completion(accessToken)
            }
        }
    }
    
    func fetchTodayEvents(completion: @escaping ([CalendarEvent]?) -> Void) {
        ensureFreshToken { token in
            
            guard let token = token else {
                print("No access token disponible")
                completion(nil)
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
                guard let data else {
                    print("Error: \(error?.localizedDescription ?? "sin datos")")
                    completion(nil)
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(CalendarEventListResponse.self, from: data)
                    print(decoded)
                    DispatchQueue.main.async {
                        completion(decoded.items)
                    }
                } catch {
                    print("Error decoding events: \(error)")
                    completion(nil)
                }
            }.resume()
        }
    }
}
