# SwiftFlight

SwiftFlight provides a straightforward way to connect with Infinite Flight's Connect API v2.

## Installation

### CocoaPods

SwiftFlight currently supports installation via CocoaPods.

Add the following to your `Podfile`:

```
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/tomthetank46/PodSpecs'

target 'InfiniteControl' do
    pod 'SwiftFlight', '~> 0.1.6'
end
```

And then run `pod install`

## Code Examples:

### Create an instance of `ConnectAPI` and pass it to `UDPReceiver` and `FlightControls` instances:
```
import SwiftFlight

let connectAPI = ConnectAPI()
let udpReceiver = UDPReceiver(API: connectAPI)
let flightControls = FlightControls(API: connectAPI)
```

### Discover Infinite Flight UDP broadcasts on port `15000`:
```
udpReceiver.findUDP()
```
This will automatically set up a TCP connection to Infinite Flight, which can be accessed through the `ConnectAPI` class.

### Setup a TCP connection with Infinite Flight directly:
```
connectAPI.setupNetworkCommunication(ip: "127.0.0.1")
```
This should be the IPv4 of the device running Infinite Flight.

### Send Commands and Set States:
```
flightControls.trim(step: 5)
flightControls.beacon(value: 0)
flightControls.speedToggle(value: true)
```

### Update States:
```
if let id = connectAPI.StateInfoDict["aircraft/0/systems/autopilot/vnav/on"]?.ID {
    connectAPI.getState(ID: id)
}
```
You can also look up IDs with the `.getID(str: String)` function. This will return `-1` if the string does not exist, and the ID if it does.
```
let id = connectAPI.getID(str: "aircraft/0/systems/autopilot/vnav/on")
if id != -1 {
    connectAPI.getState(ID: id)
}

```

### Look Up Values:
```
let id = connectAPI.getID("aircraft/0/systems/spoilers/state"])
if id != -1 {
    let spoilersPos = connectAPI.StateByID[id]?.value as? Int32 ?? 0
}
```
