// https://github.com/ponnamkarthik/FlutterToast/blob/master/android/src/main/kotlin/io/github/ponnamkarthik/toast/fluttertoast/FlutterToastPlugin.kt
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

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
// import io.flutter.plugin.common.PluginRegistry.Registrar

public class ObvFlutterPlugin: FlutterPlugin {

  private var channel: MethodChannel? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    setupChannel(binding.binaryMessenger, binding.applicationContext)
  }

  override fun onDetachedFromEngine(p0: FlutterPlugin.FlutterPluginBinding) {
    teardownChannel();
  }

  private fun setupChannel(messenger: BinaryMessenger, context: Context) {
    channel = MethodChannel(messenger, "wukgdu/bdwm_viewer")
    val handler = ObvMethodCallHandlerImpl(context)
    channel?.setMethodCallHandler(handler)
  }

  private fun teardownChannel() {
    channel?.setMethodCallHandler(null)
    channel = null
  }
}
