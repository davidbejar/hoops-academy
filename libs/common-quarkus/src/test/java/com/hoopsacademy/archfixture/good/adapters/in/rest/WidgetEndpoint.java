package com.hoopsacademy.archfixture.good.adapters.in.rest;

import com.hoopsacademy.archfixture.good.application.CreateWidget;
import com.hoopsacademy.archfixture.good.domain.Widget;
import com.hoopsacademy.common.tenancy.TenantId;

public class WidgetEndpoint {

    private final CreateWidget createWidget;

    public WidgetEndpoint(CreateWidget createWidget) {
        this.createWidget = createWidget;
    }

    public void post(String name) {
        createWidget.create(new Widget(TenantId.random(), name));
    }
}
