//===----------------------------------------------------------------------===//
// Copyright © 2025 Apple Inc. and the container project authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//===----------------------------------------------------------------------===//

import Foundation
import Testing

@testable import ContainerClient

struct ULIDTests {

    @Test("ULID format validation")
    func testULIDFormat() {
        let ulid = VolumeStorage.generateULID()

        // Should be exactly 26 characters
        #expect(ulid.count == 26, "ULID should be 26 characters, got \(ulid.count)")

        // Should only contain valid Crockford Base32 characters (lowercase)
        let validChars = CharacterSet(charactersIn: "0123456789abcdefghjkmnpqrstvwxyz")
        let ulidChars = CharacterSet(charactersIn: ulid)
        #expect(validChars.isSuperset(of: ulidChars), "ULID contains invalid characters: \(ulid)")

        // Should not contain ambiguous characters
        let ambiguousChars = ["i", "l", "o", "u"]
        for char in ambiguousChars {
            #expect(!ulid.contains(char), "ULID should not contain ambiguous character '\(char)'")
        }
    }

    @Test("Anonymous volume name format")
    func testAnonymousVolumeNameFormat() {
        let name = VolumeStorage.generateAnonymousVolumeName()

        // Should start with "anon-"
        #expect(name.starts(with: "anon-"), "Anonymous volume name should start with 'anon-'")

        // Should be exactly 31 characters (5 + 26)
        #expect(name.count == 31, "Anonymous volume name should be 31 characters, got \(name.count)")

        // Should be valid volume name
        #expect(VolumeStorage.isValidVolumeName(name), "Anonymous volume name should be valid")
    }

    @Test("ULID uniqueness")
    func testULIDUniqueness() {
        // Generate 1000 ULIDs and verify they're all unique
        var ulids = Set<String>()
        let count = 1000

        for _ in 0..<count {
            let ulid = VolumeStorage.generateULID()
            ulids.insert(ulid)
        }

        #expect(ulids.count == count, "All \(count) ULIDs should be unique, got \(ulids.count) unique values")
    }

    @Test("ULID time ordering")
    func testULIDTimeOrdering() {
        // Generate first ULID
        let ulid1 = VolumeStorage.generateULID()

        // Wait a small amount to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // Generate second ULID
        let ulid2 = VolumeStorage.generateULID()

        // Newer ULID should be lexicographically greater
        #expect(ulid2 > ulid1, "Newer ULID '\(ulid2)' should sort after older ULID '\(ulid1)'")
    }

    @Test("ULID character set validation")
    func testULIDCharacterSet() {
        // Generate multiple ULIDs and verify character set
        for _ in 0..<100 {
            let ulid = VolumeStorage.generateULID()

            // Check each character
            for char in ulid {
                let charStr = String(char)
                let isValid = "0123456789abcdefghjkmnpqrstvwxyz".contains(charStr)
                #expect(isValid, "Invalid character '\(char)' in ULID: \(ulid)")

                // Verify no ambiguous characters
                #expect(charStr != "i", "ULID should not contain 'i'")
                #expect(charStr != "l", "ULID should not contain 'l'")
                #expect(charStr != "o", "ULID should not contain 'o'")
                #expect(charStr != "u", "ULID should not contain 'u'")
            }
        }
    }
}
