# SwiftFlight
---

SwiftFlight provides a straightforward way to connect with Infinite Flight's Connect API v2.

## Installation
---

### CocoaPods
---

SwiftFlight currently supports installation via CocoaPods.

Add the following to your `Podfile`:

```
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/tomthetank46/PodSpecs'

target 'InfiniteControl' do
    pod 'SwiftFlight', '~> 0.1.5'
end
```

And then run `pod install`

## Code Examples:
---

### Create an instance of `NewConnectAPI` and pass it to `UDPReceiver` and `FlightControls` instances:
```
import SwiftFlight

let newConnectAPI = NewConnectAPI()
let udpReceiver = UDPReceiver(API: newConnectAPI)
let flightControls = FlightControls(API: newConnectAPI)
```

### Send Commands and Set States:
---
```
flightControls.trim(step: 5)
flightControls.beacon(value: 0)
flightControls.speedToggle(value: true)
```

### Update States:
---
```
let id = newConnectAPI.StateInfoDict["aircraft/0/systems/autopilot/vnav/on"]?.ID
newConnectAPI.getState(ID: id)
```

### Look Up Values:
---
```
let spoilers = newConnectAPI.StateInfoDict["aircraft/0/systems/spoilers/state"]?.ID
let spoilersPos = newConnectAPI.StateByID[spoilers]?.value as? Int32 ?? 0
```
