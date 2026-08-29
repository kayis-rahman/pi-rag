package com.sparkage.timebeam.presentation.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class TimeController {

    @GetMapping("/time")
    public Map<String, Object> getServerTime() {
        long unixTimestamp = Instant.now().getEpochSecond();
        double preciseTimestamp = Instant.now().getEpochSecond() +
                                (double) Instant.now().getNano() / 1_000_000_000.0;

        return Map.of(
            "unixTimestamp", unixTimestamp,
            "preciseTimestamp", preciseTimestamp,
            "utcTime", Instant.now().toString(),
            "serverTimeZone", "UTC"
        );
    }
}