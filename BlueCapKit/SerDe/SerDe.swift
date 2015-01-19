//
//  ByteSwap.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

func littleEndianToHost<T>(value:T) -> T {
    return value;
}

func hostToLittleEndian<T>(value:T) -> T {
    return value;
}

func byteArrayValue<T>(value:T) -> [Byte] {
    let values = [value]
    let data = NSData(bytes:values, length:sizeof(T))
    var byteArray = [Byte](count:sizeof(T), repeatedValue:0)
    data.getBytes(&byteArray, length:sizeof(T))
    return byteArray
}

func reverseBytes<T>(value:T) -> T {
    var result = value
    var swappedBytes = NSData(bytes:byteArrayValue(value).reverse(), length:sizeof(T))
    swappedBytes.getBytes(&result, length:sizeof(T))
    return result
}

public protocol Deserialized {
    typealias SelfType
    class func fromString(data:String) -> SelfType?
    class func deserializeFromLittleEndian(data:NSData) -> SelfType
    class func deserializeArrayFromLittleEndian(data:NSData) -> [SelfType]
    class func deserializeFromLittleEndian(data:NSData, start:Int) -> SelfType

}

public protocol Serialized {
    class func serialize<SerializedType>(value:SerializedType) -> NSData
    class func serializeArray<SerializedType>(values:[SerializedType]) -> NSData    
    class func serializeToLittleEndian<SerializedType>(value:SerializedType) -> NSData
    class func serializeArrayToLittleEndian<SerializedType>(values:[SerializedType]) -> NSData
    class func serializeArrayPairToLittleEndian<SerializedType1, SerializedType2>(values:([SerializedType1], [SerializedType2])) -> NSData
    
}

public protocol DeserializedEnum {
    typealias SelfType
    class func fromString(stringValue:String) -> SelfType?
    class func stringValues() -> [String]
    var stringValue : String {get}
}

public protocol DeserializedStruct {
    typealias SelfType
    typealias RawType : Deserialized
    class func fromRawValues(rawValues:[RawType]) -> SelfType?
    class func fromStrings(stringValues:Dictionary<String, String>) -> SelfType?
    var stringValues : Dictionary<String,String> {get}
    func toRawValues() -> [RawType]
}

public protocol DeserializedPairStruct {
    typealias SelfType
    typealias RawType1 : Deserialized
    typealias RawType2 : Deserialized
    class func fromRawValues(rawValues:([RawType1], [RawType2])) -> SelfType?
    class func fromStrings(stringValues:Dictionary<String, String>) -> SelfType?
    class func rawValueSizes() -> (Int, Int)
    var stringValues : Dictionary<String,String> {get}
    func toRawValues() -> ([RawType1], [RawType2])
}