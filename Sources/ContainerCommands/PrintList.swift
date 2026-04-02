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

import Foundation

/// Prints an `Encodable` value as JSON to stdout.
func printJSON<T: Encodable>(_ value: T, pretty: Bool = false) throws {
    let encoder = JSONEncoder()
    if pretty {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }
    let data = try encoder.encode(value)
    print(String(decoding: data, as: UTF8.self))
}

/// Prints a list of displayable items as either a table or quiet-mode identifiers.
///
/// JSON output is not handled here — each command encodes its own data model
/// via ``printJSON(_:)`` before reaching this function.
func printList<T: ListDisplayable>(_ items: [T], quiet: Bool) {
    if quiet {
        for item in items {
            print(item.quietValue)
        }
    } else {
        var rows: [[String]] = [T.tableHeader]
        for item in items {
            rows.append(item.tableRow)
        }
        let formatter = TableOutput(rows: rows)
        print(formatter.format())
    }
}
