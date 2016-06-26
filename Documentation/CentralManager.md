# <a name="central">CentralManager</a>

The BlueCap CentralManager implementation replaces [CBCentralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBCentralManagerDelegate) and [CBPeripheralDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralDelegate) protocol implementations with with a Scala Futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures). Futures provide inline implementation of asynchronous callbacks and allow chaining asynchronous calls as well as error handling and recovery. Also, provided are callbacks for connection events and connection and service scan timeouts. This section will describe interfaces and give example implementations for all supported use cases.

## Use Cases

* [PowerOn/PowerOff](#central_poweron_poweroff): Detect when the bluetooth transceiver is powered on and off.
* [Service Scanning](#central_service_scanning): Scan for services.
* [Service Scanning with Timeout](#central_service_scan_timeout): Scan for services with timeout.
* [Peripheral Advertisements](#central_peripheral_advertisements): Access Advertisements of discovered Peripherals.
* [Peripheral Connection](#central_peripheral_connection): Connect to discovered Peripherals.
* [Service and Characteristic Discovery](#central_characteristic_discovery): Discover Services and Characteristics of connected Peripherals.
* [Characteristic Write](#central_characteristic_write): Write a characteristic value to a connected Peripheral.
* [Characteristic Read](#central_characteristic_read): Read a characteristic value from a connected Peripheral.
* [Characteristic Update Notifications](#central_characteristic_update): Subscribe to characteristic value updates on a connected Peripheral.

### <a name="central_poweron_poweroff">PowerOn/PowerOff</a>

The state of the Bluetooth transceiver on a device is communicated to BlueCap CentralManager by the powerOn and powerOff futures,

```swift
public func powerOn() -> Future<Void>
public func powerOff() -> Future<Void>
```

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) *Future&lt;Void&gt;*. For an application to process events,

```swift
let manager = CentralManager.sharedInstance
let powerOnFuture = manager.powerOn()
powerOnFuture.onSuccess {
  …
}
let powerOffFuture = manager.powerOff()
powerOffFuture.onSuccess {
	…
}
``` 

When CentralManager is instantiated a message giving the current Bluetooth transceiver state is received and while the CentralManager is instantiated messages are received if the transceiver is powered or powered off.

### <a name="central_service_scanning">Service Scanning</a>

Central scans for advertising peripherals are initiated by calling the BlueCap CentralManager methods,

```swift
// Scan promiscuously for all advertising peripherals
public func startScanning(capacity:Int? = nil) -> FutureStream<Peripheral>

// Scan for peripherals advertising services with UUIDs
public func startScanningForServiceUUIDs(uuids:[CBUUID]!, capacity:Int? = nil) -> FutureStream<Peripheral>
``` 

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) *FutureStream&lt;Peripheral&gt;* yielding the discovered Peripheral and take the FutureStream capacity as input.

For an application to scan for Peripherals advertising Services with uuids after powerOn,

```swift
let manager = CentralManager.sharedInstance
let serviceUUID = CBUUID(string:"F000AA10-0451-4000-B000-000000000000")!

let peripheraDiscoveredFuture = manager.powerOn().flatmap {_ -> FutureStream<Peripheral> in
	manager.startScanningForServiceUUIDs([serviceUUID], capacity:10)
}
peripheraDiscoveredFuture.onSuccess {peripheral in
	…
}
```

Here the powerOn future has been flatmapped to *startScanning(capacity:Int?) -> FutureStream&lt;Peripheral&gt;* to ensure that the service scan starts after the bluetooth transceiver is powered on.

To stop a peripheral scan use the CentralManager method,

```swift
public func stopScanning()
```

and in an application,

```swift
let manager = CentralManager.sharedInstance
manager.stopScanning()
```

### <a name="central_service_scan_timeout">Service Scanning with Timeout</a>

BlueCap CentralManager can scan for advertising peripherals with a timeout. TimedScannerator methods are used to start a scan instead ob the CentralManager methods. The declarations include a timeout parameter but are otherwise the same,

```swift
// Scan promiscuously for all advertising peripherals
public func startScanning(timeoutSeconds:Double, capacity:Int? = nil) -> FutureStream<Peripheral>

// Scan for peripherals advertising services with UUIDs
public func startScanningForServiceUUIDs(timeoutSeconds:Double, uuids:[CBUUID]!, capacity:Int? = nil) -> FutureStream<Peripheral>
``` 

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) *FutureStream&lt;Peripheral&gt;* yielding the discovered peripheral and take the FutureStream capacity as input.

For an application to scan for Peripherals advertising Services  with UUIDs and a specified timeout after powerOn,

```swift
let manager = CentralManager.sharedInstance
let serviceUUID = CBUUID(string:"F000AA10-0451-4000-B000-000000000000")!

let peripheraDiscoveredFuture = manager.powerOn().flatmap {_ -> FutureStream<Peripheral> in
	TimedScannerator.sharedinstance.startScanningForServiceUUIDs(10.0, uuids:[serviceUUID], capacity:10)
}
peripheraDiscoveredFuture.onSuccess {peripheral in
	…
}
peripheraDiscoveredFuture.onFailure {error in
	…
}
```

Here the powerOn future has been flatmapped to *startScanning(capacity:Int?) -> FutureStream&lt;Peripheral&gt;* to ensure that the service scan starts after the bluetooth transceiver is powered on. On timeout peripheraDiscoveredFuture will complete with error BCError.peripheralDiscoveryTimeout.

To stop a peripheral scan use the TimedScannerator method,

```swift
public func stopScanning()
```

and in an application,

```swift
TimedScannerator.sharedInstance.stopScanning()
```

### <a name="central_peripheral_advertisements">Peripheral Advertisements</a>

Peripheral advertisements are can be obtained using the following Peripheral properties,

```swift

// Local peripheral name with key CBAdvertisementDataLocalNameKey
public var advertisedLocalName : String? 

// Manufacture data with key CBAdvertisementDataManufacturerDataKey    
public var advertisedManufactuereData : NSData? 

// Tx power with with key CBAdvertisementDataTxPowerLevelKey
public var advertisedTxPower : NSNumber? 

// Is connectable with key CBAdvertisementDataIsConnectable
public var advertisedIsConnectable : NSNumber? 
    
// Advertised service UUIDs with key CBAdvertisementDataServiceUUIDsKey
public var advertisedServiceUUIDs : [CBUUID]? 

// Advertised service data with key CBAdvertisementDataServiceDataKey
public var advertisedServiceData : [CBUUID:NSData]? 

// Advertised overflow services with key CBAdvertisementDataOverflowServiceUUIDsKey
public var advertisedOverflowServiceUUIDs : [CBUUID]? 

// Advertised solicited services with key CBAdvertisementDataSolicitedServiceUUIDsKey
public var advertisedSolicitedServiceUUIDs : [CBUUID]? 
```

### <a name="central_peripheral_connection">Peripheral Connection</a>

After discovering a peripheral a connection must be established to begin messaging. Connecting and maintaining a connection to a bluetooth device can be difficult since signals are weak and devices may have relative motion. BlueCap provides connection events to enable applications to easily handle anything that can happen. ConnectionEvent is an enum with values,

<table>
  <tr>
    <th>Event</th>
    <th>Description</th>
  </tr>
	<tr>
		<td>Connect</td>
		<td>Connected to peripheral</td>
	</tr>
	<tr>
		<td>Timeout</td>
		<td>Connection attempt timeout</td>
	</tr>
	<tr>
		<td>Disconnect</td>
		<td>Peripheral disconnected</td>
	</tr>
	<tr>
		<td>ForceDisconnect</td>
		<td>Peripheral disconnected by application</td>
	</tr>
	<tr>
		<td>Failed</td>
		<td>Connection failed without error</td>
	</tr>
	<tr>
		<td>GiveUp</td>
		<td>Give-up trying to connect.</td>
	</tr>
</table>

To connect to a peripheral use The BlueCap Peripheral method,

```swift
public func connect(capacity:Int? = nil, timeoutRetries:UInt? = nil, disconnectRetries:UInt? = nil, connectionTimeout:Double = 10.0) -> FutureStream<(Peripheral, ConnectionEvent)>
```

**Discussion**

BlueCap Peripheral connect returns a [SimpleFutures](https://github.com/troystribling/SimpleFutures) *FutureStream&lt;(Peripheral, ConnectionEvent)&gt;* yielding a tuple containing the connected Peripheral and the ConnectionEvent.

<table>
	<tr>
		<td>capacity</td>
		<td>FutureStream capacity</td>
	</tr>
	<tr>
		<td>timeoutRetries</td>
		<td>Number of connection retries on timeout. Equals 0 if nil.</td>
	</tr>
	<tr>
		<td>disconnectRetries</td>
		<td>Number of connection retries on disconnect. Equals 0 if nil.</td>
	</tr>
	<tr>
		<td>connectionTimeout</td>
		<td>Connection timeout in seconds. Default is 10s.</td>
	</tr>
</table>

Other BlueCap Peripheral connection management methods are,

```swift
// Reconnect peripheral if disconnected
public func reconnect()

// Disconnect peripheral
public func disconnect()

// Terminate peripheral
public func terminate()
```

An application can connect a Peripheral using,

```swift
let manager = CentralManager.sharedInstance
let serviceUUID = CBUUID(string:"F000AA10-0451-4000-B000-000000000000")!

let peripheralConnectFuture = manager.powerOn().flatmap {_ -> FutureStream<Peripheral> in
	manager.startScanningForServiceUUIDs([serviceUUID], capacity:10)
}.flatmap{peripheral -> FutureStream<(Peripheral, ConnectionEvent)> in
	return peripheral.connect(capacity:10, timeoutRetries:5, disconnectRetries:5, connectionTimeout:10.0)
}
peripheralConnectFuture.onSuccess {(peripheral, connectionEvent) in
	switch connectionEvent {
  case .Connect:
	  …
  case .Timeout:
    peripheral.reconnect()
		…
  case .Disconnect:
    peripheral.reconnect()
		…
  case .ForceDisconnect:
	  …
  case .Failed:
	  …
  case .GiveUp:
	  peripheral.terminate()
		…
  }
}
peripheralConnectFuture.onFailure {error in
	…
}
```

Here the [peripheraDiscoveredFuture](#central_service_scanning) from the previous section is flatmapped to *connect(capacity:Int? = nil, timeoutRetries:UInt, disconnectRetries:UInt?, connectionTimeout:Double) -> FutureStream&lt;(Peripheral, ConnectionEvent)&gt;* to ensure that connections are made after Peripherals are discovered. When ConnectionEvents of .Timeout and .Disconnect are received an attempt is made to reconnect the Peripheral. The connection is configured for a maximum of 5 timeout retries and 5 disconnect retries. If either of these thresholds is exceeded a .GiveUp event is received and the Peripheral connection is terminated ending all reconnection attempts.

### <a name="central_characteristic_discovery">Service and Characteristic Discovery</a>

After a Peripheral is connected its Services and Characteristics must be discovered before Characteristic values can be read or written to or update notifications can be received.

There are several BlueCap Peripheral methods that can be used to discover Services and Characteristics.

```swift
// Discover services and characteristics for services with UUIDs
public func discoverPeripheralServices(services:[CBUUID]!) -> Future<Peripheral>

// Discover all services and characteristics supported by peripheral
public func discoverAllPeripheralServices() -> Future<Peripheral>
```

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) *Future&lt;Peripheral&gt;* yielding the connected Peripheral.

An application can discover a Peripheral using,

```swift
// errors
public enum ApplicationErrorCode : Int {
    case PeripheralNotConnected = 1
}

public struct ApplicationError {
    public static let domain = "Application"
    public static let peripheralNotConnected = NSError(domain:domain, code:ApplicationErrorCode.PeripheralNotConnected.rawValue, userInfo:[NSLocalizedDescriptionKey:"Peripheral not connected"])
}
…
// peripheralConnectFuture and serviceUUID are defined in previous section
…
let characteristicsDiscoveredFuture = peripheralConnectFuture.flatmap {(peripheral, connectionEvent) -> Future<Peripheral> in
	if peripheral.state == .Connected {
	  return peripheral.discoverPeripheralServices([serviceUUID])
	} else {
	  let promise = Promise<Peripheral>()
    promise.failure(ApplicationError.peripheralNotConnected)
    return promise.future
  }
}
characteristicsDiscoveredFuture.onSuccess {peripheral in
	…
}
characteristicsDiscoveredFuture.onFailure {error in
	…
}
```

Here the [peripheralConnectFuture](#central_peripheralconnect) from the previous section is flatmapped to *discoverPeripheralServices(services:[CBUUID]!) -> Future&lt;Peripheral&gt;* to ensure that the Peripheral is connected before Service and Characteristic discovery starts. Also, the Peripheral is discovered only if it is connected and an error is returned if the Peripheral is not connected.

### <a name="central_characteristic_write">Characteristic Write</a>

After a Peripherals Characteristics are discovered writing Characteristic values is possible. Many BlueCap Characteristic methods are available,

```swift
// Write an NSData object to characteristic value
public func writeData(value:NSData, timeout:Double = 10.0) -> Future<Characteristic>

// Write a characteristic String Dictionary value
public func writeString(stringValue:[String:String], timeout:Double = 10.0) -> Future<Characteristic>

// Write a Deserializable characteristic value
public func write<T:Deserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic>

// Write a RawDeserializable characteristic value
public func write<T:RawDeserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic>

// Write a RawArrayDeserializable characteristic value
public func write<T:RawArrayDeserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic>

// Write a RawPairDeserializable characteristic value
public func write<T:RawPairDeserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic>

// Write a RawArrayPairDeserializable characteristic value
public func write<T:RawArrayPairDeserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic>
```

Using the [RawDeserializable enum](#serde_rawdeserializable) an application can write a BlueCap Characteristic as follows,

```swift
// errors
public enum ApplicationErrorCode : Int {
    case CharacteristicNotFound = 1
}

public struct ApplicationError {
    public static let domain = "Application"
    public static let characteristicNotFound = NSError(domain:domain, code:ApplicationErrorCode.CharacteristicNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic Not Found"])
}

// RawDeserializable enum
enum Enabled : UInt8, RawDeserializable {
    case No  = 0
    case Yes = 1
    public static let uuid = "F000AA12-0451-4000-B000-000000000000"
}
let enabledUUID = CBUUID(string:Enabled.uuid)!
…
// characteristicsDiscoveredFuture and serviceUUID are defined in a previous section
…
let writeCharacteristicFuture = characteristicsDiscoveredFuture.flatmap {peripheral -> Future<Characteristic> in
	if let service = peripheral.service(serviceUUID), characteristic = service.characteristic(enabledUUID) {
		return characteristic.write(Enabled.Yes, timeout:20.0)
	} else {
		let promise = Promise<Characteristic>()
		promise.failure(ApplicationError.characteristicNotFound)
		return promise.future
	}
}
writeCharacteristicFuture.onSuccess {characteristic in
	…
}
writeCharacteristicFuture.onFailure {error in
	…
}
```

Here the [characteristicsDiscoveredFuture](#central_characteristicdiscovery) previously defined is flatmapped to *write&lt;T:RawDeserializable&gt;(value:T, timeout:Double) -> Future&lt;Characteristic&gt;* to ensure that characteristic has been discovered before writing. An error is returned if the characteristic is not found. 

### <a name="central_characteristic_read">Characteristic Read</a>

After a Peripherals Characteristics are discovered reading Characteristic values is possible. Many BlueCap Characteristic methods are available,

```swift
// Read a characteristic from a peripheral service
public func read(timeout:Double = 10.0) -> Future<Characteristic>

// Return the characteristic value as and NSData object
public var dataValue : NSData!

// Return the characteristic value as a String Dictionary.
public var stringValue :[String:String]?

// Return a Deserializable characteristic value
public func value<T:Deserializable>() -> T?

// Return a RawDeserializable characteristic value
public func value<T:RawDeserializable where T.RawType:Deserializable>() -> T?

// Return a RawArrayDeserializable characteristic value
public func value<T:RawArrayDeserializable where T.RawType:Deserializable>() -> T?

// Return a RawPairDeserializable characteristic value
public func value<T:RawPairDeserializable where T.RawType1:Deserializable, T.RawType2:Deserializable>() -> T?
```

Using the [RawDeserializable enum](#serde_rawdeserializable) an application can read a BlueCap Characteristic as follows,

```swift
// errors
public enum ApplicationErrorCode : Int {
    case CharacteristicNotFound = 1
}

public struct ApplicationError {
    public static let domain = "Application"
    public static let characteristicNotFound = NSError(domain:domain, code:ApplicationErrorCode.CharacteristicNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic Not Found"])
}

// RawDeserializable enum
enum Enabled : UInt8, RawDeserializable {
    case No  = 0
    case Yes = 1
    public static let uuid = "F000AA12-0451-4000-B000-000000000000"
}
let enabledUUID = CBUUID(string:Enabled.uuid)!
…
// characteristicsDiscoveredFuture and serviceUUID 
// are defined in a previous section
…
let readCharacteristicFuture = characteristicsDiscoveredFuture.flatmap {peripheral -> Future<Characteristic> in
	if let service = peripheral.service(serviceUUID), characteristic = service.characteristic(enabledUUID) {
		return characteristic.read(timeout:20.0)
	} else {
		let promise = Promise<Characteristic>()
		promise.failure(ApplicationError.characteristicNotFound)
		return promise.future
	}
}
writeCharacteristicFuture.onSuccess {characteristic in
	if let value : Enabled = characteristic.value {
		…
	}
}
writeCharacteristicFuture.onFailure {error in
	…
}
```

Here the [characteristicsDiscoveredFuture](#central_characteristicdiscovery) previously defined is flatmapped to *read(timeout:Double) -> Future&lt;Characteristic&gt;* to ensure that characteristic has been discovered before reading. An error is returned if the characteristic is not found. 

### <a name="central_characteristic_update">Characteristic Update Notifications</a>

After a Peripherals Characteristics are discovered subscribing to Characteristic value update notifications is possible. Several BlueCap Characteristic methods are available,

```swift
// subscribe to characteristic update
public func startNotifying() -> Future<Characteristic>

// receive characteristic value updates
public func receiveNotificationUpdates(capacity:Int? = nil) -> FutureStream<Characteristic>

// unsubscribe from characteristic updates
public func stopNotifying() -> Future<Characteristic>

// stop receiving characteristic value updates
public func stopNotificationUpdates()
```

Using the [RawDeserializable enum](#serde_rawdeserializable) an application can receive notifications from a BlueCap Characteristic as follows,

```swift
// errors
public enum ApplicationErrorCode : Int {
    case CharacteristicNotFound = 1
}

public struct ApplicationError {
    public static let domain = "Application"
    public static let characteristicNotFound = NSError(domain:domain, code:ApplicationErrorCode.CharacteristicNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic Not Found"])
}

// RawDeserializable enum
enum Enabled : UInt8, RawDeserializable {
    case No  = 0
    case Yes = 1
    public static let uuid = "F000AA12-0451-4000-B000-000000000000"
}
let enabledUUID = CBUUID(string:Enabled.uuid)!
…
// characteristicsDiscoveredFuture and serviceUUID are defined in a previous section
…
let subscribeCharacteristicFuture = characteristicsDiscoveredFuture.flatmap {peripheral -> Future<Characteristic> in
	if let service = peripheral.service(serviceUUID), characteristic = service.characteristic(enabledUUID) {
		return characteristic.startNotifying()
	} else {
		let promise = Promise<Characteristic>()
		promise.failure(ApplicationError.characteristicNotFound)
		return promise.future
	}
}
subscribeCharacteristicFuture.onSuccess {characteristic in
	…
}
subscribeCharacteristicFuture.onFailure {error in
	…
}

let updateCharacteristicFuture = subscribeCharacteristicFuture.flatmap{characteristic -> FutureStream<Characteristic> in
	return characteristic.receiveNotificationUpdates(capacity:10)
}
updateCharacteristicFuture.onSuccess {characteristic in
	if let value : Enabled = characteristic.value {
		…
	}
}
updateCharacteristicFuture.onFailure {error in 
}
```

Here the [characteristicsDiscoveredFuture](#central_characteristicdiscovery) previously defined is flatmapped to *startNotifying() -> Future&lt;Characteristic&gt;* to ensure that characteristic has been discovered before subscribing to updates.  An error is returned if the characteristic is not found. Then updateCharacteristicFuture is flatmapped again to *receiveNotificationUpdates(capacity:Int?) -> FutureStream&lt;Characteristic&gt;* to ensure that the subsections is completed before receiving updates.

For an application to unsubscribe to Characteristic value updates and stop receiving updates,

```swift
// serviceUUID and enabledUUID are define in the example above
if let service = peripheral.service(serviceUUID), characteristic = service.characteristic(enabledUUID) {
	
	// stop receiving updates
	characteristic.stopNotificationUpdates()

	// unsubscribe to notifications
	characteristic.stopNotifying()
}
```