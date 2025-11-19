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

struct DiskUsageTests {

    @Test("DiskUsageStats JSON encoding and decoding")
    func testJSONSerialization() throws {
        let stats = DiskUsageStats(
            images: ResourceUsage(total: 10, active: 5, size: 1024, reclaimable: 512),
            containers: ResourceUsage(total: 3, active: 2, size: 2048, reclaimable: 1024),
            volumes: ResourceUsage(total: 7, active: 4, size: 4096, reclaimable: 2048)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(stats)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DiskUsageStats.self, from: data)

        #expect(decoded.images.total == stats.images.total)
        #expect(decoded.images.active == stats.images.active)
        #expect(decoded.images.size == stats.images.size)
        #expect(decoded.images.reclaimable == stats.images.reclaimable)

        #expect(decoded.containers.total == stats.containers.total)
        #expect(decoded.containers.active == stats.containers.active)
        #expect(decoded.containers.size == stats.containers.size)
        #expect(decoded.containers.reclaimable == stats.containers.reclaimable)

        #expect(decoded.volumes.total == stats.volumes.total)
        #expect(decoded.volumes.active == stats.volumes.active)
        #expect(decoded.volumes.size == stats.volumes.size)
        #expect(decoded.volumes.reclaimable == stats.volumes.reclaimable)
    }

    @Test("ResourceUsage with zero values")
    func testZeroValues() throws {
        let emptyUsage = ResourceUsage(total: 0, active: 0, size: 0, reclaimable: 0)

        let encoder = JSONEncoder()
        let data = try encoder.encode(emptyUsage)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ResourceUsage.self, from: data)

        #expect(decoded.total == 0)
        #expect(decoded.active == 0)
        #expect(decoded.size == 0)
        #expect(decoded.reclaimable == 0)
    }

    @Test("ResourceUsage with large values")
    func testLargeValues() throws {
        let largeUsage = ResourceUsage(
            total: 1000,
            active: 500,
            size: UInt64.max,
            reclaimable: UInt64.max / 2
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(largeUsage)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ResourceUsage.self, from: data)

        #expect(decoded.total == 1000)
        #expect(decoded.active == 500)
        #expect(decoded.size == UInt64.max)
        #expect(decoded.reclaimable == UInt64.max / 2)
    }

    @Test("ResourceUsage percentage calculations")
    func testPercentageCalculations() throws {
        // 0% reclaimable
        let noneReclaimable = ResourceUsage(total: 10, active: 10, size: 1000, reclaimable: 0)
        #expect(Double(noneReclaimable.reclaimable) / Double(noneReclaimable.size) == 0.0)

        // 50% reclaimable
        let halfReclaimable = ResourceUsage(total: 10, active: 5, size: 1000, reclaimable: 500)
        #expect(Double(halfReclaimable.reclaimable) / Double(halfReclaimable.size) == 0.5)

        // 100% reclaimable
        let allReclaimable = ResourceUsage(total: 10, active: 0, size: 1000, reclaimable: 1000)
        #expect(Double(allReclaimable.reclaimable) / Double(allReclaimable.size) == 1.0)
    }
}
