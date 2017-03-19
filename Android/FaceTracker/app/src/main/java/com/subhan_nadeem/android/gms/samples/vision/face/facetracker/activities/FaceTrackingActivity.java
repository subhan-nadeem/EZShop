/*
 * Copyright (C) The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.subhan_nadeem.android.gms.samples.vision.face.facetracker.activities;

import android.Manifest;
import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Bundle;
import android.speech.tts.TextToSpeech;
import android.support.design.widget.Snackbar;
import android.support.v4.app.ActivityCompat;
import android.support.v7.app.AppCompatActivity;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.vision.CameraSource;
import com.google.android.gms.vision.MultiProcessor;
import com.google.android.gms.vision.Tracker;
import com.google.android.gms.vision.face.Face;
import com.google.android.gms.vision.face.FaceDetector;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;
import com.google.gson.JsonObject;
import com.koushikdutta.async.future.FutureCallback;
import com.koushikdutta.ion.Ion;
import com.subhan_nadeem.android.gms.samples.vision.face.facetracker.App;
import com.subhan_nadeem.android.gms.samples.vision.face.facetracker.FaceGraphic;
import com.subhan_nadeem.android.gms.samples.vision.face.facetracker.FaceProximityListener;
import com.subhan_nadeem.android.gms.samples.vision.face.facetracker.R;
import com.subhan_nadeem.android.gms.samples.vision.face.facetracker.models.RecognitionCandidate;
import com.subhan_nadeem.android.gms.samples.vision.face.facetracker.models.User;
import com.subhan_nadeem.android.gms.samples.vision.face.facetracker.ui.camera.CameraSourcePreview;
import com.subhan_nadeem.android.gms.samples.vision.face.facetracker.ui.camera.GraphicOverlay;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.concurrent.TimeUnit;

import static com.subhan_nadeem.android.gms.samples.vision.face.facetracker.App.ttsObj;

/**
 * Activity for the face tracker app.  This app detects faces with the rear facing camera, and draws
 * overlay graphics to indicate the position, size, and ID of each face.
 */
public final class FaceTrackingActivity extends AppCompatActivity
        implements FaceProximityListener {
    public static final String app_id = "4724eb0e";
    public static final String api_key = "f5795e224117ac3393343c6bc14c841b";
    public static final String GALLERY_ID = "ezshop";
    public static final String URL_RECOGNIZE = "https://api.kairos.com/recognize";
    public static final String KEY_APP_ID = "app_id";
    public static final String KEY_APP_KEY = "app_key";
    public static final String KEY_GALLERY_NAME = "gallery_name";
    public static final String KEY_IMAGE = "image";

    public static final float FACE_WIDTH_PROXIMITY_TRIGGER = 130f;

    public static final int PURPOSE_ENTRANCE = 1;
    public static final int PURPOSE_EXIT = 2;
    public static final int PURPOSE_ITEM = 3;
    public static final int NO_ITEM_PICKED_UP = -1;
    private static final String TAG = "FaceTracker";
    private static final int RC_HANDLE_GMS = 9001;
    // permission request codes need to be < 256
    private static final int RC_HANDLE_CAMERA_PERM = 2;
    private static final String FIREBASE_PUSH_TOKEN = "AAAAFMfSvcA:APA91bGkiVlrAimQLWJKkdvTgF_" +
            "ow4KF17vq7VEkPjglNUmbvPIU3XrSe8f8pkRHr8YuVMN_4_4-HTx" +
            "fvngfmCCNSEo9rP3e0HG8zruRi17WPLmuKLfncAZNAN3Ch4LVLcY2XyzT-Eqm";
    private static final long NUM_SECONDS_WAIT_BETWEEN_RECOGNIZE = 2;
    public static String EXTRA_CAMERA_PURPOSE = "cameraPurpose";
    public static String URL_PUSH_NOTIFICATION = "https://fcm.googleapis.com/fcm/send";
    private static int MAX_RECOGNITION_ATTEMPTS = 3;
    private CameraSource mCameraSource = null;
    private CameraSourcePreview mPreview;
    private GraphicOverlay mGraphicOverlay;
    private ProgressBar mProgressBar;
    private int mPurpose;
    private long mLastTriggerTime;
    private ArrayList<Integer> alreadyRecognizedFacesList = new ArrayList<>();
    private DatabaseReference mDatabase;
    private DatabaseReference mUserDatabase;
    private int mRecognitionAttempts;
    private TextView mPersonText;
    private DatabaseReference mEventDatabase;
    private int mItemPickedUp;
    private DatabaseReference mInventoryDatabase;
    private String mUserFCMToken;

    public static Intent newIntent(Context appContext, int cameraPurpose) {
        Intent i = new Intent(appContext, FaceTrackingActivity.class);
        i.putExtra(EXTRA_CAMERA_PURPOSE, cameraPurpose);
        return i;
    }

    public static void fadeIn(final View view) {
        view.setVisibility(View.VISIBLE);
        view.setAlpha(0);
        final int DURATION = 1000;
        view.animate().setDuration(DURATION).alpha(1).setListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                view.setVisibility(View.VISIBLE);
            }
        });
    }

    public static void fadeOut(final View view) {
        final int DURATION = 800;
        view.animate().setDuration(DURATION).alpha(0).setListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                view.setVisibility(View.INVISIBLE);
            }
        });
    }

    /**
     * Initializes the UI and initiates the creation of a face detector.
     */
    @Override
    public void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        setContentView(R.layout.main);

        mPreview = (CameraSourcePreview) findViewById(R.id.preview);
        mGraphicOverlay = (GraphicOverlay) findViewById(R.id.faceOverlay);
        initializePermissions();

        initializeProgressBar();

        mLastTriggerTime = System.currentTimeMillis();

        mPurpose = getIntent().getExtras().getInt(EXTRA_CAMERA_PURPOSE);

        mItemPickedUp = NO_ITEM_PICKED_UP;

        mPreview.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mCameraSource.takePicture(new CameraSource.ShutterCallback() {
                    @Override
                    public void onShutter() {
                    }
                }, new CameraSource.PictureCallback() {
                    @Override
                    public void onPictureTaken(byte[] bytes) {
                        Log.d(TAG, "Picture taken!");
                    }
                });
            }
        });

        initializeSwitchCameraButton();

        mDatabase = FirebaseDatabase.getInstance().getReference();
        mUserDatabase = mDatabase.child("users");
        mInventoryDatabase = mDatabase.child("inventories");
        mEventDatabase = mDatabase.child("events");

        mPersonText = (TextView) findViewById(R.id.personText);
        mPersonText.setVisibility(View.INVISIBLE);

        if (mPurpose == PURPOSE_ITEM) {
            listenForEvents();
        }
    }

    private void listenForEvents() {

        mEventDatabase.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                for (DataSnapshot event : dataSnapshot.getChildren()) {
                    mItemPickedUp = Integer.parseInt(event.child("item_id").getValue().toString());
                }

                if (mItemPickedUp != NO_ITEM_PICKED_UP)
                    recognize(false, false);
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });
    }

    private void initializePermissions() {
        // Check for the camera permission before accessing the camera.  If the
        // permission is not granted yet, request permission.
        int rc = ActivityCompat.checkSelfPermission(this, Manifest.permission.CAMERA);
        if (rc == PackageManager.PERMISSION_GRANTED) {
            createCameraSource(false);
        } else {
            requestCameraPermission();
        }
    }

    private void initializeSwitchCameraButton() {
        findViewById(R.id.cameraButton).setOnClickListener(new View.OnClickListener() {
            boolean rearFacing = false;

            @Override
            public void onClick(View v) {
                rearFacing = !rearFacing;
                mCameraSource.stop();
                mPreview.stop();
                mPreview.release();
                mCameraSource = null;

                createCameraSource(rearFacing);
                startCameraSource();
            }
        });
    }

    private void initializeProgressBar() {
        mProgressBar = (ProgressBar) findViewById(R.id.progressBar);
        mProgressBar.setIndeterminate(true);
        mProgressBar.setVisibility(View.GONE);
    }

    //==============================================================================================
    // Camera Source Preview
    //==============================================================================================

    /**
     * Handles the requesting of the camera permission.  This includes
     * showing a "Snackbar" message of why the permission is needed then
     * sending the request.
     */
    private void requestCameraPermission() {
        Log.w(TAG, "Camera permission is not granted. Requesting permission");

        final String[] permissions = new String[]{Manifest.permission.CAMERA};

        if (!ActivityCompat.shouldShowRequestPermissionRationale(this,
                Manifest.permission.CAMERA)) {
            ActivityCompat.requestPermissions(this, permissions, RC_HANDLE_CAMERA_PERM);
            return;
        }

        final Activity thisActivity = this;

        View.OnClickListener listener = new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                ActivityCompat.requestPermissions(thisActivity, permissions,
                        RC_HANDLE_CAMERA_PERM);
            }
        };

        Snackbar.make(mGraphicOverlay, R.string.permission_camera_rationale,
                Snackbar.LENGTH_INDEFINITE)
                .setAction(R.string.ok, listener)
                .show();
    }

    /**
     * Creates and starts the camera.  Note that this uses a higher resolution in comparison
     * to other detection examples to enable the barcode detector to detect small barcodes
     * at long distances.
     */
    private void createCameraSource(boolean rearFacing) {

        int typeCamera;

        if (rearFacing)
            typeCamera = CameraSource.CAMERA_FACING_BACK;
        else
            typeCamera = CameraSource.CAMERA_FACING_FRONT;

        Context context = getApplicationContext();
        FaceDetector detector = new FaceDetector.Builder(context)
                .setClassificationType(FaceDetector.ALL_CLASSIFICATIONS)
                .build();

        detector.setProcessor(
                new MultiProcessor.Builder<>(new GraphicFaceTrackerFactory())
                        .build());

        if (!detector.isOperational()) {
            // Note: The first time that an app using face API is installed on a device, GMS will
            // download a native library to the device in order to do detection.  Usually this
            // completes before the app is run for the first time.  But if that download has not yet
            // completed, then the above call will not detect any faces.
            //
            // isOperational() can be used to check if the required native library is currently
            // available.  The detector will automatically become operational once the library
            // download completes on device.
            Log.w(TAG, "Face detector dependencies are not yet available.");
        }

        mCameraSource = new CameraSource.Builder(context, detector)
                .setRequestedPreviewSize(getResources().getDisplayMetrics().widthPixels,
                        getResources().getDisplayMetrics().heightPixels)
                .setFacing(typeCamera)
                .setRequestedFps(30.0f)
                .build();
    }

    /**
     * Restarts the camera.
     */
    @Override
    protected void onResume() {
        super.onResume();

        startCameraSource();
    }

    /**
     * Stops the camera.
     */
    @Override
    protected void onPause() {
        super.onPause();
        mPreview.stop();
    }

    /**
     * Releases the resources associated with the camera source, the associated detector, and the
     * rest of the processing pipeline.
     */
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (mCameraSource != null) {
            mCameraSource.release();
        }
    }

    /**
     * Callback for the result from requesting permissions. This method
     * is invoked for every call on {@link #requestPermissions(String[], int)}.
     * <p>
     * <strong>Note:</strong> It is possible that the permissions request interaction
     * with the user is interrupted. In this case you will receive empty permissions
     * and results arrays which should be treated as a cancellation.
     * </p>
     *
     * @param requestCode  The request code passed in {@link #requestPermissions(String[], int)}.
     * @param permissions  The requested permissions. Never null.
     * @param grantResults The grant results for the corresponding permissions
     *                     which is either {@link PackageManager#PERMISSION_GRANTED}
     *                     or {@link PackageManager#PERMISSION_DENIED}. Never null.
     * @see #requestPermissions(String[], int)
     */
    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode != RC_HANDLE_CAMERA_PERM) {
            Log.d(TAG, "Got unexpected permission result: " + requestCode);
            super.onRequestPermissionsResult(requestCode, permissions, grantResults);
            return;
        }

        if (grantResults.length != 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            Log.d(TAG, "Camera permission granted - initialize the camera source");
            // we have permission, so create the camerasource
            createCameraSource(true);
            return;
        }

        Log.e(TAG, "Permission not granted: results len = " + grantResults.length +
                " Result code = " + (grantResults.length > 0 ? grantResults[0] : "(empty)"));

        DialogInterface.OnClickListener listener = new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int id) {
                finish();
            }
        };

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Face Tracker sample")
                .setMessage(R.string.no_camera_permission)
                .setPositiveButton(R.string.ok, listener)
                .show();
    }

    /**
     * Starts or restarts the camera source, if it exists.  If the camera source doesn't exist yet
     * (e.g., because onResume was called before the camera source was created), this will be called
     * again when the camera source is created.
     */
    private void startCameraSource() {

        // check that the device has play services available.
        int code = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(
                getApplicationContext());
        if (code != ConnectionResult.SUCCESS) {
            Dialog dlg =
                    GoogleApiAvailability.getInstance().getErrorDialog(this, code, RC_HANDLE_GMS);
            dlg.show();
        }

        if (mCameraSource != null) {
            try {
                mPreview.start(mCameraSource, mGraphicOverlay);
            } catch (IOException e) {
                Log.e(TAG, "Unable to start camera source.", e);
                mCameraSource.release();
                mCameraSource = null;
            }
        }
    }

    @Override
    public void onFaceProximityTrigger(final Face face) {
        long timeSinceLastTrigger = System.currentTimeMillis() - mLastTriggerTime;

        if (timeSinceLastTrigger < TimeUnit.SECONDS.toMillis(NUM_SECONDS_WAIT_BETWEEN_RECOGNIZE))
            return;

        alreadyRecognizedFacesList.add(face.getId());
        mLastTriggerTime = System.currentTimeMillis();
        mRecognitionAttempts = 1;
        recognize(true, true);
    }

    @Override
    public void onBackPressed() {
        super.onBackPressed();
        finish();
    }

    private void recognize(final boolean sayRecognizingMessage, final boolean sayRetryMessage) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {

                mProgressBar.setVisibility(View.VISIBLE);

                if (sayRecognizingMessage)
                    App.ttsObj.speak("Recognizing", TextToSpeech.QUEUE_ADD, null);

                try {
                    mCameraSource.takePicture(new CameraSource.ShutterCallback() {
                        @Override
                        public void onShutter() {

                        }
                    }, new CameraSource.PictureCallback() {
                        @Override
                        public void onPictureTaken(final byte[] bytes) {
                            new AsyncTask<Void, Void, String>() {
                                @Override
                                protected String doInBackground(Void... params) {
                                    return Base64.encodeToString(bytes, 0);
                                }

                                @Override
                                protected void onPostExecute(String bitmap) {

                                    JsonObject json = new JsonObject();
                                    json.addProperty(KEY_IMAGE, bitmap);
                                    json.addProperty(KEY_GALLERY_NAME, GALLERY_ID);
                                    Ion.with(getApplicationContext())
                                            .load(URL_RECOGNIZE)
                                            .addHeader(KEY_APP_ID, app_id)
                                            .addHeader(KEY_APP_KEY, api_key)
                                            .setJsonObjectBody(json)
                                            .asString()
                                            .setCallback(new FutureCallback<String>() {
                                                @Override
                                                public void onCompleted(Exception e, String result) {
                                                    Log.d(TAG, result);
                                                    mProgressBar.setVisibility(View.GONE);
                                                    try {
                                                        JSONObject jsonObject = new JSONObject(result);
                                                        JSONArray imagesArray = jsonObject.getJSONArray("images");
                                                        JSONObject firstImageObject = imagesArray.getJSONObject(0);

                                                        JSONObject transactionObject =
                                                                firstImageObject.getJSONObject("transaction");

                                                        if (transactionObject.getString("status").equals("failure")) {
                                                            sayErrorMessage();
                                                            return;
                                                        }

                                                        JSONObject candidateObject =
                                                                firstImageObject.getJSONArray("candidates").getJSONObject(0);

                                                        RecognitionCandidate candidate = new RecognitionCandidate();
                                                        candidate.setUUID(candidateObject.getString("subject_id"));
                                                        candidate.setConfidence(candidateObject.getDouble("confidence"));
                                                        candidate.setTimestamp(candidateObject.getLong("enrollment_timestamp"));

                                                        if (mPurpose == PURPOSE_ENTRANCE)
                                                            enterUserIntoShop(candidate);
                                                        else if (mPurpose == PURPOSE_EXIT)
                                                            exitUserFromShop(candidate);
                                                        else if (mPurpose == PURPOSE_ITEM)
                                                            onDetectItemEvent(candidate);

                                                    } catch (JSONException e1) {
                                                        e1.printStackTrace();
                                                        Log.e(TAG, e1.toString());

                                                        if (mRecognitionAttempts != MAX_RECOGNITION_ATTEMPTS) {
                                                            recognize(false, true);

                                                                ttsObj.speak("I couldn't recognize you! Trying again", TextToSpeech.QUEUE_ADD, null);
                                                            ++mRecognitionAttempts;
                                                        }
                                                    }
                                                }
                                            });
                                }
                            }.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, (Void[]) null);
                        }
                    });
                } catch (Exception e) {
                    e.printStackTrace();
                    Toast.makeText(FaceTrackingActivity.this,
                            "Couldn't take photo! Try again.", Toast.LENGTH_LONG).show();
                }
            }
        });
    }

    private String mItemPersonName;
    private String mItemItemName;
    private void onDetectItemEvent(final RecognitionCandidate candidate) {
        final DatabaseReference userCartDatabase = mDatabase.child("store")
                .child(candidate.getUUID())
                .child("cart");

        getPersonNameForItemTTS(candidate);

        getItemNameForItemTTS();

        userCartDatabase.addListenerForSingleValueEvent(new ValueEventListener() {
            boolean itemAdded = false;

            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {

                if (!itemAdded)
                userCartDatabase.child(String.valueOf(dataSnapshot.getChildrenCount()))
                        .setValue(mItemPickedUp);

                itemAdded = true;
                removeEvents();
                mItemPickedUp = NO_ITEM_PICKED_UP;

                ttsObj.speak(mItemPersonName + " picked up a "+mItemItemName, TextToSpeech.QUEUE_ADD, null);
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });
    }

    private void getItemNameForItemTTS() {
        mInventoryDatabase.addListenerForSingleValueEvent(new ValueEventListener() {

            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                for (DataSnapshot item : dataSnapshot.getChildren()) {
                    if (item.child("item_id").getValue().toString().equals(String.valueOf(mItemPickedUp))) {
                        mItemItemName = item.child("item_id").getValue().toString();
                        return;
                    }
                }
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });
    }

    private void getPersonNameForItemTTS(RecognitionCandidate candidate) {
        mUserDatabase.child(candidate.getUUID()).addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                User user = dataSnapshot.getValue(User.class);

                mItemPersonName = user.name;
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });
    }

    private void removeEvents() {
        mEventDatabase.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                for (DataSnapshot event : dataSnapshot.getChildren()) {
                    event.getRef().setValue(null);
                }
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });
    }

    private void exitUserFromShop(final RecognitionCandidate candidate) {
        getUserFirebaseToken(candidate);
        mUserDatabase.child(candidate.getUUID()).addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                User user = dataSnapshot.getValue(User.class);

                String text = "Goodbye, " + user.name;
                showUserText(text);

                if (!user.is_in_store)
                    return;

                mUserDatabase.child(candidate.getUUID()).child("is_in_store").setValue(false);
                ttsObj.speak("Goodbye, " + user.name + "! Thank you for shopping at easyshop",
                        TextToSpeech.QUEUE_ADD, null);

                final DatabaseReference userCartDatabase = mDatabase.child("store")
                        .child(candidate.getUUID())
                        .child("cart");

                userCartDatabase.addListenerForSingleValueEvent(new ValueEventListener() {
                    @Override
                    public void onDataChange(DataSnapshot dataSnapshot) {
                        ArrayList<Integer> cartItems = new ArrayList<>();

                        for (DataSnapshot cartItem : dataSnapshot.getChildren()) {
                            cartItems.add(Integer.valueOf(cartItem.getValue().toString()));
                        }

                        calculateCartTotal(cartItems);

                    }


                    @Override
                    public void onCancelled(DatabaseError databaseError) {

                    }
                });
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });

    }

    private void getUserFirebaseToken(RecognitionCandidate candidate) {
        mUserDatabase.child(candidate.getUUID()).addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                mUserFCMToken = dataSnapshot.child("fcm_token").getValue().toString();
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });
    }

    private void calculateCartTotal(final ArrayList<Integer> cartItems) {
        mInventoryDatabase.addListenerForSingleValueEvent(new ValueEventListener() {
            double totalSpent = 0;

            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                for (int item : cartItems) {
                    totalSpent += Double.parseDouble(
                            dataSnapshot
                                    .child(String.valueOf(item))
                                    .child("item_price")
                                    .getValue().toString());
                }

                sendPushNotification(totalSpent);
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });
    }

    private void sendPushNotification(double totalSpent) {
        DecimalFormat df = new DecimalFormat("0.00");

        JsonObject dataObj = new JsonObject();
        dataObj.addProperty("alert", "Your total is $" + df.format(totalSpent));

        JsonObject notificationObj = new JsonObject();
        notificationObj.addProperty("body", "Your total is $" + df.format(totalSpent));
        notificationObj.addProperty("title", "Thank you for shopping at easyshop!");

        JsonObject pushObj = new JsonObject();
        pushObj.addProperty("to", mUserFCMToken);
        pushObj.addProperty("priority", "high");
        pushObj.add("data", dataObj);
        pushObj.add("notification", notificationObj);
        Ion.with(getApplicationContext())
                .load(URL_PUSH_NOTIFICATION)
                .addHeader("Authorization", "key=" + FIREBASE_PUSH_TOKEN)
                .setJsonObjectBody(pushObj)
                .asString()
                .setCallback(new FutureCallback<String>() {
                    @Override
                    public void onCompleted(Exception e, String result) {
                        Log.d(TAG, "PUSH RESULT: " + result);
                    }
                });
    }

    private void enterUserIntoShop(final RecognitionCandidate candidate) throws JSONException {

        clearUserCart(candidate);
        mUserDatabase.child(candidate.getUUID()).addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                User user = dataSnapshot.getValue(User.class);

                String text = "Hello, " + user.name;
                showUserText(text);

                if (user.is_in_store)
                    return;

                mUserDatabase.child(candidate.getUUID()).child("is_in_store").setValue(true);
                ttsObj.speak("Welcome to easyshop, " + user.name,
                        TextToSpeech.QUEUE_ADD, null);
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        });
    }

    private void clearUserCart(RecognitionCandidate candidate) {
        mDatabase.child("store")
                .child(candidate.getUUID()).setValue(null);
    }

    private void showUserText(String text) {
        if (mPersonText.getVisibility() != View.VISIBLE)
            fadeIn(mPersonText);
        mPersonText.setText(text);
        mPersonText.getHandler().postDelayed(new Runnable() {
            @Override
            public void run() {
                fadeOut(mPersonText);
            }
        }, 5000);
    }

    private void sayErrorMessage() {
        ttsObj.speak("You are not enrolled in our database! Please go enroll now.",
                TextToSpeech.QUEUE_ADD, null);
    }

    //==============================================================================================
    // Graphic Face Tracker
    //==============================================================================================

    /**
     * Factory for creating a face tracker to be associated with a new face.  The multiprocessor
     * uses this factory to create face trackers as needed -- one for each individual.
     */
    private class GraphicFaceTrackerFactory implements MultiProcessor.Factory<Face> {
        @Override
        public Tracker<Face> create(Face face) {
            return new GraphicFaceTracker(mGraphicOverlay);
        }
    }

    /**
     * Face tracker for each detected individual. This maintains a face graphic within the app's
     * associated face overlay.
     */
    private class GraphicFaceTracker extends Tracker<Face> {
        // Bigger is closer
        private GraphicOverlay mOverlay;
        private FaceGraphic mFaceGraphic;

        GraphicFaceTracker(GraphicOverlay overlay) {
            mOverlay = overlay;
            mFaceGraphic = new FaceGraphic(overlay, FaceTrackingActivity.this);
        }

        /**
         * Start tracking the detected face instance within the face overlay.
         */
        @Override
        public void onNewItem(int faceId, Face item) {
            mFaceGraphic.setId(faceId);
        }

        /**
         * Update the position/characteristics of the face within the overlay.
         */
        @Override
        public void onUpdate(FaceDetector.Detections<Face> detectionResults, Face face) {
            mOverlay.add(mFaceGraphic);
            mFaceGraphic.updateFace(face);

            if (face.getWidth() >= FACE_WIDTH_PROXIMITY_TRIGGER
                    && !alreadyRecognizedFacesList.contains(face.getId())
                    && mPurpose != PURPOSE_ITEM) {
                onFaceProximityTrigger(face);
            }
        }

        /**
         * Hide the graphic when the corresponding face was not detected.  This can happen for
         * intermediate frames temporarily (e.g., if the face was momentarily blocked from
         * view).
         */
        @Override
        public void onMissing(FaceDetector.Detections<Face> detectionResults) {
            mOverlay.remove(mFaceGraphic);
        }

        /**
         * Called when the face is assumed to be gone for good. Remove the graphic annotation from
         * the overlay.
         */
        @Override
        public void onDone() {
            alreadyRecognizedFacesList.remove((Object) mFaceGraphic.getFace().getId());
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    /*Toast.makeText(FaceTrackingActivity.this,
                            "FACE " + mFaceGraphic.getFace().getId() + " REMOVED",
                            Toast.LENGTH_SHORT).show();*/
                   /* ttsObj.speak("You are no longer visible", TextToSpeech.QUEUE_ADD, null);*/
                }
            });
            mOverlay.remove(mFaceGraphic);
        }
    }
}
