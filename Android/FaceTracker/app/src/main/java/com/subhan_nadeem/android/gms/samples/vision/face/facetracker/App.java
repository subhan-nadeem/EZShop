package com.subhan_nadeem.android.gms.samples.vision.face.facetracker;

import android.app.Application;
import android.speech.tts.TextToSpeech;

import java.util.Locale;

/**
 * Created by Subhan Nadeem on 2017-03-18.
 */

public class App extends Application {
    public static TextToSpeech ttsObj;

    @Override
    public void onCreate() {
        super.onCreate();
        initializeTTS();
    }

    private void initializeTTS() {
        ttsObj = new TextToSpeech(getApplicationContext(), new TextToSpeech.OnInitListener() {
            @Override
            public void onInit(int status) {
                if (status != TextToSpeech.ERROR) {
                    ttsObj.setLanguage(Locale.UK);
                }
            }
        });
    }
}
