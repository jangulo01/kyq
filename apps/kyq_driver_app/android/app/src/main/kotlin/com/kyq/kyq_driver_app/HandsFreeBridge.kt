package com.kyq.kyq_driver_app

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.hypot

/**
 * Capa nativa delgada del walkie-talkie manos libres (RN-KYQ-012, specs/005-ptt-extras).
 *
 * - Botón multimedia (auricular, manos libres, volante) con la MediaSession del sistema, activa
 *   solo mientras Dart lo pide (canal de voz abierto).
 * - Burbuja flotante sobre otras apps (Waze, Google Maps) con una vista nativa en el
 *   WindowManager, sin un segundo motor Flutter.
 *
 * No decide nada: envía "button_down", "button_up", "bubble_down" y "bubble_up" a Dart, donde
 * HandsFreePtt aplica el turno.
 */
class HandsFreeBridge(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val methods = MethodChannel(messenger, "kyq/hands_free")
    private val events = EventChannel(messenger, "kyq/hands_free/events")
    private val main = Handler(Looper.getMainLooper())
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val density = context.resources.displayMetrics.density
    private var sink: EventChannel.EventSink? = null
    private var session: MediaSession? = null
    private var bubble: ImageView? = null

    init {
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setMediaButtonActive" -> {
                setMediaButtonActive(call.argument<Boolean>("active") == true)
                result.success(null)
            }
            "showBubble" -> result.success(showBubble(call.argument<String>("look") ?: "idle"))
            "hideBubble" -> {
                hideBubble()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    private fun send(signal: String) {
        main.post { sink?.success(signal) }
    }

    // Botón multimedia

    private fun setMediaButtonActive(active: Boolean) {
        if (!active) {
            session?.isActive = false
            session?.release()
            session = null
            return
        }
        val s = session ?: MediaSession(context, "KyqWalkieTalkie").also { session = it }
        s.setCallback(object : MediaSession.Callback() {
            override fun onMediaButtonEvent(mediaButtonIntent: Intent): Boolean {
                val key = keyEvent(mediaButtonIntent) ?: return super.onMediaButtonEvent(mediaButtonIntent)
                if (key.keyCode !in PTT_KEYS) return super.onMediaButtonEvent(mediaButtonIntent)
                when (key.action) {
                    KeyEvent.ACTION_DOWN -> if (key.repeatCount == 0) send("button_down")
                    KeyEvent.ACTION_UP -> send("button_up")
                }
                return true
            }
        })
        // Android entrega los botones a la sesión que reproduce: se declara "reproduciendo".
        s.setPlaybackState(
            PlaybackState.Builder()
                .setActions(PlaybackState.ACTION_PLAY_PAUSE or PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE)
                .setState(PlaybackState.STATE_PLAYING, 0, 1f)
                .build(),
        )
        s.isActive = true
    }

    private fun keyEvent(intent: Intent): KeyEvent? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT, KeyEvent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT)
        }

    // Burbuja

    /** Muestra o actualiza la burbuja; false si falta el permiso de superposición. */
    private fun showBubble(look: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) return false
        val view = bubble ?: createBubble() ?: return false
        (view.background as GradientDrawable).setColor(colorFor(look))
        view.alpha = if (look == "connecting") 0.6f else 1f
        return true
    }

    private fun hideBubble() {
        bubble?.let { runCatching { windowManager.removeView(it) } }
        bubble = null
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun createBubble(): ImageView? {
        val size = (64 * density).toInt()
        val pad = (16 * density).toInt()
        val params = WindowManager.LayoutParams(
            size,
            size,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = (8 * density).toInt()
            y = (context.resources.displayMetrics.heightPixels * 0.35).toInt()
        }
        val view = ImageView(context).apply {
            setImageResource(android.R.drawable.ic_btn_speak_now)
            setPadding(pad, pad, pad, pad)
            background = GradientDrawable().apply { shape = GradientDrawable.OVAL }
            elevation = 8 * density
            contentDescription = "Kyq: mantén pulsado para hablar"
        }
        val slop = 12 * density
        var startX = 0
        var startY = 0
        var downX = 0f
        var downY = 0f
        var dragging = false
        view.setOnTouchListener { v, e ->
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startX = params.x
                    startY = params.y
                    downX = e.rawX
                    downY = e.rawY
                    dragging = false
                    send("bubble_down")
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = e.rawX - downX
                    val dy = e.rawY - downY
                    if (!dragging && hypot(dx, dy) > slop) {
                        // Arrastrar mueve la burbuja y suelta el turno.
                        dragging = true
                        send("bubble_up")
                    }
                    if (dragging) {
                        params.x = startX + dx.toInt()
                        params.y = startY + dy.toInt()
                        runCatching { windowManager.updateViewLayout(v, params) }
                    }
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> if (!dragging) send("bubble_up")
            }
            true
        }
        return runCatching { windowManager.addView(view, params) }.map {
            bubble = view
            view
        }.getOrNull()
    }

    private fun colorFor(look: String): Int = when (look) {
        "talking" -> 0xFFE53935.toInt()
        "remoteTalking" -> 0xFF2E7D32.toInt()
        "busy" -> 0xFFEF6C00.toInt()
        "connecting" -> 0xFF757575.toInt()
        else -> 0xFF1E88E5.toInt()
    }

    /** Se llama al soltar el motor Flutter: no deja la sesión ni la burbuja colgadas. */
    fun dispose() {
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        sink = null
        setMediaButtonActive(false)
        hideBubble()
    }

    private companion object {
        val PTT_KEYS = setOf(
            KeyEvent.KEYCODE_HEADSETHOOK,
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
            KeyEvent.KEYCODE_MEDIA_PLAY,
            KeyEvent.KEYCODE_MEDIA_PAUSE,
        )
    }
}
