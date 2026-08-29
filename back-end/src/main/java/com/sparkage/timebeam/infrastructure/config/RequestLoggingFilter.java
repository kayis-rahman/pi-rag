package com.sparkage.timebeam.infrastructure.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingRequestWrapper;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Component
public class RequestLoggingFilter extends OncePerRequestFilter {

    private static final Logger logger = LoggerFactory.getLogger(RequestLoggingFilter.class);

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        // Wrap request and response to cache content
        ContentCachingRequestWrapper requestWrapper = new ContentCachingRequestWrapper(request);
        ContentCachingResponseWrapper responseWrapper = new ContentCachingResponseWrapper(response);

        long startTime = System.currentTimeMillis();

        try {
            filterChain.doFilter(requestWrapper, responseWrapper);

            long duration = System.currentTimeMillis() - startTime;

            // Log request
            logRequest(requestWrapper);

            // Log response
            logResponse(responseWrapper, duration);

        } finally {
            // Copy response content back to original response
            responseWrapper.copyBodyToResponse();
        }
    }

    private void logRequest(ContentCachingRequestWrapper request) {
        String method = request.getMethod();
        String uri = request.getRequestURI();
        String queryString = request.getQueryString();
        String fullUri = uri + (queryString != null ? "?" + queryString : "");

        logger.debug(">>> REQUEST: {} {} from {}:{}",
            method, fullUri,
            request.getRemoteAddr(), request.getRemotePort());

        // Log headers
        request.getHeaderNames().asIterator().forEachRemaining(headerName -> {
            if (!headerName.equalsIgnoreCase("authorization")) { // Don't log auth tokens
                logger.debug(">>> REQUEST HEADER: {} = {}", headerName, request.getHeader(headerName));
            } else {
                logger.debug(">>> REQUEST HEADER: {} = [REDACTED]", headerName);
            }
        });

        // Log body for POST/PUT/PATCH requests
        byte[] content = request.getContentAsByteArray();
        if (content.length > 0) {
            String body = new String(content, StandardCharsets.UTF_8);
            // Truncate very long bodies
            if (body.length() > 2000) {
                body = body.substring(0, 2000) + "... [TRUNCATED]";
            }
            logger.debug(">>> REQUEST BODY: {}", body);
        }
    }

    private void logResponse(ContentCachingResponseWrapper response, long duration) {
        int status = response.getStatus();

        logger.debug("<<< RESPONSE: {} in {}ms", status, duration);

        // Log headers
        response.getHeaderNames().forEach(headerName -> {
            logger.debug("<<< RESPONSE HEADER: {} = {}", headerName, response.getHeader(headerName));
        });

        // Log body for error responses or small responses
        byte[] content = response.getContentAsByteArray();
        if (content.length > 0) {
            // Only log body for errors (4xx/5xx) or small responses
            if (status >= 400 || content.length < 1000) {
                String body = new String(content, StandardCharsets.UTF_8);
                logger.debug("<<< RESPONSE BODY: {}", body);
            } else {
                logger.debug("<<< RESPONSE BODY: [{} bytes - not logged for performance]", content.length);
            }
        }
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        // Skip logging for static resources and health checks
        return path.startsWith("/actuator/health") ||
               path.startsWith("/css/") ||
               path.startsWith("/js/") ||
               path.startsWith("/images/") ||
               path.startsWith("/favicon");
    }
}
