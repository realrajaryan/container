//===----------------------------------------------------------------------===//
// Copyright © 2025 Apple Inc. and the container project authors. All rights reserved.
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
import Foundation

extension Application.VolumeCommand {
    struct VolumeCreate: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "create",
            abstract: "Create a volume"
        )

        @Argument(help: "Volume name")
        var name: String

        @Option(name: .customLong("opt"), parsing: .upToNextOption, help: "Set driver specific options")
        var driverOpts: [String] = []

        @Option(name: .customLong("label"), parsing: .upToNextOption, help: "Set metadata on a volume")
        var labels: [String] = []

        func run() async throws {
            let parsedDriverOpts = Utility.parseKeyValuePairs(driverOpts)
            let parsedLabels = Utility.parseKeyValuePairs(labels)

            let request = VolumeCreateRequest(
                name: name,
                driver: "local",
                driverOpts: parsedDriverOpts,
                labels: parsedLabels
            )

            let volume = try await ClientVolume.create(request)
            print(volume.name)
        }
    }
}
