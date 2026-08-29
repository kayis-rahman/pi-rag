package com.sparkage.timebeam.presentation.dto;

public class TaskProgressResponseDto {
    private int completedSessions;
    private long totalTimeSpentSeconds;
    private double progressPercentage;

    public TaskProgressResponseDto() {}

    public TaskProgressResponseDto(int completedSessions, long totalTimeSpentSeconds, double progressPercentage) {
        this.completedSessions = completedSessions;
        this.totalTimeSpentSeconds = totalTimeSpentSeconds;
        this.progressPercentage = progressPercentage;
    }

    public int getCompletedSessions() { return completedSessions; }
    public void setCompletedSessions(int completedSessions) { this.completedSessions = completedSessions; }

    public long getTotalTimeSpentSeconds() { return totalTimeSpentSeconds; }
    public void setTotalTimeSpentSeconds(long totalTimeSpentSeconds) { this.totalTimeSpentSeconds = totalTimeSpentSeconds; }

    public double getProgressPercentage() { return progressPercentage; }
    public void setProgressPercentage(double progressPercentage) { this.progressPercentage = progressPercentage; }
}
