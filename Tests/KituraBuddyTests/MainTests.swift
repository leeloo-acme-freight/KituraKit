/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import XCTest
import Foundation
import Kitura
import SafetyContracts

@testable import KituraBuddy

class MainTests: XCTestCase {

    static var allTests: [(String, (MainTests) -> () throws -> Void)] {
        return [
            ("testClientGet", testClientGet),
            ("testClientGetErrorPath", testClientGetErrorPath),
            ("testClientGetSingle", testClientGetSingle),
            ("testClientGetSingleErrorPath", testClientGetSingleErrorPath),
            ("testClientPost", testClientPost),
            ("testClientPostErrorPath", testClientPostErrorPath),
            ("testClientPut", testClientPut),
            ("testClientPutErrorPath", testClientPutErrorPath),
            ("testClientPatch", testClientPatch),
            ("testClientPatchErrorPath", testClientPatchErrorPath),
            ("testClientDelete", testClientDelete),
            ("testClientDeleteSingle", testClientDeleteSingle),
            ("testClientDeleteInvalid", testClientDeleteInvalid)
        ]
    }

    private let controller = Controller(userStore: initialStore)

    private let client = KituraBuddy(baseURL: "http://localhost:8080")

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        Kitura.addHTTPServer(onPort: 8080, with: controller.router)
        Kitura.start()

    }

    override func tearDown() {
        Kitura.stop()
        super.tearDown()
    }

    func testClientGet() {
        let expectation1 = expectation(description: "A response is received from the server -> array of users")

        // Invoke GET operation on library
        client.get("/users") { (users: [User]?, error: ProcessHandlerError?) -> Void in
            guard let users = users else {
                XCTFail("Failed to get users! Error: \(String(describing: error))")
                return
            }
            XCTAssertEqual(users.count, 4)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientGetErrorPath() {
        let expectation1 = expectation(description: "An error is received from the server")

        // Invoke GET operation on library
        client.get("/notAValidRoute") { (users: [User]?, error: ProcessHandlerError?) -> Void in
            if case .notFound? = error {
                expectation1.fulfill()
            } else {
                XCTFail("Failed to get expected error from server: \(String(describing: error))")
                return
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientGetSingle() {
        let expectation1 = expectation(description: "A response is received from the server -> user")

        // Invoke GET operation on library
        let id = "1"
        client.get("/users", identifier: id) { (user: User?, error: ProcessHandlerError?) -> Void in
            guard let user = user else {
                XCTFail("Failed to get user! Error: \(String(describing: error))")
                return
            }
            XCTAssertEqual(user, initialStore[id]!)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientGetSingleErrorPath() {
        let expectation1 = expectation(description: "An error is received from the server")

        // Invoke GET operation on library
        let id = "1"
        client.get("/notAValidRoute", identifier: id) { (users: User?, error: ProcessHandlerError?) -> Void in
            if case .notFound? = error {
                expectation1.fulfill()
            } else {
                XCTFail("Failed to get expected error from server: \(String(describing: error))")
                return
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientPost() {
        let expectation1 = expectation(description: "A response is received from the server -> user")

        // Invoke POST operation on library
        let newUser = User(id: 5, name: "John Doe")

        client.post("/users", data: newUser) { (user: User?, error: ProcessHandlerError?) -> Void in
            guard let user = user else {
                XCTFail("Failed to post user! Error: \(String(describing: error))")
                return
            }

            XCTAssertEqual(user, newUser)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientPostErrorPath() {
        let expectation1 = expectation(description: "An error is received from the server")

        // Invoke POST operation on library
        let newUser = User(id: 5, name: "John Doe")

        client.post("/notAValidRoute", data: newUser) { (users: User?, error: ProcessHandlerError?) -> Void in
            if case .notFound? = error {
                expectation1.fulfill()
            } else {
                XCTFail("Failed to get expected error: \(String(describing: error))")
                return
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientPut() {
        let expectation1 = expectation(description: "A response is received from the server -> user")

        // Invoke PUT operation on library
        let expectedUser = User(id: 5, name: "John Doe")

        client.put("/users", identifier: String(expectedUser.id), data: expectedUser) { (user: User?, error: ProcessHandlerError?) -> Void in

            guard let user = user else {
                XCTFail("Failed to put user! Error: \(String(describing: error))")
                return
            }

            XCTAssertEqual(user, expectedUser)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientPutErrorPath() {
        let expectation1 = expectation(description: "An error is received from the server")

        // Invoke PUT operation on library
        let expectedUser = User(id: 5, name: "John Doe")

        client.put("/notAValidRoute", identifier: String(expectedUser.id), data: expectedUser) { (users: User?, error: ProcessHandlerError?) -> Void in
            if case .notFound? = error {
                expectation1.fulfill()
            } else {
                XCTFail("Failed to get expected error: \(String(describing: error))")
                return
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientPatch() {
        let expectation1 = expectation(description: "A response is received from the server -> user")

        let expectedUser = User(id: 4, name: "John Doe")
        
        client.patch("/users", identifier: String(describing: expectedUser.id), data: expectedUser) { (user: User?, error: ProcessHandlerError?) -> Void in
            guard let user = user else {
                XCTFail("Failed to patch user! Error: \(String(describing: error))")
                return
            }

            XCTAssertEqual(user, expectedUser)

            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientPatchErrorPath() {
        let expectation1 = expectation(description: "An error is received from the server")
        let expectedUser = User(id: 4, name: "John Doe")

        client.patch("/notAValidRoute", identifier: String(describing: expectedUser.id), data: expectedUser) { (users: UserOptional?, error: ProcessHandlerError?) -> Void in
            if case .notFound? = error {
                expectation1.fulfill()
            } else {
                XCTFail("Failed to get expected error from server: \(String(describing: error))")
                return
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

     func testClientDeleteSingle() {
        let expectation1 = expectation(description: "No error is received from the server")

        // Invoke GET operation on library
        client.delete("/users", identifier: "1") { error in
            guard error == nil else {
                XCTFail("Failed to delete user! Error: \(String(describing: error))")
                return
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    // delete tests get executed first and cause get individual user tests to fail as the users have been deleted

    func testClientDelete() {
        let expectation1 = expectation(description: "No error is received from the server")

        client.delete("/users") { error in
            guard error == nil else {
                XCTFail("Failed to delete user! Error: \(String(describing: error))")
                return
            }

            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientDeleteInvalid() {
        let expectation1 = expectation(description: "An error is received from the server")

        client.delete("/notAValidRoute") { error in
            if case .notFound? = error {
                expectation1.fulfill()
            } else {
                XCTFail("Failed to get expected error: \(String(describing: error))")
                return
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

}
