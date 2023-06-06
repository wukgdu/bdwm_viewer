// https://github.com/ponnamkarthik/FlutterToast/blob/master/android/src/main/kotlin/io/github/ponnamkarthik/toast/fluttertoast/MethodCallHandlerImpl.kt
/*
MIT License

Copyright (c) 2020 Karthik Ponnam

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
package com.wukgdu365.bdwm_viewer

import android.app.Activity
import android.content.Context
import android.os.Build
import android.widget.Toast
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlin.Exception

internal class ObvMethodCallHandlerImpl(private var context: Context) : MethodCallHandler {

    private var mToast: Toast? = null

    private fun cancelToast() {
        if (mToast != null) {
            mToast?.cancel()
            mToast = null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "showToast" -> {
                // cancelToast();
                val mMessage = call.argument<Any>("msg").toString()

                mToast = Toast.makeText(context, mMessage, Toast.LENGTH_SHORT)

                if (context is Activity) {
                    (context as Activity).runOnUiThread { mToast?.show() }
                } else {
                    mToast?.show()
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    mToast?.addCallback(object : Toast.Callback() {
                        override fun onToastHidden() {
                            super.onToastHidden()
                            mToast = null
                        }
                    })
                }
                result.success(true)
            }
            "cancelToast" -> {
                cancelToast();
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
