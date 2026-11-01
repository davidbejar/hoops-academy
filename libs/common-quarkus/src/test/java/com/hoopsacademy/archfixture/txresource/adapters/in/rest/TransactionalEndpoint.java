package com.hoopsacademy.archfixture.txresource.adapters.in.rest;

import jakarta.transaction.Transactional;

public class TransactionalEndpoint {

    @Transactional
    public void post() {}
}
