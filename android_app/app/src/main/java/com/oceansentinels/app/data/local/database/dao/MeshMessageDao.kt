package com.oceansentinels.app.data.local.database.dao

import androidx.room.*
import com.oceansentinels.app.data.local.database.entity.MeshMessageEntity
import kotlinx.coroutines.flow.Flow

/**
 * DAO for mesh message queue operations.
 * Manages the local queue of hazard reports waiting to be sent
 * via internet or relayed through the BLE mesh network.
 */
@Dao
interface MeshMessageDao {

    // ==================== Queries ====================

    /** Get all messages ordered by urgency (critical first) then by creation time */
    @Query("""
        SELECT * FROM mesh_messages 
        ORDER BY 
            CASE urgency 
                WHEN 'critical' THEN 0 
                WHEN 'high' THEN 1 
                WHEN 'medium' THEN 2 
                WHEN 'low' THEN 3 
            END,
            created_at_millis DESC
    """)
    fun getAllMessages(): Flow<List<MeshMessageEntity>>

    /** Get all messages as a list (non-flow) */
    @Query("SELECT * FROM mesh_messages ORDER BY created_at_millis DESC")
    suspend fun getAllMessagesList(): List<MeshMessageEntity>

    /** Get a message by its unique mesh ID */
    @Query("SELECT * FROM mesh_messages WHERE message_id = :messageId LIMIT 1")
    suspend fun getByMessageId(messageId: String): MeshMessageEntity?

    /** Get a message by local auto-increment ID */
    @Query("SELECT * FROM mesh_messages WHERE local_id = :localId")
    suspend fun getByLocalId(localId: Long): MeshMessageEntity?

    /** Check if a message with this ID already exists (for deduplication) */
    @Query("SELECT COUNT(*) > 0 FROM mesh_messages WHERE message_id = :messageId")
    suspend fun exists(messageId: String): Boolean

    /** Get pending messages that need to be sent, ordered by priority */
    @Query("""
        SELECT * FROM mesh_messages 
        WHERE status IN ('pending', 'failed') 
        AND retry_count < max_retries
        AND expires_at > :now
        ORDER BY 
            CASE urgency 
                WHEN 'critical' THEN 0 
                WHEN 'high' THEN 1 
                WHEN 'medium' THEN 2 
                WHEN 'low' THEN 3 
            END,
            created_at_millis ASC
    """)
    suspend fun getPendingMessages(now: String): List<MeshMessageEntity>

    /** Get own non-delivered messages as flow for Queue tab (includes 'relayed' status) */
    @Query("""
        SELECT * FROM mesh_messages 
        WHERE is_own_message = 1 AND status IN ('pending', 'sending', 'failed', 'relayed') 
        ORDER BY created_at_millis DESC
    """)
    fun getPendingMessagesFlow(): Flow<List<MeshMessageEntity>>

    /** Get delivered messages */
    @Query("""
        SELECT * FROM mesh_messages 
        WHERE status = 'delivered' 
        ORDER BY delivered_at DESC
    """)
    fun getDeliveredMessages(): Flow<List<MeshMessageEntity>>

    /** Get own messages (created by this device) */
    @Query("""
        SELECT * FROM mesh_messages 
        WHERE is_own_message = 1 
        ORDER BY created_at_millis DESC
    """)
    fun getOwnMessages(): Flow<List<MeshMessageEntity>>

    /** Get relayed messages: received from others OR own messages relayed via mesh */
    @Query("""
        SELECT * FROM mesh_messages 
        WHERE is_own_message = 0 OR has_been_relayed = 1 
        ORDER BY created_at_millis DESC
    """)
    fun getRelayedMessages(): Flow<List<MeshMessageEntity>>

    /**
     * Get messages that have been relayed but not yet delivered to server.
     * Includes BOTH received-from-others AND own messages that were relayed
     * via mesh. Previously excluded own relayed messages (is_own_message = 0),
     * which meant own messages never got uploaded when internet returned.
     */
    @Query("""
        SELECT * FROM mesh_messages 
        WHERE status = 'relayed'
        AND retry_count < max_retries
        ORDER BY 
            CASE urgency 
                WHEN 'critical' THEN 0 
                WHEN 'high' THEN 1 
                WHEN 'medium' THEN 2 
                WHEN 'low' THEN 3 
            END
    """)
    suspend fun getRelayedUndelivered(): List<MeshMessageEntity>

    /** Get messages not yet relayed to peers */
    @Query("""
        SELECT * FROM mesh_messages 
        WHERE has_been_relayed = 0 
        AND status IN ('pending', 'sending')
        ORDER BY created_at_millis ASC
    """)
    suspend fun getUnrelayedMessages(): List<MeshMessageEntity>

    /**
     * Get messages that were already relayed to some peers but haven't been
     * delivered to server. These can be re-broadcast to newly connected peers
     * (broadcastMessage skips peers already in relay_path).
     * No TTL filter — messages relay until time-based expiry (72h) or server delivery.
     */
    @Query("""
        SELECT * FROM mesh_messages 
        WHERE has_been_relayed = 1 
        AND status IN ('relayed', 'pending', 'sending')
        ORDER BY 
            CASE urgency 
                WHEN 'critical' THEN 0 
                WHEN 'high' THEN 1 
                WHEN 'medium' THEN 2 
                WHEN 'low' THEN 3 
            END,
            created_at_millis ASC
    """)
    suspend fun getRelayableMessages(): List<MeshMessageEntity>

    /** Count messages by status */
    @Query("SELECT COUNT(*) FROM mesh_messages WHERE status = :status")
    suspend fun countByStatus(status: String): Int

    /** Count own pending messages */
    @Query("SELECT COUNT(*) FROM mesh_messages WHERE is_own_message = 1 AND status IN ('pending', 'sending', 'failed')")
    suspend fun countOwnPending(): Int

    /** Count total delivered */
    @Query("SELECT COUNT(*) FROM mesh_messages WHERE status = 'delivered'")
    suspend fun countDelivered(): Int

    /** Count total relayed for others */
    @Query("SELECT COUNT(*) FROM mesh_messages WHERE is_own_message = 0")
    suspend fun countRelayed(): Int

    /** Get expired messages */
    @Query("SELECT * FROM mesh_messages WHERE expires_at <= :now AND status != 'delivered'")
    suspend fun getExpiredMessages(now: String): List<MeshMessageEntity>

    // ==================== Inserts ====================

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(message: MeshMessageEntity): Long

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(messages: List<MeshMessageEntity>)

    // ==================== Updates ====================

    @Update
    suspend fun update(message: MeshMessageEntity)

    /** Mark a message as delivered */
    @Query("""
        UPDATE mesh_messages 
        SET status = 'delivered', 
            delivered_at = :deliveredAt, 
            transport = :transport,
            server_reference_id = :serverRefId
        WHERE message_id = :messageId
    """)
    suspend fun markDelivered(
        messageId: String,
        deliveredAt: String,
        transport: String,
        serverRefId: String?
    )

    /** Mark a message as sending */
    @Query("UPDATE mesh_messages SET status = 'sending' WHERE message_id = :messageId")
    suspend fun markSending(messageId: String)

    /** Mark a message as failed and increment retry count */
    @Query("""
        UPDATE mesh_messages 
        SET status = 'failed', 
            retry_count = retry_count + 1,
            last_attempt_at = :attemptedAt
        WHERE message_id = :messageId
    """)
    suspend fun markFailed(messageId: String, attemptedAt: String)

    /** Mark a message as relayed */
    @Query("""
        UPDATE mesh_messages 
        SET status = 'relayed', has_been_relayed = 1 
        WHERE message_id = :messageId
    """)
    suspend fun markRelayed(messageId: String)

    /** Mark a message relay path updated */
    @Query("""
        UPDATE mesh_messages 
        SET has_been_relayed = 1, relay_path = :relayPath 
        WHERE message_id = :messageId
    """)
    suspend fun updateRelayPath(messageId: String, relayPath: String)

    // ==================== Deletes ====================

    @Delete
    suspend fun delete(message: MeshMessageEntity)

    @Query("DELETE FROM mesh_messages WHERE message_id = :messageId")
    suspend fun deleteByMessageId(messageId: String)

    /** Delete expired messages */
    @Query("DELETE FROM mesh_messages WHERE expires_at <= :now AND status = 'delivered'")
    suspend fun deleteExpiredDelivered(now: String)

    /** Delete all messages */
    @Query("DELETE FROM mesh_messages")
    suspend fun deleteAll()

    /**
     * Keep the most important N messages, delete the rest.
     * Priority: urgency weight (critical=0, high=1, medium=2, low=3),
     * then delivery status (undelivered before delivered), then newest first.
     * This ensures critical hazard reports survive eviction over old low-urgency ones.
     */
    @Query("""
        DELETE FROM mesh_messages 
        WHERE local_id NOT IN (
            SELECT local_id FROM mesh_messages 
            ORDER BY 
                CASE urgency 
                    WHEN 'critical' THEN 0 
                    WHEN 'high' THEN 1 
                    WHEN 'medium' THEN 2 
                    WHEN 'low' THEN 3 
                    ELSE 4 
                END ASC,
                CASE status 
                    WHEN 'pending' THEN 0 
                    WHEN 'sending' THEN 1 
                    WHEN 'relayed' THEN 2 
                    WHEN 'failed' THEN 3 
                    WHEN 'delivered' THEN 4 
                    ELSE 5 
                END ASC,
                created_at_millis DESC 
            LIMIT :limit
        )
    """)
    suspend fun trimToLimit(limit: Int = 500)

    // ==================== Processed Message IDs (Deduplication) ====================

    /** Get all known message IDs for deduplication */
    @Query("SELECT message_id FROM mesh_messages")
    suspend fun getAllMessageIds(): List<String>
}
