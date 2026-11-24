package com.hoopsacademy.common.telemetry;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.TraceFlags;
import io.opentelemetry.api.trace.TraceState;
import io.opentelemetry.context.Context;
import io.opentelemetry.sdk.trace.samplers.SamplingDecision;
import java.util.List;
import org.junit.jupiter.api.Test;

/** WP143, ADR-0074: the configured parent-based ratio sampler, except that a database span needs a parent. */
class DatabaseSpansNeedAParentTest {

    private static final String TRACE = "0af7651916cd43dd8448eb211c80319c";
    private static final Attributes DATABASE = Attributes.builder().put("db.system", "postgresql").build();
    private static final Context NO_PARENT = Context.root();

    private static Context parent(TraceFlags flags) {
        return Context.root().with(Span.wrap(
                SpanContext.createFromRemoteParent(TRACE, "b7ad6b7169203331", flags, TraceState.getDefault())));
    }

    private static SamplingDecision decide(double ratio, Context parent, SpanKind kind, Attributes attributes) {
        return new DatabaseSpansNeedAParent(DatabaseSpansNeedAParent.CONFIGURED, ratio)
                .shouldSample(parent, TRACE, "span", kind, attributes, List.of()).getDecision();
    }

    @Test
    void aDatabaseSpanWithoutAParentIsDroppedWhateverTheRatio() {
        assertThat(decide(1.0, NO_PARENT, SpanKind.CLIENT, DATABASE)).isEqualTo(SamplingDecision.DROP);
    }

    @Test
    void aDatabaseSpanFollowsItsParent() {
        assertThat(decide(0.0, parent(TraceFlags.getSampled()), SpanKind.CLIENT, DATABASE))
                .isEqualTo(SamplingDecision.RECORD_AND_SAMPLE);
        assertThat(decide(1.0, parent(TraceFlags.getDefault()), SpanKind.CLIENT, DATABASE))
                .isEqualTo(SamplingDecision.DROP);
    }

    @Test
    void anyOtherRootFollowsTheRatio() {
        assertThat(decide(1.0, NO_PARENT, SpanKind.SERVER, Attributes.empty())).isEqualTo(SamplingDecision.RECORD_AND_SAMPLE);
        assertThat(decide(0.0, NO_PARENT, SpanKind.SERVER, Attributes.empty())).isEqualTo(SamplingDecision.DROP);
        assertThat(decide(1.0, NO_PARENT, SpanKind.CLIENT, Attributes.empty()))
                .as("a REST call of a job is not a database span").isEqualTo(SamplingDecision.RECORD_AND_SAMPLE);
    }

    @Test
    void aRequestFollowsTheCallersDecision() {
        assertThat(decide(0.0, parent(TraceFlags.getSampled()), SpanKind.SERVER, Attributes.empty()))
                .isEqualTo(SamplingDecision.RECORD_AND_SAMPLE);
        assertThat(decide(1.0, parent(TraceFlags.getDefault()), SpanKind.SERVER, Attributes.empty()))
                .isEqualTo(SamplingDecision.DROP);
    }

    @Test
    void onlyTheParentBasedRatioSamplerIsReplaced() {
        assertThatThrownBy(() -> new DatabaseSpansNeedAParent("always_on", 1.0))
                .isInstanceOf(IllegalStateException.class).hasMessageContaining("parentbased_traceidratio");
    }
}
