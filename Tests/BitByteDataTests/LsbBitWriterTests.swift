// Copyright (c) 2020 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import XCTest
import BitByteData

class LsbBitWriterTests: XCTestCase {

    func testWriteBit() {
        let writer = LsbBitWriter()
        writer.write(bit: 0)
        writer.write(bit: 1)
        writer.write(bit: 0)
        writer.write(bit: 1)
        writer.write(bit: 1)
        writer.align()
        XCTAssertEqual(writer.data, Data([26]))
    }

    func testWriteBitsArray() {
        let writer = LsbBitWriter()
        writer.write(bits: [1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1])
        writer.align()
        XCTAssertEqual(writer.data, Data([83, 6]))
    }

    func testWriteSignedNumber_SM() {
        let repr = SignedNumberRepresentation.signMagnitude
        let writer = LsbBitWriter()
        writer.write(signedNumber: 127, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([127]))
        writer.write(signedNumber: 6, bitsCount: 4, representation: repr)
        XCTAssertEqual(writer.data, Data([127]))
        writer.write(signedNumber: 56, bitsCount: 7, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 134]))
        writer.align()
        XCTAssertEqual(writer.data, Data([127, 134, 3]))
        writer.write(signedNumber: -123, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 134, 3, 251]))
        writer.write(signedNumber: -56, bitsCount: 12, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 134, 3, 251, 56]))
        writer.align()
        XCTAssertEqual(writer.data, Data([127, 134, 3, 251, 56, 8]))
        writer.write(signedNumber: Int.max, bitsCount: Int.bitWidth, representation: repr)
        writer.write(signedNumber: Int.min + 1, bitsCount: Int.bitWidth, representation: repr)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([127, 134, 3, 251, 56, 8,
                                              0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F,
                                              0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([127, 134, 3, 251, 56, 8, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF]))
        }
    }

    func testWriteSignedNumber_1C() {
        let repr = SignedNumberRepresentation.oneComplement
        let writer = LsbBitWriter()
        writer.write(signedNumber: 127, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([127]))
        writer.write(signedNumber: 6, bitsCount: 4, representation: repr)
        XCTAssertEqual(writer.data, Data([127]))
        writer.write(signedNumber: 56, bitsCount: 7, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 134]))
        writer.align()
        XCTAssertEqual(writer.data, Data([127, 134, 3]))
        writer.write(signedNumber: -123, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 134, 3, 132]))
        writer.write(signedNumber: -56, bitsCount: 12, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 134, 3, 132, 199]))
        writer.align()
        XCTAssertEqual(writer.data, Data([127, 134, 3, 132, 199, 15]))
        writer.write(signedNumber: Int.max, bitsCount: Int.bitWidth, representation: repr)
        writer.write(signedNumber: Int.min + 1, bitsCount: Int.bitWidth, representation: repr)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([127, 134, 3, 132, 199, 15,
                                              0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F,
                                              0, 0, 0, 0, 0, 0, 0, 0x80]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([127, 134, 3, 132, 199, 15, 0xFF, 0xFF, 0xFF, 0x7F, 0, 0, 0, 0x80]))
        }
    }

    func testWriteSignedNumber_2C() {
        let repr = SignedNumberRepresentation.twoComplement
        let writer = LsbBitWriter()
        writer.write(signedNumber: 127, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([127]))
        writer.write(signedNumber: 6, bitsCount: 4, representation: repr)
        XCTAssertEqual(writer.data, Data([127]))
        writer.write(signedNumber: 56, bitsCount: 7, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 134]))
        writer.align()
        XCTAssertEqual(writer.data, Data([127, 134, 3]))
        writer.write(signedNumber: -123, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 134, 3, 133]))
        writer.write(signedNumber: -56, bitsCount: 12, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 134, 3, 133, 200]))
        writer.align()
        XCTAssertEqual(writer.data, Data([127, 134, 3, 133, 200, 15]))
        writer.write(signedNumber: Int.max, bitsCount: Int.bitWidth, representation: repr)
        writer.write(signedNumber: Int.min, bitsCount: Int.bitWidth, representation: repr)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([127, 134, 3, 133, 200, 15,
                                              0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F,
                                              0, 0, 0, 0, 0, 0, 0, 0x80]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([127, 134, 3, 133, 200, 15, 0xFF, 0xFF, 0xFF, 0x7F, 0, 0, 0, 0x80]))
        }
    }

    func testWriteSignedNumber_Biased_E127() {
        let repr = SignedNumberRepresentation.biased(bias: 127)
        let writer = LsbBitWriter()
        writer.write(signedNumber: 126, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([253]))
        writer.write(signedNumber: 6, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([253, 133]))
        writer.write(signedNumber: 56, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([253, 133, 183]))
        writer.write(signedNumber: 0, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([253, 133, 183, 127]))
        writer.align()
        XCTAssertEqual(writer.data, Data([253, 133, 183, 127]))
        writer.write(signedNumber: -123, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([253, 133, 183, 127, 4]))
        writer.write(signedNumber: -56, bitsCount: 12, representation: repr)
        XCTAssertEqual(writer.data, Data([253, 133, 183, 127, 4, 71]))
        writer.align()
        XCTAssertEqual(writer.data, Data([253, 133, 183, 127, 4, 71, 0]))
        writer.write(signedNumber: Int.max, bitsCount: Int.bitWidth, representation: repr)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([253, 133, 183, 127, 4, 71, 0, 0x7E, 0, 0, 0, 0, 0, 0, 0x80]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([253, 133, 183, 127, 4, 71, 0, 0x7E, 0, 0, 0x80]))
        }
    }

    func testWriteSignedNumber_Biased_E3() {
        let repr = SignedNumberRepresentation.biased(bias: 3)
        let writer = LsbBitWriter()
        writer.write(signedNumber: -3, bitsCount: 4, representation: repr)
        XCTAssertFalse(writer.isAligned)
        writer.write(signedNumber: 12, bitsCount: 4, representation: repr)
        XCTAssertTrue(writer.isAligned)
        XCTAssertEqual(writer.data, Data([240]))
        writer.write(signedNumber: 126, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([240, 129]))
        writer.write(signedNumber: 6, bitsCount: 12, representation: repr)
        XCTAssertFalse(writer.isAligned)
        XCTAssertEqual(writer.data, Data([240, 129, 9]))
        writer.write(signedNumber: 56, bitsCount: 6, representation: repr)
        XCTAssertFalse(writer.isAligned)
        XCTAssertEqual(writer.data, Data([240, 129, 9, 176]))
        writer.align()
        XCTAssertTrue(writer.isAligned)
        XCTAssertEqual(writer.data, Data([240, 129, 9, 176, 3]))
        writer.write(signedNumber: 0, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([240, 129, 9, 176, 3, 3]))
        writer.write(signedNumber: Int.max, bitsCount: Int.bitWidth, representation: repr)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([240, 129, 9, 176, 3, 3, 2, 0, 0, 0, 0, 0, 0, 0x80]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([240, 129, 9, 176, 3, 3, 2, 0, 0, 0x80]))
        }
    }

    func testWriteSignedNumber_Biased_E1023() {
        let repr = SignedNumberRepresentation.biased(bias: 1023)
        let writer = LsbBitWriter()
        writer.write(signedNumber: -1023, bitsCount: 11, representation: repr)
        XCTAssertFalse(writer.isAligned)
        XCTAssertEqual(writer.data, Data([0]))
        writer.align()
        XCTAssertTrue(writer.isAligned)
        XCTAssertEqual(writer.data, Data([0, 0]))
        writer.write(signedNumber: 0, bitsCount: 11, representation: repr)
        XCTAssertFalse(writer.isAligned)
        XCTAssertEqual(writer.data, Data([0, 0, 255]))
        writer.align()
        XCTAssertTrue(writer.isAligned)
        XCTAssertEqual(writer.data, Data([0, 0, 255, 3]))
        writer.write(signedNumber: Int.max, bitsCount: Int.bitWidth, representation: repr)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([0, 0, 255, 3, 0xFE, 3, 0, 0, 0, 0, 0, 0x80]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([0, 0, 255, 3, 0xFE, 3, 0, 0x80]))
        }
    }

    func testWriteUnsignedNumber() {
        let writer = LsbBitWriter()
        writer.write(unsignedNumber: UInt.max, bitsCount: UInt.bitWidth)
        if UInt.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
        } else if UInt.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([0xFF, 0xFF, 0xFF, 0xFF]))
        }
    }

    func testAppendByte() {
        let writer = LsbBitWriter()
        writer.append(byte: 0xCA)
        XCTAssertEqual(writer.data, Data([0xCA]))
        writer.append(byte: 0xFF)
        XCTAssertEqual(writer.data, Data([0xCA, 0xFF]))
        writer.append(byte: 0)
        XCTAssertEqual(writer.data, Data([0xCA, 0xFF, 0]))
    }

    func testAlign() {
        let writer = LsbBitWriter()
        writer.align()
        XCTAssertEqual(writer.data, Data())
        XCTAssertTrue(writer.isAligned)
    }

    func testIsAligned() {
        let writer = LsbBitWriter()
        writer.write(bits: [0, 1, 0])
        XCTAssertFalse(writer.isAligned)
        writer.write(bits: [0, 1, 0, 1, 0])
        XCTAssertTrue(writer.isAligned)
        writer.write(bit: 0)
        XCTAssertFalse(writer.isAligned)
        writer.align()
        XCTAssertTrue(writer.isAligned)
    }

    func testNamingConsistency() {
        let writer = LsbBitWriter()
        writer.write(signedNumber: 14582, bitsCount: 15)
        writer.align()
        XCTAssertEqual(writer.data, Data([0xF6, 0x38]))
        let bitReader = LsbBitReader(data: writer.data)
        XCTAssertEqual(bitReader.signedInt(fromBits: 15), 14582)
    }

}
