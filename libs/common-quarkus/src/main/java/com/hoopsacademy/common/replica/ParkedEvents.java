package com.hoopsacademy.common.replica;

/**
 * Where refused records are noted for an operator ({@code <schema>.parked_event}, global, the app role may only
 * insert); parking the same record again (a replay) is a no-op.
 */
public interface ParkedEvents {

    void park(ParkedEvent event);
}
