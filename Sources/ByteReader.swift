// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

public protocol ByteReader: AnyObject {

    var size: Int { get }

    var data: Data { get }

    var offset: Int { get set }

    init(data: Data)

    func byte() -> UInt8

    func bytes(count: Int) -> [UInt8]

    func int(fromBytes count: Int) -> Int

    func uint64(fromBytes count: Int) -> UInt64

    func uint32(fromBytes count: Int) -> UInt32

    func uint16(fromBytes count: Int) -> UInt16

}

extension ByteReader {

    public init(_ bitReader: BitReader) {
        self.init(data: bitReader.data)
        self.offset = bitReader.offset
    }

    public var bytesLeft: Int {
        return data.endIndex - offset
    }

    public var bytesRead: Int {
        return offset - data.startIndex
    }

    public var isFinished: Bool {
        return data.endIndex <= offset
    }

    public func int(fromBytes count: Int) -> Int {
        if MemoryLayout<Int>.size == 8 {
            return Int(truncatingIfNeeded: self.uint64(fromBytes: count))
        } else if MemoryLayout<Int>.size == 4 {
            return Int(truncatingIfNeeded: self.uint32(fromBytes: count))
        } else {
            fatalError("Unknown Int bit width")
        }
    }

}
