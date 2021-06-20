// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/**
 A type that contains functions for reading `Data` bit-by-bit using "LSB0" bit numbering scheme and byte-by-byte in the
 Little endian order.
 */
public final class LsbBitReader: BitReader {

    private var bitMask: UInt8 = 1
    private var currentByte: UInt8

    /// Size of the `data` (in bytes).
    public let size: Int

    /// Data which is being read.
    public let data: Data

    /**
     The offset to the byte in `data` right after the `currentByte`.

     - Precondition: The reader MUST be aligned when accessing the setter of `offset`.
     */
    public var offset: Int {
        willSet {
            precondition(self.bitMask == 1, "BitReader is not aligned.")
        }
        didSet {
            if !self.isFinished {
                currentByte = data[offset]
            }
        }
    }

    /// True, if reader's BIT pointer is aligned with the BYTE border.
    public var isAligned: Bool {
        return self.bitMask == 1
    }

    /// Amount of bits left to read.
    public var bitsLeft: Int {
        let bytesLeft = data.endIndex - offset
        return bytesLeft * 8 - bitMask.trailingZeroBitCount
    }

    /// Amount of bits that were already read.
    public var bitsRead: Int {
        let bytesRead = offset - data.startIndex
        return bytesRead * 8 + bitMask.trailingZeroBitCount
    }

    /// Creates an instance for reading bits (and bytes) from `data`.
    public init(data: Data) {
        self.size = data.count
        self.data = data
        self.offset = data.startIndex
        self.currentByte = data.first ?? 0
    }

    /**
     Converts a `ByteReader` instance into `LsbBitReader`, enabling bit reading capabilities. Current `offset` value of
     `byteReader` is preserved.
     */
    public convenience init(_ byteReader: ByteReader) {
        self.init(data: byteReader.data)
        self.offset = byteReader.offset
        self.currentByte = byteReader.isFinished ? 0 : byteReader.data[byteReader.offset]
    }

    /**
     Advances reader's BIT pointer by specified amount of bits (default is 1).

     - Warning: Doesn't check if there is any data left. It is advised to use `isFinished` AFTER calling this method
     to check if the end was reached.
     */
    public func advance(by count: Int = 1) {
        for _ in 0..<count {
            if self.bitMask == 128 {
                self.bitMask = 1
                self.offset += 1
            } else {
                self.bitMask <<= 1
            }
        }
    }

    /**
     Reads bit and returns it, advancing by one BIT position.

     - Precondition: There MUST be enough data left.
     */
    public func bit() -> UInt8 {
        precondition(bitsLeft >= 1)
        let bit: UInt8 = self.currentByte & self.bitMask > 0 ? 1 : 0

        if self.bitMask == 128 {
            self.bitMask = 1
            self.offset += 1
        } else {
            self.bitMask <<= 1
        }

        return bit
    }

    /**
     Reads `count` bits and returns them as an array of `UInt8`, advancing by `count` BIT positions.

     - Precondition: Parameter `count` MUST not be less than 0.
     - Precondition: There MUST be enough data left.
     */
    public func bits(count: Int) -> [UInt8] {
        precondition(count >= 0)
        precondition(bitsLeft >= count)

        var array = [UInt8]()
        array.reserveCapacity(count)
        for _ in 0..<count {
            array.append(self.bit())
        }

        return array
    }

    /**
     Reads `fromBits` bits and returns them as an `Int` number, advancing by `fromBits` BIT positions.

     - Precondition: Parameter `fromBits` MUST be from `0...Int.bitWidth` range, i.e. it MUST not exceed maximum bit
     width of `Int` type on the current platform.
     - Precondition: There MUST be enough data left.
     */
    public func signedInt(fromBits count: Int, representation: SignedNumberRepresentation = .twoComplement) -> Int {
        precondition(0...Int.bitWidth ~= count)
        precondition(bitsLeft >= count)

        guard count > 0
            else { return 0 }

        var result = 0
        switch representation {
        case .signMagnitude:
            result = self.int(fromBits: count - 1)
            result = self.bit() > 0 ? -result : result
        case .oneComplement:
            result = self.int(fromBits: count - 1)
            if self.bit() > 0 {
                // First, we convert to 2's-complement, and then we proceed as in the 2's-complement case.
                result &+= 1
                result &-= 1 << (count - 1)
            }
        case .twoComplement:
            result = self.int(fromBits: count - 1)
            result &-= self.bit() > 0 ? (1 << (count - 1)) : 0
        case .biased(let bias):
            result = self.int(fromBits: count)
            result &-= bias
        case .radixNegativeTwo:
            var mult = 1
            var sign = 1
            for _ in 0..<count {
                result &+= Int(truncatingIfNeeded: self.bit()) * sign * mult
                mult <<= 1
                sign *= -1
            }
        }

        return result
    }

    /**
     Reads `fromBits` bits and returns them as an `UInt8` number, advancing by `fromBits` BIT positions.

     - Precondition: Parameter `fromBits` MUST be from `0...8` range, i.e. it MUST not exceed maximum bit width of
     `UInt8` type on the current platform.
     - Precondition: There MUST be enough data left.
     */
    public func byte(fromBits count: Int) -> UInt8 {
        precondition(0...8 ~= count)
        precondition(bitsLeft >= count)

        var result = 0 as UInt8
        for i in 0..<count {
            let bit: UInt8 = self.currentByte & self.bitMask > 0 ? 1 : 0
            result += (1 << i) * bit

            if self.bitMask == 128 {
                self.bitMask = 1
                self.offset += 1
            } else {
                self.bitMask <<= 1
            }
        }

        return result
    }

    /**
     Reads `fromBits` bits and returns them as an `UInt16` number, advancing by `fromBits` BIT positions.

     - Precondition: Parameter `fromBits` MUST be from `0...16` range, i.e. it MUST not exceed maximum bit width of
     `UInt16` type on the current platform.
     - Precondition: There MUST be enough data left.
     */
    public func uint16(fromBits count: Int) -> UInt16 {
        precondition(0...16 ~= count)
        precondition(bitsLeft >= count)

        var result = 0 as UInt16
        for i in 0..<count {
            let bit: UInt16 = self.currentByte & self.bitMask > 0 ? 1 : 0
            result += (1 << i) * bit

            if self.bitMask == 128 {
                self.bitMask = 1
                self.offset += 1
            } else {
                self.bitMask <<= 1
            }
        }

        return result
    }

    /**
     Reads `fromBits` bits and returns them as an `UInt32` number, advancing by `fromBits` BIT positions.

     - Precondition: Parameter `fromBits` MUST be from `0...32` range, i.e. it MUST not exceed maximum bit width of
     `UInt32` type on the current platform.
     - Precondition: There MUST be enough data left.
     */
    public func uint32(fromBits count: Int) -> UInt32 {
        precondition(0...32 ~= count)
        precondition(bitsLeft >= count)

        var result = 0 as UInt32
        for i in 0..<count {
            let bit: UInt32 = self.currentByte & self.bitMask > 0 ? 1 : 0
            result += (1 << i) * bit

            if self.bitMask == 128 {
                self.bitMask = 1
                self.offset += 1
            } else {
                self.bitMask <<= 1
            }
        }

        return result
    }

    /**
     Reads `fromBits` bits and returns them as an `UInt64` number, advancing by `fromBits` BIT positions.

     - Precondition: Parameter `fromBits` MUST be from `0...64` range, i.e. it MUST not exceed maximum bit width of
     `UInt64` type on the current platform.
     - Precondition: There MUST be enough data left.
     */
    public func uint64(fromBits count: Int) -> UInt64 {
        precondition(0...64 ~= count)
        precondition(bitsLeft >= count)

        var result = 0 as UInt64
        for i in 0..<count {
            let bit: UInt64 = self.currentByte & self.bitMask > 0 ? 1 : 0
            result += (1 << i) * bit

            if self.bitMask == 128 {
                self.bitMask = 1
                self.offset += 1
            } else {
                self.bitMask <<= 1
            }
        }

        return result
    }

    /**
     Moves BIT pointer to the first BIT of the next BYTE. If the reader is already aligned, then does nothing.

     - Warning: Doesn't check if there is any data left. It is advised to use `isFinished` after calling this method
     to check if the end was reached.
     */
    public func align() {
        if self.bitMask != 1 {
            self.bitMask = 1
            self.offset += 1
        }
    }

    /**
     Reads byte and returns it, advancing by one BYTE position.

     - Precondition: The reader MUST be aligned.
     - Precondition: There MUST be enough data left.
     */
    public func byte() -> UInt8 {
        defer { offset += 1 }
        return data[offset]
    }

    /**
     Reads `count` bytes and returns them as an array of `UInt8`, advancing by `count` BYTE positions.

     - Precondition: The reader MUST be aligned.
     - Precondition: There MUST be enough data left.
     */
    public func bytes(count: Int) -> [UInt8] {
        defer { offset += count }
        return data[offset..<offset + count].toByteArray(count)
    }

    /**
     Reads 8 bytes and returns them as a `UInt64` number, advancing by 8 BYTE positions.

     - Precondition: The reader MUST be aligned.
     - Precondition: There MUST be enough data left.
     */
    public func uint64() -> UInt64 {
        defer { offset += 8 }
        return data[offset..<offset + 8].toU64()
    }

    /**
     Reads `fromBytes` bytes and returns them as a `UInt64` number, advancing by `fromBytes` BYTE positions.

     - Precondition: The reader MUST be aligned.
     - Precondition: Parameter `fromBytes` MUST not be less than 0.
     - Precondition: There MUST be enough data left.
     */
    public func uint64(fromBytes count: Int) -> UInt64 {
        precondition(0...8 ~= count)
        var result = 0 as UInt64
        for i in 0..<count {
            result += UInt64(truncatingIfNeeded: data[offset]) << (8 * i)
            offset += 1
        }
        return result
    }

    /**
     Reads 4 bytes and returns them as a `UInt32` number, advancing by 4 BYTE positions.

     - Precondition: The reader MUST be aligned.
     - Precondition: There MUST be enough data left.
     */
    public func uint32() -> UInt32 {
        defer { offset += 4 }
        return data[offset..<offset + 4].toU32()
    }

    /**
     Reads `fromBytes` bytes and returns them as a `UInt32` number, advancing by `fromBytes` BYTE positions.

     - Precondition: The reader MUST be aligned.
     - Precondition: Parameter `fromBytes` MUST not be less than 0.
     - Precondition: There MUST be enough data left.
     */
    public func uint32(fromBytes count: Int) -> UInt32 {
        precondition(0...4 ~= count)
        var result = 0 as UInt32
        for i in 0..<count {
            result += UInt32(truncatingIfNeeded: data[offset]) << (8 * i)
            offset += 1
        }
        return result
    }

    /**
     Reads 2 bytes and returns them as a `UInt16` number, advancing by 2 BYTE positions.

     - Precondition: The reader MUST be aligned.
     - Precondition: There MUST be enough data left.
     */
    public func uint16() -> UInt16 {
        defer { offset += 2 }
        return data[offset..<offset + 2].toU16()
    }

    /**
     Reads `fromBytes` bytes and returns them as a `UInt16` number, advancing by `fromBytes` BYTE positions.

     - Precondition: The reader MUST be aligned.
     - Precondition: Parameter `fromBytes` MUST not be less than 0.
     - Precondition: There MUST be enough data left.
     */
    public func uint16(fromBytes count: Int) -> UInt16 {
        precondition(0...2 ~= count)
        var result = 0 as UInt16
        for i in 0..<count {
            result += UInt16(truncatingIfNeeded: data[offset]) << (8 * i)
            offset += 1
        }
        return result
    }

}
