package com.hoopsacademy.athlete.application.replica;

/** Where refused records are noted for an operator (athlete.parked_event, insert only); parking the same record again is a
 * no-op. */
public interface ParkedEvents {

    void park(ParkedEvent event);
}
