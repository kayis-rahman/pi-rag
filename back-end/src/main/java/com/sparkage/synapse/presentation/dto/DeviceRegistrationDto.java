package com.sparkage.synapse.presentation.dto;

public class DeviceRegistrationDto {
    private String deviceId;
    private String deviceName;
    private String deviceType;
    private String platformVersion;
    private String appVersion;
    private String apnsToken;

    public DeviceRegistrationDto() {}

    public DeviceRegistrationDto(String deviceId, String deviceName, String deviceType,
                                String platformVersion, String appVersion, String apnsToken) {
        this.deviceId = deviceId;
        this.deviceName = deviceName;
        this.deviceType = deviceType;
        this.platformVersion = platformVersion;
        this.appVersion = appVersion;
        this.apnsToken = apnsToken;
    }

    // Getters and setters
    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }

    public String getDeviceName() { return deviceName; }
    public void setDeviceName(String deviceName) { this.deviceName = deviceName; }

    public String getDeviceType() { return deviceType; }
    public void setDeviceType(String deviceType) { this.deviceType = deviceType; }

    public String getPlatformVersion() { return platformVersion; }
    public void setPlatformVersion(String platformVersion) { this.platformVersion = platformVersion; }

    public String getAppVersion() { return appVersion; }
    public void setAppVersion(String appVersion) { this.appVersion = appVersion; }

    public String getApnsToken() { return apnsToken; }
    public void setApnsToken(String apnsToken) { this.apnsToken = apnsToken; }

    @Override
    public String toString() {
        return "DeviceRegistrationDto{" +
                "deviceId='" + deviceId + '\'' +
                ", deviceName='" + deviceName + '\'' +
                ", deviceType='" + deviceType + '\'' +
                ", platformVersion='" + platformVersion + '\'' +
                ", appVersion='" + appVersion + '\'' +
                '}';
    }
}
