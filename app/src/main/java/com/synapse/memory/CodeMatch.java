package com.synapse.memory;

public class CodeMatch {
    private String filePath;
    private String contentPreview;
    private Float similarityScore;

    // Constructors
    public CodeMatch() {}

    public CodeMatch(String filePath, String contentPreview, Float similarityScore) {
        this.filePath = filePath;
        this.contentPreview = contentPreview;
        this.similarityScore = similarityScore;
    }

    // Getters and setters
    public String getFilePath() {
        return filePath;
    }

    public void setFilePath(String filePath) {
        this.filePath = filePath;
    }

    public String getContentPreview() {
        return contentPreview;
    }

    public void setContentPreview(String contentPreview) {
        this.contentPreview = contentPreview;
    }

    public Float getSimilarityScore() {
        return similarityScore;
    }

    public void setSimilarityScore(Float similarityScore) {
        this.similarityScore = similarityScore;
    }
}