package com.hoopsacademy.common.tenancy;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;

/** The pure rules of {@link TenantScope#runExclusive}: the advisory key of a lock name and its transaction timeout. */
final class ExclusiveLocks {

    private ExclusiveLocks() {
    }

    /** Stable 64-bit advisory lock key of a lock name (first 8 bytes of its SHA-256), equal in every JVM. */
    static long advisoryKey(String lockKey) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(lockKey.getBytes(StandardCharsets.UTF_8));
            return ByteBuffer.wrap(digest).getLong();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is always available", e);
        }
    }

    /** The JTA timeout of the lock transaction: {@code timeout} in whole seconds, capped at what JTA accepts. */
    static int transactionTimeoutSeconds(Duration timeout) {
        return (int) Math.min(Integer.MAX_VALUE, timeout.toSeconds());
    }
}
