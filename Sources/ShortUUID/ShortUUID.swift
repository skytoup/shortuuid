
import Foundation

/// Concise UUID generation
///
/// <https://github.com/skorokithakis/shortuuid>
public struct ShortUUID {
    static let defaultAlphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ" + "abcdefghijkmnopqrstuvwxyz"

    var _alphabet: String = defaultAlphabet
    public var alphabet: String {
        get { _alphabet }
        mutating set {
            let cs = Set(newValue.map { $0 }).sorted()
            _alphabet = String(cs)
        }
    }
    
    /// Return the necessary length to fit the entire UUID given the current alphabet.
    var defaultPadLength: Int {
        let factor = log(Double(UInt64.max)) / Double(_alphabet.count)
        return Int(ceil(factor))
    }
    
    /// 使用自定义字符创建ShortUUID
    ///
    /// - Parameter alphabet: 自定义字符
    public init(alphabet: String? = nil) {
        if let alphabet = alphabet {
            self.alphabet = alphabet
        }
    }
    
    // MARK: - public
    
    /// 创建一个uuid
    ///
    /// - Parameters:
    ///   - name: 指定字符生成
    ///   - padLength: 对齐位数
    /// - Returns: uuid string
    public func uuid(name: String? = nil, padLength: Int? = nil) -> String {
        let uuidBytes: UUIDBytes
        if let name = name {
            let isURL = ["http://", "https://"].contains(where: { name.starts(with: $0) })
            uuidBytes = UUID.uuid5(namespace: isURL ? .URL : .DNS, input: name).uuid
        } else {
            uuidBytes = UUID().uuid
        }

        return encode(uuid: uuidBytes, paddingLen: padLength ?? defaultPadLength)
    }

    /// 随机生成uuid并转为short uuid
    /// - Parameter length: 补位长度
    /// - Returns: short uuid
    @inline(__always)
    public func random(length: Int? = nil) -> String {
        uuid(padLength: length)
    }

    /// 使用uuid生成short uuid
    ///
    /// - Parameters:
    ///   - uuid:
    ///   - paddingLen: 补位长度
    /// - Returns: short uuid
    @inline(__always)
    public func encode(uuid: UUIDBytes, paddingLen: Int? = nil) -> String {
        intToString(uuid, padding: paddingLen)
    }
    
    /// 使用uuid生成short uuid
    ///
    /// - Parameters:
    ///   - uuid:
    ///   - paddingLen: 补位长度
    /// - Returns: short uuid
    @inline(__always)
    public func encode(uuid: UUID, paddingLen: Int? = nil) -> String {
        encode(uuid: uuid.uuid, paddingLen: paddingLen)
    }
    
    /// short uuid转UUID
    /// 转换的数据需要`ShortUUID.alphabet`一致
    ///
    /// - Parameter text:
    /// - Returns:
    public func decode(text: String) -> UUID {
        let uuid = stringToInt(text)
        return UUID(uuid: uuid)
    }
    
    /// Returns the string length of the shortened UUID.
    /// - Parameter numBytes:
    /// - Returns:
    public func encodeLength(numBytes: Int) -> Int {
        let factor = log(256) / log(Double(_alphabet.count))
        return Int(ceil(factor * Double(numBytes)))
    }
    
    // MARK: - internal
    
    /// short str还原uuid bytes
    ///
    /// - Parameter str: short uuid
    /// - Returns: uuid
    func stringToInt(_ str: String) -> UUIDBytes {
        let idxs = str.map { character -> Int in
            guard let idx = _alphabet.firstIndex(of: character) else {
                return 0
            }
            
            return _alphabet.distance(from: _alphabet.startIndex, to: idx)
        }
        
        let alphabetLen = UInt32(_alphabet.count)
        let res = idxs.reduce(Self.UUIDBytesZero) { res, now in
            Self.muladd(bytes: res, mulNum: alphabetLen, addNum: UInt32(now))
        }
        
        return res
    }
    
    /// uuid bytes转换为short str
    /// uuid bytes以128 bit Int多此计算整除结果和余数, 并以余数作为索引取alphabet字符组成字符串
    ///
    /// - Parameters:
    ///   - uuid:
    ///   - padding: 补位长度
    /// - Returns: uuid string
    func intToString(_ uuid: UUIDBytes, padding: Int? = nil) -> String {
        var bytes = uuid
        var num: UInt64 = 0
        var dig: UInt64 = 0
        var charIdxs = [Int]()
        let alphabetLen32 = UInt32(_alphabet.count)
        
        while num == 0 {
            let res = Self.divmod(bytes: bytes, num: alphabetLen32)
            switch res {
                case .num(let numDigit):
                    num = numDigit.num
                    dig = numDigit.digit
                case .bytes(let numDigitBytes):
                    bytes = numDigitBytes.num
                    dig = numDigitBytes.digit
            }
            
            charIdxs.append(Int(dig))
        }

        let alphabetLen64 = UInt64(_alphabet.count)
        
        while num != 0 {
            dig = num % alphabetLen64
            num /= alphabetLen64
            
            charIdxs.append(Int(dig))
        }

        if let padding = padding, padding > charIdxs.count {
            let rem = [Int](repeating: 0, count: padding - charIdxs.count)
            charIdxs.append(contentsOf: rem)
        }
        
        let chars = charIdxs.reversed()
            .map { _alphabet.index(_alphabet.startIndex, offsetBy: $0) }
            .map { _alphabet[$0] }

        return String(chars)
    }
}

/// Utils
extension ShortUUID {
    public typealias UUIDBytes = uuid_t
    typealias NumDigit = (num: Int, digit: Int)
    typealias NumDigitU64 = (num: UInt64, digit: UInt64)
    typealias NumDigitBytes = (num: UUIDBytes, digit: UInt64)

    public static var UUIDBytesZero: UUIDBytes { (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) }
    
    /// 整除和求余的结果
    enum DivmodResult {
        /// UInt64的结果
        case num(NumDigitU64)
        /// bytes的结果
        case bytes(NumDigitBytes)
    }
    
    /// UUID bytes的乘并加
    ///
    /// - Parameters:
    ///   - bytes: UUID bytes 128 bits
    ///   - mulNum: 相乘的数
    ///   - addNum: 加的数
    /// - Returns: 乘并加的结果
    static func muladd(bytes: UUIDBytes, mulNum: UInt32, addNum: UInt32) -> UUIDBytes {
        let mulNumU64 = UInt64(mulNum)
        let addNumU64 = UInt64(addNum)
        
        // 按32 bits分块相乘
        let res3 = mul(b0: bytes.12, b1: bytes.13, b2: bytes.14, b3: bytes.15, mulNum: mulNumU64, addNum: addNumU64, carry: 0)
        let res2 = mul(b0: bytes.8, b1: bytes.9, b2: bytes.10, b3: bytes.11, mulNum: mulNumU64, addNum: 0, carry: res3.digit)
        let res1 = mul(b0: bytes.4, b1: bytes.5, b2: bytes.6, b3: bytes.7, mulNum: mulNumU64, addNum: 0, carry: res2.digit)
        let res0 = mul(b0: bytes.0, b1: bytes.1, b2: bytes.2, b3: bytes.3, mulNum: mulNumU64, addNum: 0, carry: res1.digit)
        
        var bs = UUIDBytesZero
        // 直接忽略处理res0.digit > 0的溢出情况, 正常情况下不会出现
        assign(bytes: &bs, num0: res0.num, num1: res1.num, num2: res2.num, num3: res3.num)

        return bs
    }
    
    /// 4 bytes的乘并加
    ///
    /// - Parameters:
    ///   - b0:
    ///   - b1:
    ///   - b2:
    ///   - b3:
    ///   - mulNum: 乘数
    ///   - addNum: 加数
    ///   - carry: 进位数
    /// - Returns: 乘并加的结果和进位数
    static func mul(b0: UInt8, b1: UInt8, b2: UInt8, b3: UInt8, mulNum: UInt64, addNum: UInt64, carry: UInt64) -> NumDigitU64 {
        let partNum = (UInt64(b0) << 24) | (UInt64(b1) << 16) | (UInt64(b2) << 8) | UInt64(b3)
        let res = partNum * mulNum + carry + addNum
        return (res & 0xFFFF_FFFF, res >> 32)
    }
    
    /// UUID bytes的整除并求余
    ///
    /// - Parameters:
    ///   - bytes: UUID bytes 128 bits
    ///   - num: 除数
    /// - Returns: 整除和求余的结果
    static func divmod(bytes: UUIDBytes, num: UInt32) -> DivmodResult {
        let numU64 = UInt64(num)
        // 按32 bits分块整除求余
        let res0 = divmod(b0: bytes.0, b1: bytes.1, b2: bytes.2, b3: bytes.3, num: numU64, rem: 0)
        let res1 = divmod(b0: bytes.4, b1: bytes.5, b2: bytes.6, b3: bytes.7, num: numU64, rem: res0.digit)
        let res2 = divmod(b0: bytes.8, b1: bytes.9, b2: bytes.10, b3: bytes.11, num: numU64, rem: res1.digit)
        let res3 = divmod(b0: bytes.12, b1: bytes.13, b2: bytes.14, b3: bytes.15, num: numU64, rem: res2.digit)

        if res0.num + res1.num == 0 {
            // 整除结果少于64 bits, 直接转为UInt64
            let num = [res0, res1, res2, res3].reduce(0) { res, now in
                (res << 32) | now.num
            }
            return .num((num, res3.digit))
        } else {
            var bs = UUIDBytesZero
            // 使用32 bits进行整除运算, 结果不会超过32 bits
            assign(bytes: &bs, num0: res0.num, num1: res1.num, num2: res2.num, num3: res3.num)
            
            return .bytes((bs, res3.digit))
        }
    }
    
    /// 4 bytes的整除并求余
    ///
    /// - Parameters:
    ///   - b0:
    ///   - b1:
    ///   - b2:
    ///   - b3:
    ///   - num: 除数
    ///   - rem: 前部分运算剩下的余数
    /// - Returns: 整除和求余的结果
    static func divmod(b0: UInt8, b1: UInt8, b2: UInt8, b3: UInt8, num: UInt64, rem: UInt64) -> NumDigitU64 {
        let partNum = (rem << 32) | (UInt64(b0) << 24) | (UInt64(b1) << 16) | (UInt64(b2) << 8) | UInt64(b3)
        return (partNum / num, partNum % num)
    }
    
    static func assign(bytes: inout UUIDBytes, num0: UInt64, num1: UInt64, num2: UInt64, num3: UInt64) {
        let u64Len = MemoryLayout<UInt64>.size
        var h = CFSwapInt64((num0 << 32) | num1)
        memcpy(&bytes, &h, u64Len)
        h = CFSwapInt64((num2 << 32) | num3)
        memcpy(&bytes.8, &h, u64Len)
    }
}
