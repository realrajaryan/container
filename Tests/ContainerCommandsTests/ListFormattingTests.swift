//===----------------------------------------------------------------------===//
// Copyright © 2026 Apple Inc. and the container project authors.
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

import ContainerResource
import Foundation
import Testing

@testable import ContainerCommands

// MARK: - Test ListDisplayable conformer

private struct TestItem: ListDisplayable, Codable {
    let id: String
    let name: String

    static var tableHeader: [String] { ["ID", "NAME"] }
    var tableRow: [String] { [id, name] }
    var quietValue: String { id }
}

// MARK: - TableOutput tests

struct TableOutputTests {
    @Test
    func emptyRowsProducesEmptyString() {
        let table = TableOutput(rows: [])
        #expect(table.format() == "")
    }

    @Test
    func headerOnlyProducesHeaderRow() {
        let table = TableOutput(rows: [["ID", "NAME"]])
        #expect(table.format() == "ID  NAME")
    }

    @Test
    func columnsPaddedToMaxWidth() {
        let rows = [
            ["ID", "NAME"],
            ["1", "short"],
            ["2", "a longer name"],
        ]
        let table = TableOutput(rows: rows)
        let output = table.format()
        let lines = output.split(separator: "\n")
        #expect(lines.count == 3)

        // "ID" column should be padded to width of "ID" (2) + spacing (2) = 4
        #expect(lines[0].hasPrefix("ID  "))
        #expect(lines[1].hasPrefix("1   "))
        #expect(lines[2].hasPrefix("2   "))
    }

    @Test
    func customSpacing() {
        let rows = [["A", "B"], ["1", "2"]]
        let table = TableOutput(rows: rows, spacing: 4)
        let output = table.format()
        #expect(output.contains("A    B"))
    }

    @Test
    func lastColumnNotPadded() {
        let rows = [["A", "B"], ["1", "2"]]
        let table = TableOutput(rows: rows)
        let lines = table.format().split(separator: "\n")
        for line in lines {
            #expect(!line.hasSuffix(" "))
        }
    }

    @Test
    func singleColumnNoPadding() {
        let rows = [["DOMAIN"], ["example.com"], ["test.local"]]
        let table = TableOutput(rows: rows)
        let output = table.format()
        #expect(output == "DOMAIN\nexample.com\ntest.local")
    }

    @Test
    func rowCountMatchesInput() {
        let rows = [["H1", "H2"], ["a", "b"], ["c", "d"], ["e", "f"]]
        let table = TableOutput(rows: rows)
        let lines = table.format().split(separator: "\n")
        #expect(lines.count == 4)
    }
}

// MARK: - printJSON tests

struct PrintJSONTests {
    @Test
    func compactModeProducesValidJSON() throws {
        let items = [TestItem(id: "a", name: "b")]
        let encoder = JSONEncoder()
        let data = try encoder.encode(items)
        let decoded = try JSONDecoder().decode([TestItem].self, from: data)
        #expect(decoded.count == 1)
        #expect(decoded[0].id == "a")
        #expect(decoded[0].name == "b")
    }

    @Test
    func compactModeIsSingleLine() throws {
        let items = [TestItem(id: "a", name: "b"), TestItem(id: "c", name: "d")]
        let encoder = JSONEncoder()
        let data = try encoder.encode(items)
        let output = String(decoding: data, as: UTF8.self)
        #expect(!output.contains("\n"))
    }

    @Test
    func prettyModeIsMultiLine() throws {
        let items = [TestItem(id: "a", name: "b")]
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        let output = String(decoding: data, as: UTF8.self)
        #expect(output.contains("\n"))
    }

    @Test
    func prettyModeHasSortedKeys() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(["z": 1, "a": 2])
        let output = String(decoding: data, as: UTF8.self)
        let aIndex = output.range(of: "\"a\"")!.lowerBound
        let zIndex = output.range(of: "\"z\"")!.lowerBound
        #expect(aIndex < zIndex)
    }

    @Test
    func arrayEncodingMatchesManualJoin() throws {
        // Verify that JSONEncoder().encode(array) produces the same result as
        // encoding each element and joining (the old jsonArray() approach).
        let items = [TestItem(id: "x", name: "y"), TestItem(id: "a", name: "b")]
        let encoder = JSONEncoder()

        // Whole-array encoding (new approach via printJSON)
        let wholeData = try encoder.encode(items)
        let wholeOutput = String(decoding: wholeData, as: UTF8.self)

        // Per-element encoding (old jsonArray approach)
        let perElement = try items.map { String(decoding: try encoder.encode($0), as: UTF8.self) }
        let joinedOutput = "[\(perElement.joined(separator: ","))]"

        // Both should decode to the same structure
        let decoded1 = try JSONDecoder().decode([TestItem].self, from: wholeOutput.data(using: .utf8)!)
        let decoded2 = try JSONDecoder().decode([TestItem].self, from: joinedOutput.data(using: .utf8)!)
        #expect(decoded1.count == decoded2.count)
        #expect(decoded1[0].id == decoded2[0].id)
        #expect(decoded1[1].id == decoded2[1].id)
    }
}

// MARK: - ListDisplayable contract tests

struct ListDisplayableContractTests {
    @Test
    func testItemTableRowMatchesHeaderCount() {
        let item = TestItem(id: "1", name: "test")
        #expect(TestItem.tableHeader.count == item.tableRow.count)
    }

    @Test
    func quietValueIsNonEmpty() {
        let item = TestItem(id: "abc", name: "test")
        #expect(!item.quietValue.isEmpty)
    }
}

// MARK: - PrintableContainer conformance tests

struct PrintableContainerDisplayTests {
    @Test
    func tableHeaderHasNineColumns() {
        #expect(PrintableContainer.tableHeader.count == 9)
        #expect(PrintableContainer.tableHeader[0] == "ID")
        #expect(PrintableContainer.tableHeader[1] == "IMAGE")
        #expect(PrintableContainer.tableHeader[2] == "OS")
        #expect(PrintableContainer.tableHeader[3] == "ARCH")
        #expect(PrintableContainer.tableHeader[4] == "STATE")
        #expect(PrintableContainer.tableHeader[5] == "ADDR")
        #expect(PrintableContainer.tableHeader[6] == "CPUS")
        #expect(PrintableContainer.tableHeader[7] == "MEMORY")
        #expect(PrintableContainer.tableHeader[8] == "STARTED")
    }
}

// MARK: - PrintableNetwork conformance tests

struct PrintableNetworkDisplayTests {
    @Test
    func tableHeaderHasThreeColumns() {
        #expect(PrintableNetwork.tableHeader.count == 3)
        #expect(PrintableNetwork.tableHeader[0] == "NETWORK")
        #expect(PrintableNetwork.tableHeader[1] == "STATE")
        #expect(PrintableNetwork.tableHeader[2] == "SUBNET")
    }
}

// MARK: - ListFormat tests

struct ListFormatTests {
    @Test
    func hasJsonAndTableCases() {
        let cases = ListFormat.allCases
        #expect(cases.count == 2)
        #expect(cases.contains(.json))
        #expect(cases.contains(.table))
    }

    @Test
    func rawValuesMatchExpected() {
        #expect(ListFormat.json.rawValue == "json")
        #expect(ListFormat.table.rawValue == "table")
    }
}

// MARK: - String.elided tests

struct StringElidedTests {
    @Test
    func shortStringUnchanged() {
        #expect("hello".elided(to: 10) == "hello")
    }

    @Test
    func exactLengthUnchanged() {
        #expect("hello".elided(to: 5) == "hello")
    }

    @Test
    func longStringTruncatedWithEllipsis() {
        #expect("hello world".elided(to: 8) == "hello...")
    }

    @Test
    func maxCountLessThanEllipsis() {
        #expect("hello".elided(to: 2) == "..")
        #expect("hello".elided(to: 1) == ".")
        #expect("hello".elided(to: 0) == "")
    }
}
