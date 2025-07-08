# Bluetooth State Recovery Implementation

## Overview

This implementation adds automatic Bluetooth state recovery to the bitchat app, ensuring robust operation when Bluetooth connectivity is interrupted or becomes unavailable.

## Features Added

### 1. State Tracking
- **Central Manager State**: Tracks the state of the CBCentralManager
- **Peripheral Manager State**: Tracks the state of the CBPeripheralManager
- **Recovery Status**: Monitors whether recovery is in progress

### 2. Automatic Recovery Logic
- **State Change Detection**: Monitors when Bluetooth managers transition from `poweredOn` to other states
- **Recovery Timer**: Implements a 2-second interval timer that attempts recovery up to 5 times
- **Smart Recovery**: Only attempts recovery for recoverable states (ignores `unsupported` and `unauthorized`)

### 3. Recovery Process
1. **Detection**: When either manager goes from `poweredOn` to `poweredOff`, `resetting`, or `unknown`
2. **Recovery Start**: Begins monitoring both managers for return to `poweredOn` state
3. **Full Recovery**: When both managers are `poweredOn`, reinitializes services:
   - Restarts scanning
   - Sets up peripheral services
   - Starts advertising
   - Sends broadcast announcements to rejoin the mesh network
4. **Failure Handling**: After 5 failed attempts (10 seconds), stops recovery and notifies the user

### 4. User Notifications
The recovery system provides user feedback through system messages:
- **Recovery Success**: "bluetooth connection restored. reconnecting to mesh network..."
- **Recovery Failure**: "bluetooth recovery failed. please check your bluetooth settings..."
- **Bluetooth Off**: "bluetooth is turned off. please enable bluetooth to continue messaging."
- **Permission Denied**: "bluetooth permission denied. please allow bluetooth access in settings."

## Implementation Details

### New Properties in BluetoothMeshService
```swift
private var centralManagerState: CBManagerState = .unknown
private var peripheralManagerState: CBManagerState = .unknown
private var stateRecoveryTimer: Timer?
private var recoveryAttempts: Int = 0
private let maxRecoveryAttempts: Int = 5
private var isRecovering: Bool = false
```

### New Protocol: BluetoothRecoveryDelegate
```swift
enum BluetoothRecoveryEvent {
    case bluetoothRecovered
    case bluetoothRecoveryFailed
    case bluetoothStateChanged(central: String, peripheral: String)
}

protocol BluetoothRecoveryDelegate: AnyObject {
    func bluetoothRecoveryEvent(_ event: BluetoothRecoveryEvent)
}
```

### Key Methods Added
- `startStateRecovery()`: Initiates the recovery process
- `attemptStateRecovery()`: Periodic recovery attempts
- `stopStateRecovery()`: Ends recovery process
- `onBluetoothFullyRecovered()`: Handles successful recovery
- `stateToString()`: Converts CBManagerState to readable string

## Usage

The recovery system works automatically without requiring any changes to existing code. The ChatViewModel automatically implements the `BluetoothRecoveryDelegate` protocol and displays appropriate system messages to users.

## Benefits

1. **Improved Reliability**: Automatically recovers from temporary Bluetooth interruptions
2. **Better User Experience**: Provides clear feedback about Bluetooth status
3. **Mesh Network Stability**: Ensures devices rejoin the mesh network after recovery
4. **Battery Efficiency**: Stops unnecessary recovery attempts for permanent failures
5. **Graceful Degradation**: Handles different failure modes appropriately

## Testing Scenarios

To test the recovery system:

1. **Bluetooth Toggle**: Turn Bluetooth off and on in Settings
2. **App Backgrounding**: Background the app during active connections
3. **System Bluetooth Reset**: Reset network settings to trigger Bluetooth restart
4. **Permission Changes**: Revoke and re-grant Bluetooth permissions
5. **Low Battery**: Test behavior when system limits Bluetooth functionality

## Configuration

The recovery system uses these configurable parameters:
- **Recovery Interval**: 2 seconds between attempts
- **Max Attempts**: 5 attempts before giving up
- **Total Recovery Time**: 10 seconds maximum

These can be adjusted based on testing and user feedback.

## Future Enhancements

Potential improvements for the recovery system:
1. **Exponential Backoff**: Increase delay between recovery attempts
2. **User Controls**: Allow users to manually trigger recovery
3. **Recovery Statistics**: Track recovery success rates for optimization
4. **Advanced Diagnostics**: Provide detailed Bluetooth state information
5. **Recovery Notifications**: System-level notifications for recovery events
