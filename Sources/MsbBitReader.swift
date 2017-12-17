// Copyright (c) 2017 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

public final class MsbBitReader: ByteReader, BitReader {

    public private(set) var bitMask: UInt8

    public var isAligned: Bool {
        return self.bitMask == 128
    }

    public override init(data: Data) {
        self.bitMask = 128
        super.init(data: data)
    }

    public func bits(count: Int) -> [UInt8] {
        guard count > 0 else {
            return []
        }

        var array: [UInt8] = Array(repeating: 0, count: count)
        for i in 0..<count {
            array[i] = self.data[self.offset] & self.bitMask > 0 ? 1 : 0

            if self.bitMask == 1 {
                self.offset += 1
                self.bitMask = 128
            } else {
                self.bitMask >>= 1
            }
        }

        return array
    }

    public func intFromBits(count: Int) -> Int {
        guard count > 0 else {
            return 0
        }

        var result = 0
        for i in 0..<count {
            let power = count - i - 1

            let bit = self.data[self.offset] & self.bitMask > 0 ? 1 : 0
            result += (1 << power) * bit

            if self.bitMask == 1 {
                self.offset += 1
                self.bitMask = 128
            } else {
                self.bitMask >>= 1
            }
        }

        return result
    }

    public func bit() -> Int {
        let bit = self.data[self.offset] & self.bitMask > 0 ? 1 : 0

        if self.bitMask == 1 {
            self.offset += 1
            self.bitMask = 128
        } else {
            self.bitMask >>= 1
        }

        return bit
    }

    public func align() {
        guard self.bitMask != 128 else {
            return
        }
        self.bitMask = 128
        self.offset += 1
    }

    public override func byte() -> UInt8 {
        precondition(isAligned, "BitReader is not aligned.")
        return super.byte()
    }

    public override func bytes(count: Int) -> [UInt8] {
        precondition(isAligned, "BitReader is not aligned.")
        return super.bytes(count: count)
    }

    public override func uint64() -> UInt64 {
        precondition(isAligned, "BitReader is not aligned.")
        return super.uint64()
    }

    public override func uint32() -> UInt32 {
        precondition(isAligned, "BitReader is not aligned.")
        return super.uint32()
    }

    public override func uint16() -> UInt16 {
        precondition(isAligned, "BitReader is not aligned.")
        return super.uint16()
    }

}