package com.hoopsacademy.core.testsupport;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.LogRecord;
import java.util.logging.Logger;
import org.jboss.logmanager.ExtLogRecord;

/**
 * Captures every log record of the service (root logger, all levels the categories emit; {@code com.hoopsacademy} is at
 * DEBUG in tests) while open: formatted message plus the stack trace and messages of any throwable. Used to prove that a
 * secret never reaches the logs.
 */
public final class LogCapture implements AutoCloseable {

    private final List<String> lines = new CopyOnWriteArrayList<>();
    private final Handler handler = new Handler() {
        @Override
        public void publish(LogRecord record) {
            StringBuilder line = new StringBuilder(record.getLoggerName()).append(' ').append(message(record));
            if (record.getThrown() != null) {
                StringWriter trace = new StringWriter();
                record.getThrown().printStackTrace(new PrintWriter(trace));
                line.append('\n').append(trace);
            }
            lines.add(line.toString());
        }

        @Override
        public void flush() {}

        @Override
        public void close() {}
    };

    private LogCapture() {
        handler.setLevel(Level.ALL);
        Logger.getLogger("").addHandler(handler);
    }

    public static LogCapture start() {
        return new LogCapture();
    }

    public List<String> lines() {
        return List.copyOf(lines);
    }

    /** The captured lines containing {@code text}. */
    public List<String> containing(String text) {
        return lines.stream().filter(line -> line.contains(text)).toList();
    }

    @Override
    public void close() {
        Logger.getLogger("").removeHandler(handler);
    }

    private static String message(LogRecord record) {
        if (record instanceof ExtLogRecord ext) {
            return ext.getFormattedMessage();
        }
        return String.valueOf(record.getMessage());
    }
}
