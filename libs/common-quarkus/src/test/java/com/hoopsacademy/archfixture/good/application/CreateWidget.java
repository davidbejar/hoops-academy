package com.hoopsacademy.archfixture.good.application;

import com.hoopsacademy.archfixture.good.domain.Widget;
import jakarta.transaction.Transactional;

public class CreateWidget {

    private final WidgetPort port;

    public CreateWidget(WidgetPort port) {
        this.port = port;
    }

    @Transactional
    public void create(Widget widget) {
        port.save(widget);
    }
}
