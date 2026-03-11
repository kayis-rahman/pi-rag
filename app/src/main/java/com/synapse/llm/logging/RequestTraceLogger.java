package com.synapse.llm.logging;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Sinks;
import reactor.core.scheduler.Schedulers;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

/**
 * Async, non-blocking request trace logger using Project Reactor hot sink.
 * Enqueues log lines to a Sinks.Many and subscribes on boundedElastic() to write
 * asynchronously to a file, preventing any blocking I/O on Netty event-loop threads.
 */
@Component
@Slf4j
public class RequestTraceLogger {

    private static final DateTimeFormatter TIMESTAMP_FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS").withZone(ZoneId.systemDefault());

    private final Sinks.Many<String> sink = Sinks.many().multicast().onBackpressureBuffer(1024, false);
    private final Path logFile;

    public RequestTraceLogger(@Value("${synapse.logging.trace-file:logs/synapse-trace.log}") String path) {
        this.logFile = Path.of(path);

        // Ensure parent directory exists at init time
        try {
            Files.createDirectories(logFile.getParent());
            log.info("Trace log directory created: {}", logFile.getParent().toAbsolutePath());
        } catch (IOException e) {
            log.warn("Failed to create trace log directory: {}", e.getMessage());
        }

        // Subscribe on boundedElastic to drain sink asynchronously
        sink.asFlux()
            .subscribeOn(Schedulers.boundedElastic())
            .subscribe(
                line -> {
                    try {
                        Files.writeString(
                            logFile,
                            line + "\n",
                            StandardOpenOption.CREATE,
                            StandardOpenOption.APPEND
                        );
                    } catch (IOException e) {
                        log.warn("Trace log write failed: {}", e.getMessage());
                    }
                },
                e -> log.error("Trace logger subscriber error: {}", e.getMessage()),
                () -> log.info("Trace logger subscriber completed")
            );

        log.info("RequestTraceLogger initialized, writing to: {}", logFile.toAbsolutePath());
    }

    /**
     * Log a request at entry point.
     */
    public void logRequest(String model, int messageCount, boolean stream) {
        String timestamp = TIMESTAMP_FORMATTER.format(Instant.now());
        String line = String.format(
            "%s | REQUEST | model=%s | messages=%d | stream=%s",
            timestamp, model, messageCount, stream
        );
        sink.tryEmitNext(line);
    }

    /**
     * Log a response at completion.
     */
    public void logResponse(String model, int statusCode, long latencyMs, String error) {
        String timestamp = TIMESTAMP_FORMATTER.format(Instant.now());
        String line = String.format(
            "%s | RESPONSE | model=%s | status=%d | latency=%dms | error=%s",
            timestamp, model, statusCode, latencyMs, error != null ? error : "null"
        );
        sink.tryEmitNext(line);
    }

    /**
     * Generic log line (for debugging/tracing other events).
     */
    public void log(String line) {
        sink.tryEmitNext(line);
    }
}
