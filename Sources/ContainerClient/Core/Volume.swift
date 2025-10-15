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

/// A named or anonymous volume that can be mounted in containers.
public struct Volume: Sendable, Codable, Equatable, Identifiable {
    // id of the volume.
    public var id: String { name }
    // Name of the volume.
    public var name: String
    // Driver used to create the volume.
    public var driver: String
    // Filesystem format of the volume.
    public var format: String
    // The mount point of the volume on the host.
    public var source: String
    // Timestamp when the volume was created.
    public var createdAt: Date
    // User-defined key/value metadata.
    public var labels: [String: String]
    // Driver-specific options.
    public var options: [String: String]
    // Size of the volume in bytes (optional).
    public var sizeInBytes: UInt64?
    // Whether this is an anonymous volume.
    public var isAnonymous: Bool
    // The container ID that created this anonymous volume (if applicable).
    public var createdByContainerID: String?

    public init(
        name: String,
        driver: String = "local",
        format: String = "ext4",
        source: String,
        createdAt: Date = Date(),
        labels: [String: String] = [:],
        options: [String: String] = [:],
        sizeInBytes: UInt64? = nil,
        isAnonymous: Bool = false,
        createdByContainerID: String? = nil
    ) {
        self.name = name
        self.driver = driver
        self.format = format
        self.source = source
        self.createdAt = createdAt
        self.isAnonymous = isAnonymous
        self.createdByContainerID = createdByContainerID

        // Add reserved label for anonymous volumes to persist the flag
        var finalLabels = labels
        if isAnonymous {
            finalLabels["com.apple.container.volume.anonymous"] = "true"
            if let containerID = createdByContainerID {
                finalLabels["com.apple.container.volume.created-by"] = containerID
            }
        }
        self.labels = finalLabels
        self.options = options
        self.sizeInBytes = sizeInBytes
    }
}

/// Error types for volume operations.
public enum VolumeError: Error, LocalizedError {
    case volumeNotFound(String)
    case volumeAlreadyExists(String)
    case volumeInUse(String)
    case invalidVolumeName(String)
    case driverNotSupported(String)
    case storageError(String)

    public var errorDescription: String? {
        switch self {
        case .volumeNotFound(let name):
            return "Volume '\(name)' not found"
        case .volumeAlreadyExists(let name):
            return "Volume '\(name)' already exists"
        case .volumeInUse(let name):
            return "Volume '\(name)' is currently in use and cannot be accessed by another container, or deleted."
        case .invalidVolumeName(let name):
            return "Invalid volume name '\(name)'"
        case .driverNotSupported(let driver):
            return "Volume driver '\(driver)' is not supported"
        case .storageError(let message):
            return "Storage error: \(message)"
        }
    }
}

/// Volume storage management utilities.
public struct VolumeStorage {
    public static let volumeNamePattern = "^[A-Za-z0-9][A-Za-z0-9_.-]*$"
    public static let anonymousVolumePattern = "^anon-[0-9a-hjkmnp-tv-z]{26}$"
    public static let defaultVolumeSizeBytes: UInt64 = 512 * 1024 * 1024 * 1024  // 512GB

    // Crockford Base32 alphabet (lowercase, excludes i, l, o, u to avoid ambiguity)
    private static let base32Alphabet = "0123456789abcdefghjkmnpqrstvwxyz"
    private static let base32Mask: UInt64 = 0x1F  // 5 bits for base32 (2^5 = 32)

    public static func isValidVolumeName(_ name: String) -> Bool {
        guard name.count <= 255 else { return false }

        do {
            // Check if it's an anonymous volume name (anon-{ulid})
            let anonRegex = try Regex(anonymousVolumePattern)
            if (try? anonRegex.wholeMatch(in: name)) != nil {
                return true
            }

            // Check if it's a regular named volume
            let regex = try Regex(volumeNamePattern)
            return (try? regex.wholeMatch(in: name)) != nil
        } catch {
            return false
        }
    }

    /// Generates a ULID (Universally Unique Lexicographically Sortable Identifier)
    /// Returns a 26-character lowercase string in Crockford Base32 format
    public static func generateULID() -> String {
        // ULID format: 48-bit timestamp (6 bytes encoded as 10 base32 chars) + 80-bit randomness (10 bytes encoded as 16 base32 chars) = 26 chars total
        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000)  // milliseconds since epoch

        // Encode timestamp (48 bits = 10 base32 chars)
        var timestampChars: [Character] = []
        var ts = timestamp
        for _ in 0..<10 {
            let index = Int(ts & Self.base32Mask)
            timestampChars.insert(base32Alphabet[base32Alphabet.index(base32Alphabet.startIndex, offsetBy: index)], at: 0)
            ts >>= 5
        }
        var ulid = String(timestampChars)

        // Encode randomness (80 bits = 16 base32 chars)
        var randomBytes = [UInt8](repeating: 0, count: 10)
        if SecRandomCopyBytes(kSecRandomDefault, 10, &randomBytes) != errSecSuccess {
            // Fallback to use UUID for randomness but still encode as base32
            var uuid = UUID().uuid
            withUnsafeBytes(of: &uuid) { buffer in
                // Take first 10 bytes from UUID
                for i in 0..<min(10, buffer.count) {
                    randomBytes[i] = buffer[i]
                }
            }
        }

        // Convert random bytes to base32
        var bits: UInt64 = 0
        var bitsCount = 0
        for byte in randomBytes {
            bits = (bits << 8) | UInt64(byte)
            bitsCount += 8

            while bitsCount >= 5 {
                bitsCount -= 5
                let index = Int((bits >> bitsCount) & Self.base32Mask)
                ulid += String(base32Alphabet[base32Alphabet.index(base32Alphabet.startIndex, offsetBy: index)])
            }
        }

        return ulid
    }

    /// Generates an anonymous volume name with the format: anon-{ulid}
    public static func generateAnonymousVolumeName() -> String {
        "anon-\(generateULID())"
    }
}
