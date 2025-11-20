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

import ArgumentParser
import ContainerClient
import ContainerizationOCI
import Foundation

extension Application {
    public struct ImagePrune: AsyncParsableCommand {
        public init() {}
        public static let configuration = CommandConfiguration(
            commandName: "prune",
            abstract: "Remove unreferenced and dangling images")

        @Flag(name: .shortAndLong, help: "Remove all unused images, not just dangling ones")
        var all: Bool = false

        @OptionGroup
        var global: Flags.Global

        public func run() async throws {
            let allImages = try await ClientImage.list()

            let keepingReferences: [String]
            if all {
                let containers = try await ClientContainer.list()
                var imagesInUse = Set<String>()
                for container in containers {
                    imagesInUse.insert(container.configuration.image.reference)
                }

                keepingReferences = allImages.filter { image in
                    imagesInUse.contains(image.reference)
                }.map { $0.reference }
            } else {
                // Default: keep all tagged images (remove dangling/untagged)
                keepingReferences = allImages.filter { image in
                    hasTag(image.reference)
                }.map { $0.reference }
            }

            let (deleted, size) = try await ClientImage.pruneImages(keepingReferences: keepingReferences)

            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            let freed = formatter.string(fromByteCount: Int64(size))

            if !deleted.isEmpty {
                print("Deleted Images:")
                for item in deleted {
                    if item.starts(with: "sha256:") {
                        print("deleted: \(item)")
                    } else {
                        print("untagged: \(item)")
                    }
                }
                print()
            }

            print("Reclaimed \(freed) in disk space")
        }

        private func hasTag(_ reference: String) -> Bool {
            do {
                let ref = try ContainerizationOCI.Reference.parse(reference)
                return ref.tag != nil && !ref.tag!.isEmpty
            } catch {
                return false
            }
        }
    }
}
