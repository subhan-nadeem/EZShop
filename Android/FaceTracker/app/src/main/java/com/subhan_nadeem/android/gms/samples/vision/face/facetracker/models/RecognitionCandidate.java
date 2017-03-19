package com.subhan_nadeem.android.gms.samples.vision.face.facetracker.models;

/**
 * Created by Subhan Nadeem on 2017-03-18.
 */

public class RecognitionCandidate {
    public String getUUID() {
        return UUID;
    }

    public void setUUID(String UUID) {
        this.UUID = UUID;
    }

    public double getConfidence() {
        return confidence;
    }

    public void setConfidence(double confidence) {
        this.confidence = confidence;
    }

    public long getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(long timestamp) {
        this.timestamp = timestamp;
    }

    private String UUID;
    private double confidence;
    private long timestamp;
}
