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

#if os(macOS)
import Foundation
import ContainerXPC

/// Keys for XPC fields.
public enum XPCKeys: String {
    /// Route key.
    case route
    /// Container array key.
    case containers
    /// ID key.
    case id
    // ID for a process.
    case processIdentifier
    /// Container configuration key.
    case containerConfig
    /// Container options key.
    case containerOptions
    /// Vsock port number key.
    case port
    /// Exit code for a process
    case exitCode
    /// An event that occurred in a container
    case containerEvent
    /// Error key.
    case error
    /// FD to a container resource key.
    case fd
    /// FDs pointing to container logs key.
    case logs
    /// Options for stopping a container key.
    case stopOptions
    /// Plugins
    case pluginName
    case plugins
    case plugin

    /// Health check request.
    case ping

    /// Process request keys.
    case signal
    case snapshot
    case stdin
    case stdout
    case stderr
    case status
    case width
    case height
    case processConfig

    /// Update progress
    case progressUpdateEndpoint
    case progressUpdateSetDescription
    case progressUpdateSetSubDescription
    case progressUpdateSetItemsName
    case progressUpdateAddTasks
    case progressUpdateSetTasks
    case progressUpdateAddTotalTasks
    case progressUpdateSetTotalTasks
    case progressUpdateAddItems
    case progressUpdateSetItems
    case progressUpdateAddTotalItems
    case progressUpdateSetTotalItems
    case progressUpdateAddSize
    case progressUpdateSetSize
    case progressUpdateAddTotalSize
    case progressUpdateSetTotalSize

    /// Network
    case networkId
    case networkConfig
    case networkState
    case networkStates

    /// Kernel
    case kernel
    case kernelTarURL
    case kernelFilePath
    case systemPlatform

    /// Volume
    case volume
    case volumeName
    case volumeCreateRequest
    case volumeDeleteRequest
    case volumeListResponse
    case volumeInspectResponse
}

public enum XPCRoute: String {
    case listContainer
    case createContainer
    case deleteContainer
    case containerLogs
    case containerEvent

    case pluginLoad
    case pluginGet
    case pluginRestart
    case pluginUnload
    case pluginList

    case networkCreate
    case networkDelete
    case networkList

    case volumeCreate
    case volumeDelete
    case volumeList
    case volumeInspect

    case ping

    case installKernel
    case getDefaultKernel
}

extension XPCMessage {
    public init(route: XPCRoute) {
        self.init(route: route.rawValue)
    }

    public func data(key: XPCKeys) -> Data? {
        data(key: key.rawValue)
    }

    public func dataNoCopy(key: XPCKeys) -> Data? {
        dataNoCopy(key: key.rawValue)
    }

    public func set(key: XPCKeys, value: Data) {
        set(key: key.rawValue, value: value)
    }

    public func string(key: XPCKeys) -> String? {
        string(key: key.rawValue)
    }

    public func set(key: XPCKeys, value: String) {
        set(key: key.rawValue, value: value)
    }

    public func bool(key: XPCKeys) -> Bool {
        bool(key: key.rawValue)
    }

    public func set(key: XPCKeys, value: Bool) {
        set(key: key.rawValue, value: value)
    }

    public func uint64(key: XPCKeys) -> UInt64 {
        uint64(key: key.rawValue)
    }

    public func set(key: XPCKeys, value: UInt64) {
        set(key: key.rawValue, value: value)
    }

    public func int64(key: XPCKeys) -> Int64 {
        int64(key: key.rawValue)
    }

    public func set(key: XPCKeys, value: Int64) {
        set(key: key.rawValue, value: value)
    }

    public func int(key: XPCKeys) -> Int {
        Int(int64(key: key.rawValue))
    }

    public func set(key: XPCKeys, value: Int) {
        set(key: key.rawValue, value: Int64(value))
    }

    public func fileHandle(key: XPCKeys) -> FileHandle? {
        fileHandle(key: key.rawValue)
    }

    public func set(key: XPCKeys, value: FileHandle) {
        set(key: key.rawValue, value: value)
    }

    public func fileHandles(key: XPCKeys) -> [FileHandle]? {
        fileHandles(key: key.rawValue)
    }

    public func set(key: XPCKeys, value: [FileHandle]) throws {
        try set(key: key.rawValue, value: value)
    }

    public func endpoint(key: XPCKeys) -> xpc_endpoint_t? {
        endpoint(key: key.rawValue)
    }

    public func set(key: XPCKeys, value: xpc_endpoint_t) {
        set(key: key.rawValue, value: value)
    }
}

#endif
