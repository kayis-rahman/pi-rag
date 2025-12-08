//
//  E2EAuthenticationTests.swift
//  TimeBeamUITests
//
//  Created by TimeBeam Team
//  End-to-end authentication tests connecting to live backend
//

import XCTest

final class E2EAuthenticationTests: TimeBeamE2ETestBase {

    // MARK: - Backend Health Check

    func testBackendConnectivity() throws {
        // Verify backend is reachable and seeded data is available
        let backendURL = TestConfiguration.e2eBackendURL

        // Test health endpoint
        let healthURL = URL(string: "\(backendURL)/api/auth/health")!
        var request = URLRequest(url: healthURL)
        request.httpMethod = "GET"

        let expectation = expectation(description: "Backend health check")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                XCTFail("Backend not reachable: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertTrue((200..<300).contains(httpResponse.statusCode),
                             "Backend should return success status")
            }

            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    // MARK: - Authentication Flow Tests

    func testUserLoginWithTestAccount() throws {
        // Test login with the seeded test user
        let testEmail = TestConfiguration.testUserEmail

        // Verify user exists in backend by attempting login
        let loginURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/auth/login")!
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginBody = ["email": testEmail]
        request.httpBody = try JSONSerialization.data(withJSONObject: loginBody)

        let expectation = expectation(description: "User login")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                XCTFail("Login request failed: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 200,
                             "Login should succeed for seeded test user")

                if httpResponse.statusCode == 200,
                   let data = data {
                    do {
                        let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        XCTAssertNotNil(responseJSON?["accessToken"],
                                      "Login response should contain access token")
                    } catch {
                        XCTFail("Failed to parse login response: \(error)")
                    }
                }
            }

            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    func testUserLoginWithInvalidEmail() throws {
        // Test login with non-existent email
        let invalidEmail = "nonexistent@example.com"

        let loginURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/auth/login")!
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginBody = ["email": invalidEmail]
        request.httpBody = try JSONSerialization.data(withJSONObject: loginBody)

        let expectation = expectation(description: "Invalid user login")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                XCTFail("Login request failed: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 401,
                             "Login should fail for non-existent user")
            }

            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    func testAutoRegistrationOnFirstLogin() throws {
        // Test that new users are auto-registered on first login
        let newUserEmail = "newuser-\(UUID().uuidString)@example.com"

        let loginURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/auth/login")!
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginBody = ["email": newUserEmail]
        request.httpBody = try JSONSerialization.data(withJSONObject: loginBody)

        let expectation = expectation(description: "Auto-registration login")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                XCTFail("Login request failed: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 200,
                             "Auto-registration should succeed")

                if httpResponse.statusCode == 200,
                   let data = data {
                    do {
                        let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        XCTAssertNotNil(responseJSON?["accessToken"],
                                      "Auto-registration response should contain access token")
                    } catch {
                        XCTFail("Failed to parse auto-registration response: \(error)")
                    }
                }
            }

            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    // MARK: - Task Data Verification

    func testSeededTestDataAvailability() throws {
        // Verify that seeded test data is available via API
        let tasksURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/tasks")!
        var request = URLRequest(url: tasksURL)
        request.httpMethod = "GET"

        // First login to get token
        let token = try loginAndGetToken(email: TestConfiguration.testUserEmail)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let expectation = expectation(description: "Fetch seeded tasks")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                XCTFail("Tasks fetch failed: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let tasks = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                    XCTAssertNotNil(tasks, "Should receive tasks array")
                    XCTAssertEqual(tasks?.count, TestConfiguration.ExpectedData.initialTaskCount,
                                 "Should have expected number of seeded tasks")

                    // Verify specific task exists
                    let taskTitles = tasks?.compactMap { $0["title"] as? String }
                    XCTAssertTrue(taskTitles?.contains("Complete project documentation") ?? false,
                                "Should contain seeded documentation task")

                } catch {
                    XCTFail("Failed to parse tasks response: \(error)")
                }
            }

            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    // MARK: - Helper Methods

    private func loginAndGetToken(email: String) throws -> String {
        let loginURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/auth/login")!
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginBody = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: loginBody)

        let semaphore = DispatchSemaphore(value: 0)
        var token: String?

        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    token = responseJSON?["accessToken"] as? String
                } catch {
                    XCTFail("Failed to parse login response: \(error)")
                }
            }
        }.resume()

        semaphore.wait()
        return try XCTUnwrap(token, "Should receive access token")
    }
}
