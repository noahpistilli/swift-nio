//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif


public class BaseSocket : Selectable {
    public let descriptor: Int32
    public private(set) var open: Bool;
    
    public var localAddress: SocketAddress? {
        get {
            return nil
        }
    }
    public var remoteAddress: SocketAddress? {
        get {
            return nil
        }
    }
    
    init(descriptor : Int32) {
        self.descriptor = descriptor
        self.open = true
    }
    
    public func setNonBlocking() throws {
        let res = fcntl(self.descriptor, F_SETFL, O_NONBLOCK)
        
        guard res >= 0 else {
            throw IOError(errno: errno, reason: "fcntl(...) failed")
        }
        
    }
    
    public func setOption<T>(level: Int32, name: Int32, value: T) throws {
        var val = value
        guard setsockopt(
            self.descriptor,
            level,
            name,
            &val,
            socklen_t(MemoryLayout<T>.stride)
            ) != -1 else {
                throw IOError(errno: errno, reason: "setsockopt failed")
        }
    }
    
    public func getOption<T>(level: Int32, name: Int32) throws -> T {
        var length = socklen_t(MemoryLayout<T>.stride)
        var val = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer {
            val.deinitialize()
            val.deallocate(capacity: 1)
        }
        
        guard getsockopt(self.descriptor, level, name, val, &length) != -1 else {
            throw IOError(errno: errno, reason: "getsockopt failed")
        }
        return val.pointee
    }
    
    public func bind(address: SocketAddress) throws {
        var addr = address.addr
        
        #if os(Linux)
            let res = withUnsafePointer(to: &addr) {
                Glibc.bind(self.descriptor, UnsafePointer<sockaddr>($0), socklen_t(address.size));
            }
        #else
            let res = withUnsafePointer(to: &addr) {
                Darwin.bind(self.descriptor, UnsafePointer<sockaddr>($0), socklen_t(address.size));
            }
        #endif
        
        guard res >= 0 else {
            throw IOError(errno: errno, reason: "bind(...) failed")
        }
    }

    
    public func close() throws {
        #if os(Linux)
            let res = Glibc.close(self.descriptor)
        #else
            let res = Darwin.close(self.descriptor)
        #endif
        guard res >= 0 else {
            throw IOError(errno: errno, reason: "shutdown(...) failed")
        }
        self.open = false
    }
}
