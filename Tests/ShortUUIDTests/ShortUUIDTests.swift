@testable import ShortUUID
import XCTest

final class ShortUUIDTests: XCTestCase {
    func testPartBytesDivmod() throws {
        let bs: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0xFE, 0xFF)
        let divNum: UInt64 = 0xF
        let mod: UInt64 = 0
        let res = ShortUUID.NumDigitU64(0x10FF, 0xE)

        let (num, digit) = ShortUUID.divmod(b0: bs.0, b1: bs.1, b2: bs.2, b3: bs.3, num: divNum, rem: mod)

        XCTAssertEqual(num, res.num)
        XCTAssertEqual(digit, res.digit)
    }
    
    func testEncode() throws {
        let su = ShortUUID()
        let uuid = UUID(uuidString: "5453B1ED-7BDE-4A41-A76C-27F61ADE5F73")!.uuid
        let res = "H2DX73XSkZc7NiVW3QYNes"
        
        let uuidEncoded = su.encode(uuid: uuid)
        
        XCTAssertEqual(res, uuidEncoded)
    }
    
    func testDecode() throws {
        let su = ShortUUID()
        let encodeStr = "H2DX73XSkZc7NiVW3QYNes"
        let res = UUID(uuidString: "5453B1ED-7BDE-4A41-A76C-27F61ADE5F73")

        let uuid = su.decode(text: encodeStr)

        XCTAssertEqual(res, uuid)
    }
    
    func testUUID5() throws {
        let uuid = UUID.uuid5(namespace: .URL, input: "input string")
        let res = "4552DE95-510D-5AB2-85A0-6F42CEACDB7E"
        
        XCTAssertEqual(res, uuid.uuidString)
    }
    
    @available(iOS 13.0, tvOS 13.0, *)
    func testMeasureRandom() {
        let su = ShortUUID()
        
        let opt = XCTMeasureOptions.default
        opt.iterationCount = 300
        
        measure(options: opt) {
            _ = su.random()
        }
    }
}
