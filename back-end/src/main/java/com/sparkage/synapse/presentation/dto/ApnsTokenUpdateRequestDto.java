package com.sparkage.synapse.presentation.dto;

/**
 * DTO for updating APNs token for a device
 */
public class ApnsTokenUpdateRequestDto {
    private String deviceId;
    private String apnsToken;

    public ApnsTokenUpdateRequestDto() {}

    public ApnsTokenUpdateRequestDto(String deviceId, String apnsToken) {
        this.deviceId = deviceId;
        this.apnsToken = apnsToken;
    }

    // Getters and setters
    public String getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }

    public String getApnsToken() {
        return apnsToken;
    }

    public void setApnsToken(String apnsToken) {
        this.apnsToken = apnsToken;
    }

    @Override
    public String toString() {
        return "ApnsTokenUpdateRequestDto{" +
                "deviceId='" + deviceId + '\'' +
                ", apnsToken='" + (apnsToken != null ? "***" : "null") + '\'' +
                '}';
    }
}
