# OceanHazard BLE Mesh - Analysis & Upgrade Guide

> **Analysis Date**: February 15, 2026  
> **Component**: OceanHazard Android App - BLE Mesh Networking  
> **Purpose**: Critical errors identification for upgrade planning

---

## Executive Summary

The OceanHazard BLE Mesh implementation follows a sound architectural concept (BitChat-inspired) with dual PHY advertising, TTL-based flooding, and deterministic message IDs. However, **14 critical and high-severity issues** have been identified that will cause mesh network failure on modern Android devices.

**⚠️ CRITICAL**: The mesh will NOT function correctly on Android 6+ devices due to MAC address privacy restrictions.

---

## 🔴 CRITICAL ERRORS (Must Fix Before Production)

### 1. MAC Address Privacy Issue - COMPLETE MESH FAILURE

**Affected Files:**
- `MeshForegroundService.kt`
- `MeshMessageRepository.kt`
- `BleMeshManager.kt`

**Problem:**
Since Android 6.0 (API 23), `BluetoothAdapter.getAddress()` returns `02:00:00:00:00:00` instead of the real MAC address for privacy protection.

```kotlin
// CURRENT BROKEN CODE (Multiple locations)
val deviceMac = try {
    bluetoothManager.adapter?.address ?: "00:00:00:00:00:00"
} catch (e: SecurityException) {
    "00:00:00:00:00:00"
}
```

**Impact:**
- ❌ All Android 6+ devices appear to have the SAME MAC address
- ❌ Message ID collisions (SHA-256 uses MAC as input)
- ❌ Loop detection fails (relies on unique MAC addresses)
- ❌ Relay path tracking completely broken
- ❌ Cannot distinguish between devices

**Upgrade Required:**
```kotlin
// SOLUTION: Generate persistent device ID stored in SharedPreferences
class DeviceIdentifier @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val prefs = context.getSharedPreferences("mesh_prefs", Context.MODE_PRIVATE)
    
    fun getDeviceId(): String {
        var id = prefs.getString("device_mesh_id", null)
        if (id == null) {
            id = UUID.randomUUID().toString().replace("-", "").take(12)
            prefs.edit().putString("device_mesh_id", id).apply()
        }
        return id
    }
    
    // For display/legacy purposes - get MAC from connected devices only
    fun getPeerMac(device: BluetoothDevice): String = device.address
}
```

---

### 2. Mesh ID Truncation Bug

**Location:** `MeshForegroundService.kt:115-116`

**Problem:**
```kotlin
val meshId = MeshMessage.generateDeviceFingerprint(deviceMac, androidId)
    .take(8).toByteArray(Charsets.UTF_8)  // ❌ WRONG
```

**Issue:** Takes 8 characters from hex string (should be 16 for 64-bit), then UTF-8 encoding creates collisions.

**Fix:**
```kotlin
val fullFingerprint = MeshMessage.generateDeviceFingerprint(deviceMac, androidId)
val meshId = fullFingerprint.hexToByteArray()  // Use full 8 bytes (16 hex chars)
```

---

### 3. Message Relay State Inconsistency

**Location:** `MeshForegroundService.kt:handleReceivedMessage()`

**Problem:**
```kotlin
val relayed = message.relay(getDeviceMac())
if (relayed != null) {
    val sentCount = bleMeshManager.broadcastMessage(relayed)
    if (sentCount > 0) {
        meshRepository.markRelayed(message.messageId)  // ❌ Wrong message ID!
    }
}
```

**Issue:**
- `message.relay()` creates a NEW message object with updated path
- But `markRelayed()` is called on ORIGINAL message ID
- No tracking that THIS device has relayed the message

**Fix:**
```kotlin
private suspend fun handleReceivedMessage(message: MeshMessage) {
    if (meshRepository.isMessageKnown(message.messageId)) return
    
    // Save original first
    meshRepository.saveReceivedMessage(message)
    
    // Create relay version with this device in path
    val deviceId = getDeviceId()  // Use proper device ID, not MAC
    val relayedMessage = message.relay(deviceId)
    
    if (relayedMessage != null) {
        val sentCount = bleMeshManager.broadcastMessage(relayedMessage)
        if (sentCount > 0) {
            // Mark that WE relayed this message
            meshRepository.markRelayedByThisDevice(message.messageId, deviceId)
        }
    }
    
    // Try server delivery
    if (hasInternet) {
        meshRepository.tryDeliverToServer(message)
    }
}
```

---

### 4. Database Status Inconsistency

**Location:** `MeshMessageEntity.kt:fromDomain()`

**Problem:**
```kotlin
// When saving received message:
suspend fun saveReceivedMessage(message: MeshMessage) {
    val entity = MeshMessageEntity.fromDomain(
        message,
        isOwnMessage = false,
        transport = MeshTransport.BLE_CODED
    ).copy(status = MeshMessageStatus.RELAYED.value)  // Sets RELAYED
    
    // BUT fromDomain() ALSO sets status from message.status!
    // Result: unpredictable status
}
```

**Fix:**
```kotlin
// In MeshMessageEntity.kt
companion object {
    fun fromDomain(
        message: MeshMessage,
        isOwnMessage: Boolean = true,
        transport: MeshTransport = MeshTransport.LOCAL_QUEUE,
        overrideStatus: MeshMessageStatus? = null  // Add this
    ): MeshMessageEntity {
        return MeshMessageEntity(
            // ...
            status = (overrideStatus ?: message.status).value,  // Use override if provided
            // ...
        )
    }
}
```

---

## 🟠 HIGH SEVERITY ISSUES

### 5. No MTU/Fragmentation Handling

**Location:** `BleMeshManager.kt:broadcastMessage()`

**Problem:**
```kotlin
fun broadcastMessage(message: MeshMessage): Int {
    val data = message.toBytes()  // Can be 500+ bytes!
    // ... directly writes without checking MTU
    characteristic.value = data
    gatt.writeCharacteristic(characteristic)  // Will fail if > MTU
}
```

**Constants defined but unused:**
```kotlin
const val MAX_PACKET_SIZE = 512
const val FRAGMENT_SIZE = 469
```

**Fix Required:**
```kotlin
fun broadcastMessage(message: MeshMessage): Int {
    val data = message.toBytes()
    
    // Fragment if needed
    if (data.size > FRAGMENT_SIZE) {
        return sendFragmented(data, message.messageId)
    }
    
    return sendSingle(data)
}

private fun sendFragmented(data: ByteArray, messageId: String): Int {
    val fragments = data.chunked(FRAGMENT_SIZE)
    val header = MeshFragmentHeader(
        messageId = messageId,
        totalFragments = fragments.size,
        // ...
    )
    // Implement fragmentation protocol
}
```

---

### 6. Fragile JSON Parsing with Regex

**Location:** `BleMeshManager.kt:parseMeshMessage()`

**Problem:**
```kotlin
private fun extractStringField(json: String, field: String): String? {
    val regex = Regex("\"$field\"\\s*:\\s*\"((?:[^"\\\\]|\\\\.)*)\"")
    return regex.find(json)?.groupValues?.get(1)
}
```

**Issues:**
- Breaks with nested JSON
- Breaks with special characters
- Breaks with escaped quotes
- No validation

**Fix:**
```kotlin
// Use kotlinx.serialization or Gson
@Serializable
data class MeshMessageDto(
    @SerialName("id") val messageId: String,
    @SerialName("mac") val originDeviceMac: String,
    // ...
)

private fun parseMeshMessage(json: String): MeshMessage? {
    return try {
        Json.decodeFromString<MeshMessageDto>(json).toDomain()
    } catch (e: Exception) {
        Timber.e(e, "Failed to parse mesh message")
        null
    }
}
```

---

### 7. Queue Processing Race Condition

**Location:** `MeshForegroundService.kt`

**Problem:**
```kotlin
// Called from multiple places without synchronization:
// 1. Periodic queue processor (every 30s)
// 2. Network availability callback
// 3. Manual flush action

suspend fun processQueue() {
    if (!isInternetAvailable()) return
    val messages = meshMessageDao.getPendingMessages(now)  // ❌ No lock
    messages.forEach { tryDeliverToServer(it.toDomain()) }
}
```

**Fix:**
```kotlin
private val queueProcessingLock = Mutex()

suspend fun processQueue() {
    queueProcessingLock.withLock {
        if (!isInternetAvailable()) return
        
        // Double-check after acquiring lock
        val messages = meshMessageDao.getPendingMessages(LocalDateTime.now().toString())
        messages.forEach { message ->
            // Check again before each delivery
            if (message.status != MeshMessageStatus.DELIVERED.value) {
                tryDeliverToServer(message.toDomain())
            }
        }
    }
}
```

---

### 8. Memory Leak in processedMessageIds

**Location:** `BleMeshManager.kt`

**Problem:**
```kotlin
private val processedMessageIds = LinkedHashSet<String>()

fun markProcessed(messageId: String) {
    synchronized(processedMessageIds) {
        processedMessageIds.add(messageId)
        if (processedMessageIds.size > maxProcessedIds) {
            val iterator = processedMessageIds.iterator()
            repeat(processedMessageIds.size - maxProcessedIds) {
                if (iterator.hasNext()) {
                    iterator.next()
                    iterator.remove()  // ❌ May cause issues
                }
            }
        }
    }
}
```

**Better Approach:**
```kotlin
// Use a circular buffer or LRU cache
private val processedMessageIds = Collections.synchronizedSet(
    object : LinkedHashSet<String>(maxProcessedIds, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Boolean>): Boolean {
            return size > maxProcessedIds
        }
    }
)
```

---

### 9. PHY Upgrade Race Condition

**Location:** `BleMeshManager.kt:gattClientCallback`

**Problem:**
```kotlin
override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
    when (newState) {
        BluetoothProfile.STATE_CONNECTED -> {
            // ...
            handler.postDelayed({
                // ❌ Connection might be disconnected by now
                gatt.setPreferredPhy(PHY_LE_CODED, PHY_LE_CODED, PHY_OPTION_S8)
            }, 1000)
        }
    }
}
```

**Fix:**
```kotlin
private val activeConnections = ConcurrentHashMap<String, BluetoothGatt>()

override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
    when (newState) {
        BluetoothProfile.STATE_CONNECTED -> {
            activeConnections[gatt.device.address] = gatt
            // ...
        }
        BluetoothProfile.STATE_DISCONNECTED -> {
            activeConnections.remove(gatt.device.address)
            // ...
        }
    }
}

// In PHY upgrade:
handler.postDelayed({
    if (activeConnections.containsKey(gatt.device.address)) {
        try {
            gatt.setPreferredPhy(PHY_LE_CODED, PHY_LE_CODED, PHY_OPTION_S8)
        } catch (e: Exception) {
            Timber.w(e, "PHY upgrade failed")
        }
    }
}, 1000)
```

---

## 🟡 MEDIUM SEVERITY ISSUES

### 10. Message Expiry Not Enforced

**Location:** `MeshMessageDao.kt`

**Problem:**
```kotlin
// Query exists but never called:
@Query("SELECT * FROM mesh_messages WHERE expires_at <= :now AND status != 'delivered'")
suspend fun getExpiredMessages(now: String): List<MeshMessageEntity>
```

**Fix:**
```kotlin
// Add to MeshForegroundService:startQueueProcessor()
private fun startQueueProcessor() {
    serviceScope.launch {
        while (isActive && _isServiceRunning.value) {
            // Clean up expired messages
            meshRepository.cleanupExpiredMessages()
            
            if (hasInternet) {
                meshRepository.processQueue()
            }
            delay(QUEUE_CHECK_INTERVAL_MS)
        }
    }
}
```

---

### 11. No Acknowledgment System

**Problem:** Fire-and-forget flooding with no delivery confirmation.

**Recommendation:** Implement ACK protocol:
```kotlin
data class MeshAck(
    val originalMessageId: String,
    val ackFromDeviceId: String,
    val timestamp: Long
)

// After sending, expect ACK within timeout
// Retry if no ACK received
```

---

### 12. Connectivity Check Thread Safety

**Location:** `MeshMessageRepository.kt:isInternetAvailable()`

**Problem:** Called from multiple coroutines without synchronization.

**Fix:**
```kotlin
private val _hasInternet = AtomicBoolean(false)

fun updateInternetStatus(available: Boolean) {
    _hasInternet.set(available)
}

fun isInternetAvailable(): Boolean = _hasInternet.get()
```

---

### 13. Incorrect Status Mapping in ViewModel

**Location:** `MeshViewModel.kt`

**Problem:**
```kotlin
val transport = when (message.status) {
    MeshMessageStatus.DELIVERED -> MeshTransport.INTERNET  // ❌ Not always!
    MeshMessageStatus.RELAYED -> MeshTransport.BLE_CODED
    else -> MeshTransport.LOCAL_QUEUE
}
```

**Fix:** Store actual transport used in the entity, don't infer from status.

---

### 14. Missing Relay Path Persistence

**Problem:** When relaying, the updated path is not saved back to database.

**Fix:**
```kotlin
suspend fun updateRelayPath(messageId: String, newPath: List<String>) {
    meshMessageDao.updateRelayPath(messageId, newPath.joinToString(","))
}
```

---

## 📋 Upgrade Priority Matrix

| Priority | Issue | Effort | Impact |
|----------|-------|--------|--------|
| P0 | MAC Address Privacy | Medium | Mesh non-functional on Android 6+ |
| P0 | Device ID Generation | Low | Identity collisions |
| P1 | JSON Serialization | Low | Message parsing failures |
| P1 | Queue Race Condition | Low | Duplicate deliveries |
| P1 | MTU Fragmentation | Medium | Large message failures |
| P2 | Memory Leak Fix | Low | Stability issues |
| P2 | PHY Race Condition | Low | Connection instability |
| P2 | Status Consistency | Low | UI state issues |
| P3 | Message Expiry | Low | DB bloat |
| P3 | ACK Protocol | High | Reliability improvement |

---

## 🔧 Recommended Upgrade Path

### Phase 1: Critical Fixes (Week 1)
1. Replace MAC-based ID with persistent UUID
2. Fix mesh ID truncation
3. Fix relay state tracking
4. Fix database status inconsistency

### Phase 2: Reliability (Week 2)
1. Implement proper JSON serialization (kotlinx.serialization)
2. Add queue processing mutex
3. Add MTU negotiation and fragmentation
4. Fix memory leak in deduplication

### Phase 3: Enhancements (Week 3)
1. Add ACK protocol
2. Implement message expiry cleanup
3. Add comprehensive logging
4. Add metrics/analytics

---

## 📝 Files Requiring Changes

| File | Lines to Change | Priority |
|------|-----------------|----------|
| `BleMeshManager.kt` | 50+ | P0, P1 |
| `MeshForegroundService.kt` | 30+ | P0, P1 |
| `MeshMessageRepository.kt` | 40+ | P0, P1 |
| `MeshMessageEntity.kt` | 15+ | P0 |
| `MeshMessageDao.kt` | 10+ | P1 |
| `MeshViewModel.kt` | 10+ | P2 |
| `MeshModule.kt` | 5+ | P0 |

---

## ✅ Testing Checklist for Upgrade

- [ ] Test on Android 12+ (API 31+)
- [ ] Test on Android 10 (API 29)
- [ ] Test on Android 8 (API 26)
- [ ] Verify unique device IDs across devices
- [ ] Verify message relay with 3+ devices
- [ ] Verify loop detection works
- [ ] Test with 1KB+ descriptions
- [ ] Test offline → online transition
- [ ] Test concurrent message sending
- [ ] Verify no memory leaks (profile 1 hour)

---

*End of Analysis Document*
