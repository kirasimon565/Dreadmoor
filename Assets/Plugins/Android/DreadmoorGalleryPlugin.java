package com.blackmoonstudio.dreadmoor;

import android.app.Activity;
import android.app.Fragment;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;

import com.unity3d.player.UnityPlayer;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

/**
 * Uses Android's Storage Access Framework. No broad storage permission is
 * requested; only the URI selected by the player is read and copied into the
 * application's private cache directory.
 */
public final class DreadmoorGalleryPlugin {
    private static final String TAG = "DreadmoorImagePicker";

    private DreadmoorGalleryPlugin() { }

    public static void pickImage(final Activity activity, final String gameObject, final String callback) {
        if (activity == null) {
            UnityPlayer.UnitySendMessage(gameObject, callback, "ERROR:Android activity unavailable");
            return;
        }
        activity.runOnUiThread(() -> {
            PickerFragment existing = (PickerFragment) activity.getFragmentManager().findFragmentByTag(TAG);
            if (existing != null) {
                existing.launch(gameObject, callback);
                return;
            }
            PickerFragment fragment = new PickerFragment();
            Bundle arguments = new Bundle();
            arguments.putString("gameObject", gameObject);
            arguments.putString("callback", callback);
            fragment.setArguments(arguments);
            activity.getFragmentManager().beginTransaction().add(fragment, TAG).commitAllowingStateLoss();
            activity.getFragmentManager().executePendingTransactions();
            fragment.launch(gameObject, callback);
        });
    }

    public static final class PickerFragment extends Fragment {
        private static final int REQUEST_IMAGE = 8421;
        private String gameObject = "DreadmoorApplication";
        private String callback = "OnAvatarPicked";
        private boolean launched;

        @Override
        public void onCreate(Bundle state) {
            super.onCreate(state);
            setRetainInstance(true);
            Bundle arguments = getArguments();
            if (arguments != null) {
                gameObject = arguments.getString("gameObject", gameObject);
                callback = arguments.getString("callback", callback);
            }
        }

        void launch(String target, String method) {
            gameObject = target;
            callback = method;
            if (launched || getActivity() == null) return;
            launched = true;
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            intent.setType("image/*");
            startActivityForResult(intent, REQUEST_IMAGE);
        }

        @Override
        public void onActivityResult(int requestCode, int resultCode, Intent data) {
            super.onActivityResult(requestCode, resultCode, data);
            launched = false;
            if (requestCode != REQUEST_IMAGE) return;
            if (resultCode != Activity.RESULT_OK || data == null || data.getData() == null) {
                send("");
                removeSelf();
                return;
            }
            Uri uri = data.getData();
            try {
                File destination = new File(getActivity().getFilesDir(), "dreadmoor_player_avatar.png");
                try (InputStream input = getActivity().getContentResolver().openInputStream(uri);
                     FileOutputStream output = new FileOutputStream(destination, false)) {
                    if (input == null) throw new IllegalStateException("Selected image could not be opened");
                    byte[] buffer = new byte[16 * 1024];
                    int count;
                    long total = 0;
                    final long maximum = 20L * 1024L * 1024L;
                    while ((count = input.read(buffer)) >= 0) {
                        total += count;
                        if (total > maximum) throw new IllegalStateException("Selected image exceeds 20 MB");
                        output.write(buffer, 0, count);
                    }
                    output.flush();
                }
                send(destination.getAbsolutePath());
            } catch (Exception exception) {
                send("ERROR:" + exception.getMessage());
            }
            removeSelf();
        }

        private void send(String value) {
            UnityPlayer.UnitySendMessage(gameObject, callback, value == null ? "" : value);
        }

        private void removeSelf() {
            if (getActivity() != null)
                getActivity().getFragmentManager().beginTransaction().remove(this).commitAllowingStateLoss();
        }
    }
}
