package com.synapse;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties
public class SynapseApplication {
    public static void main(String[] args) {
        SpringApplication.run(SynapseApplication.class, args);
    }
}