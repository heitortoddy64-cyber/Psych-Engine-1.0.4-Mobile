package mobile.backend.java;

import android.app.Activity;
import android.content.Intent;
import android.app.ProgressDialog;
import android.net.Uri;
import android.database.Cursor;
import android.provider.OpenableColumns;
import android.util.Base64;
import android.os.Handler;
import android.os.Looper;
import org.haxe.extension.Extension;
import java.io.OutputStream;
import java.io.InputStream;
import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.net.URL;
import android.util.Log;
import java.net.HttpURLConnection;

/**
 * * @Authors LumiCoder, (FNF BR) and StarNova, (Cream.BR)
 * 
 * @version: 0.1.6
 **/
public class FileUtils extends Extension {

    private static final int CREATE_FILE_CODE = 1024;
    private static final int PICK_FILE_CODE = 1025;
    private static boolean downloadSuccess = false;
    private static boolean isFinished = false;
    private static String contentToSave = "";
    private static boolean binaryRead = false;
    private static String saveFileName = "";

    public static org.haxe.lime.HaxeObject callbackObject;

    public static void saveFile(final String fileName, final String data, final org.haxe.lime.HaxeObject callback) {
        contentToSave = data == null ? "" : data;
        saveFileName = fileName;
        callbackObject = callback;

        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                try {
                    Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
                    intent.addCategory(Intent.CATEGORY_OPENABLE);
                    intent.setType("application/json");
                    intent.putExtra(Intent.EXTRA_TITLE, fileName);

                    if (Extension.mainActivity != null) {
                        Extension.mainActivity.startActivityForResult(intent, CREATE_FILE_CODE);
                    } else {
                        notifyCallback("onFileError", new Object[] {});
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    notifyCallback("onFileError", new Object[] {});
                }
            }
        });
    }

    public static void browseFiles(final String mimeType, final org.haxe.lime.HaxeObject callback) {
        browse(mimeType, callback, false);
    }

    public static void browseBinaryFiles(final String mimeType, final org.haxe.lime.HaxeObject callback) {
        browse(mimeType, callback, true);
    }

    private static void browse(final String mimeType, final org.haxe.lime.HaxeObject callback, boolean binary) {
        binaryRead = binary;
        callbackObject = callback;
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                try {
                    Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                    intent.addCategory(Intent.CATEGORY_OPENABLE);
                    intent.setType(mimeType != null ? mimeType : "*/*");

                    if (Extension.mainActivity != null) {
                        Extension.mainActivity.startActivityForResult(intent, PICK_FILE_CODE);
                    } else {
                        notifyCallback("onFileError", new Object[] {});
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    notifyCallback("onFileError", new Object[] {});
                }
            }
        });
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == CREATE_FILE_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                Uri uri = data.getData();
                if (uri != null) {
                    writeFileToUri(uri);
                } else { notifyCallback("onFileError", new Object[] {}); }
            } else {
                contentToSave = "";
                notifyCallback("onFileCancelled", new Object[] {});
            }
            return true;
        }

        if (requestCode == PICK_FILE_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                Uri uri = data.getData();
                if (uri != null && callbackObject != null) {
                    readBytesFromUri(uri);
                } else { notifyCallback("onFileError", new Object[] {}); }
            } else {
                notifyCallback("onFileCancelled", new Object[] {});
            }
            return true;
        }

        return false;
    }

    private static void writeFileToUri(final Uri uri) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    try (OutputStream fileOutputStream = Extension.mainActivity.getContentResolver().openOutputStream(uri, "wt")) {
                        if (fileOutputStream == null) throw new java.io.IOException("No output stream");
                        byte[] bytesToWrite = contentToSave.getBytes("UTF-8");

                        fileOutputStream.write(bytesToWrite);
                        fileOutputStream.flush();
                        fileOutputStream.close();

                        contentToSave = "";
                        notifyCallback("onFileSaved", new Object[] { saveFileName });
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    notifyCallback("onFileError", new Object[] {});
                }
            }
        }).start();
    }

    private static void readBytesFromUri(final Uri uri) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    try (InputStream inputStream = Extension.mainActivity.getContentResolver().openInputStream(uri);
                         ByteArrayOutputStream byteBuffer = new ByteArrayOutputStream()) {
                    if (inputStream == null) throw new java.io.IOException("No input stream");

                    byte[] buffer = new byte[1024];
                    int len;
                    while ((len = inputStream.read(buffer)) != -1) {
                        byteBuffer.write(buffer, 0, len);
                    }

                    final byte[] bytes = byteBuffer.toByteArray();
                    final String fileContent = binaryRead ? Base64.encodeToString(bytes, Base64.NO_WRAP) : new String(bytes, "UTF-8");
                    String fileName = uri.getLastPathSegment();
                    try (Cursor cursor = Extension.mainActivity.getContentResolver().query(uri, null, null, null, null)) {
                        if (cursor != null && cursor.moveToFirst()) {
                            int column = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
                            if (column >= 0) fileName = cursor.getString(column);
                        }
                    }
                    if (fileName == null) fileName = binaryRead ? "import.png" : "import.json";
                    // Return a leaf name, never a provider-controlled filesystem path.
                    fileName = fileName.replace('\\', '/');
                    fileName = fileName.substring(fileName.lastIndexOf('/') + 1);

                    notifyCallback("onFileSelected", new Object[] { fileContent, fileName });

                    inputStream.close();
                    byteBuffer.close();
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    notifyCallback("onFileError", new Object[] {});
                }
            }
        }).start();
    }

    private static void notifyCallback(final String method, final Object[] args) {
        final org.haxe.lime.HaxeObject callback = callbackObject;
        if (callback == null) return;

        Extension.callbackHandler.post(new Runnable() {
            @Override
            public void run() {
                if (callbackObject == callback) {
                    callbackObject = null;
                    contentToSave = "";
                    callback.call(method, args);
                }
            }
        });
    }

    public static boolean downloadFile(String fileURL, String savePath) {
        try {
            URL url = new URL(fileURL);
            HttpURLConnection httpConn = (HttpURLConnection) url.openConnection();
            httpConn.setRequestProperty("User-Agent", "Mozilla/5.0");
            httpConn.setInstanceFollowRedirects(true);

            int responseCode = httpConn.getResponseCode();

            if (responseCode == HttpURLConnection.HTTP_OK) {
                InputStream inputStream = httpConn.getInputStream();
                FileOutputStream outputStream = new FileOutputStream(savePath);

                byte[] buffer = new byte[4096];
                int bytesRead = -1;
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
                }

                outputStream.close();
                inputStream.close();
                return true;
            } else {
                return false;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
}