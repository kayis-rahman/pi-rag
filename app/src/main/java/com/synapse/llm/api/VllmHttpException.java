package com.synapse.llm.api;

/**
 * Exception that carries the original HTTP status code from vLLM.
 * Used to propagate error codes (400, 404, 500, etc.) instead of always returning 502.
 */
public class VllmHttpException extends RuntimeException {
    private final int statusCode;

    public VllmHttpException(int statusCode, String body) {
        super("vLLM error (" + statusCode + "): " + body);
        this.statusCode = statusCode;
    }

    public int getStatus() {
        return statusCode;
    }
}
