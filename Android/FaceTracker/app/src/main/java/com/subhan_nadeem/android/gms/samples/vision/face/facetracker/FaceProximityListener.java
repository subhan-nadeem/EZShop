package com.subhan_nadeem.android.gms.samples.vision.face.facetracker;

import com.google.android.gms.vision.face.Face;

/**
 * Created by Subhan Nadeem on 2017-03-18.
 */
public interface FaceProximityListener {
    void onFaceProximityTrigger(Face face);
}
