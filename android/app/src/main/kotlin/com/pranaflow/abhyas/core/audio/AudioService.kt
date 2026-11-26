package com.pranaflow.abhyas.core.audio

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.ToneGenerator
import com.pranaflow.abhyas.engine.meditation.JapaStage
import com.pranaflow.abhyas.engine.player.PracticePhase

enum class BellType {
    START,
    END,
    TRANSITION,
}

enum class AudioServiceStatus {
    IDLE,
    PLAYING,
    PAUSED,
}

interface AudioPlaybackDriver {
    fun playBellAsset(assetPath: String, volume: Float)
    fun playVoiceAsset(assetPath: String, volume: Float)
    fun playTrackAsset(assetPath: String, volume: Float, looping: Boolean = false, onComplete: (() -> Unit)? = null)
    fun pauseTrack()
    fun resumeTrack()
    fun seekTrack(positionMillis: Int)
    fun setVolume(volume: Float)
    fun playSystemTick()
    fun stopAll()
    fun release()
}

class RecordingAudioPlaybackDriver : AudioPlaybackDriver {
    val playedBells = mutableListOf<String>()
    val playedVoices = mutableListOf<String>()
    val playedTracks = mutableListOf<String>()
    var tickCount: Int = 0
    var paused: Boolean = false
    var stoppedCount: Int = 0
    var lastSeekMillis: Int? = null
    var lastVolume: Float = 1.0f

    override fun playBellAsset(assetPath: String, volume: Float) {
        playedBells.add(assetPath)
        lastVolume = volume
    }

    override fun playVoiceAsset(assetPath: String, volume: Float) {
        playedVoices.add(assetPath)
        lastVolume = volume
    }

    override fun playTrackAsset(assetPath: String, volume: Float, looping: Boolean, onComplete: (() -> Unit)?) {
        playedTracks.add(assetPath)
        paused = false
        lastVolume = volume
    }

    override fun pauseTrack() {
        paused = true
    }

    override fun resumeTrack() {
        paused = false
    }

    override fun seekTrack(positionMillis: Int) {
        lastSeekMillis = positionMillis
    }

    override fun setVolume(volume: Float) {
        lastVolume = volume
    }

    override fun playSystemTick() {
        tickCount++
    }

    override fun stopAll() {
        stoppedCount++
        paused = false
    }

    override fun release() = stopAll()
}

/**
 * Android native triple-channel audio driver using [MediaPlayer] against APK assets + [AudioManager] focus handling.
 * Audio focus interruptions (e.g., phone calls) notify [onAudioFocusInterrupted] so practice pauses safely to natural breath (NFR-02).
 */
class AndroidAudioPlaybackDriver(
    context: Context,
    private val onAudioFocusInterrupted: (() -> Unit)? = null,
) : AudioPlaybackDriver {
    private val appContext = context.applicationContext
    private val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager

    private var bellPlayer: MediaPlayer? = null
    private var voicePlayer: MediaPlayer? = null
    private var trackPlayer: MediaPlayer? = null
    private var toneGenerator: ToneGenerator? = null
    private var focusRequest: AudioFocusRequest? = null

    private val audioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
        .build()

    private val focusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                pauseTrack()
                onAudioFocusInterrupted?.invoke()
            }
        }
    }

    private fun requestFocus() {
        val mgr = audioManager ?: return
        val req = focusRequest ?: AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(audioAttributes)
            .setOnAudioFocusChangeListener(focusChangeListener)
            .build()
            .also { focusRequest = it }
        mgr.requestAudioFocus(req)
    }

    private fun abandonFocus() {
        val mgr = audioManager ?: return
        focusRequest?.let { mgr.abandonAudioFocusRequest(it) }
    }

    private fun cleanAssetPath(assetPath: String): String =
        assetPath.removePrefix("assets/").removePrefix("/")

    private fun playIntoPlayer(
        existing: MediaPlayer?,
        assign: (MediaPlayer?) -> Unit,
        assetPath: String,
        volume: Float,
        looping: Boolean = false,
        onComplete: (() -> Unit)? = null,
    ) {
        val clean = cleanAssetPath(assetPath)
        val candidates = buildList {
            add(clean)
            if (clean.endsWith(".mp3")) add(clean.removeSuffix(".mp3") + ".wav")
            else if (clean.endsWith(".wav")) add(clean.removeSuffix(".wav") + ".mp3")
        }

        runCatching {
            existing?.stop()
            existing?.release()
        }

        for (candidate in candidates) {
            val loaded = runCatching {
                appContext.assets.openFd(candidate).use { afd ->
                    MediaPlayer().apply {
                        setAudioAttributes(audioAttributes)
                        setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                        setVolume(volume, volume)
                        isLooping = looping
                        setOnCompletionListener {
                            if (!looping) {
                                onComplete?.invoke()
                            }
                        }
                        prepare()
                        start()
                    }
                }
            }.getOrNull()

            if (loaded != null) {
                assign(loaded)
                return
            }
        }
    }

    override fun playBellAsset(assetPath: String, volume: Float) {
        requestFocus()
        playIntoPlayer(bellPlayer, { bellPlayer = it }, assetPath, volume, looping = false)
    }

    override fun playVoiceAsset(assetPath: String, volume: Float) {
        requestFocus()
        playIntoPlayer(voicePlayer, { voicePlayer = it }, assetPath, volume, looping = false)
    }

    override fun playTrackAsset(assetPath: String, volume: Float, looping: Boolean, onComplete: (() -> Unit)?) {
        requestFocus()
        playIntoPlayer(trackPlayer, { trackPlayer = it }, assetPath, volume, looping = looping, onComplete = onComplete)
    }

    override fun pauseTrack() {
        runCatching {
            if (trackPlayer?.isPlaying == true) {
                trackPlayer?.pause()
            }
        }
    }

    override fun resumeTrack() {
        runCatching {
            trackPlayer?.start()
        }
    }

    override fun seekTrack(positionMillis: Int) {
        runCatching {
            trackPlayer?.seekTo(positionMillis.coerceAtLeast(0))
        }
    }

    override fun setVolume(volume: Float) {
        val clamped = volume.coerceIn(0f, 1f)
        runCatching { bellPlayer?.setVolume(clamped, clamped) }
        runCatching { voicePlayer?.setVolume(clamped, clamped) }
        runCatching { trackPlayer?.setVolume(clamped, clamped) }
    }

    override fun playSystemTick() {
        runCatching {
            if (toneGenerator == null) {
                toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 25)
            }
            toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 25)
        }
    }

    override fun stopAll() {
        listOf(bellPlayer, voicePlayer, trackPlayer).forEach { player ->
            runCatching {
                player?.stop()
                player?.release()
            }
        }
        bellPlayer = null
        voicePlayer = null
        trackPlayer = null
        abandonFocus()
    }

    override fun release() {
        stopAll()
        runCatching { toneGenerator?.release() }
        toneGenerator = null
    }
}

/**
 * Unified AudioService for bells, phase cues, Naam Japa transitions, ticks, and long-form Yoga Nidra / Tanpura tracks.
 */
class AudioService(
    private val driver: AudioPlaybackDriver,
) {
    var status: AudioServiceStatus = AudioServiceStatus.IDLE
        private set
    var volume: Float = 1.0f
        private set
    var currentTrackPath: String? = null
        private set

    val isPlaying: Boolean
        get() = status == AudioServiceStatus.PLAYING

    fun playBell(type: BellType) {
        val asset = when (type) {
            BellType.START -> "audio/singingBowl_practice_start_gong.wav"
            BellType.END -> "audio/singingBowl_session_complete_3bowls.wav"
            BellType.TRANSITION -> "audio/singingBowl_grounding_bell.wav"
        }
        driver.playBellAsset(asset, volume)
    }

    fun playVoiceCue(assetPath: String) {
        driver.playVoiceAsset(assetPath, volume)
    }

    fun playNaamJapaPhase(stage: JapaStage) {
        when (stage) {
            JapaStage.VAIKHARI -> {
                driver.playBellAsset("audio/singingBowl_practice_start_gong.wav", volume)
                playVoiceCue("audio/voice/voice_japa_vaikhari.wav")
            }
            JapaStage.UPAMSHU -> {
                driver.playBellAsset("audio/singingBowl_kumbhaka_hold.wav", volume)
                playVoiceCue("audio/voice/voice_japa_upamshu.wav")
            }
            JapaStage.MANASIKA -> {
                driver.playBellAsset("audio/singingBowl_puraka_inhale.wav", volume)
                playVoiceCue("audio/voice/voice_japa_manasika.wav")
            }
            JapaStage.LAYA -> {
                driver.playBellAsset("audio/singingBowl_shanti_chime.wav", volume)
                playVoiceCue("audio/voice/voice_japa_laya.wav")
            }
            JapaStage.COMPLETE -> playBell(BellType.END)
        }
    }

    fun playPhaseCue(phase: PracticePhase) {
        val asset = when (phase) {
            PracticePhase.PURAKA -> "audio/singingBowl_puraka_inhale.wav"
            PracticePhase.ANTAR_KUMBHAKA -> "audio/singingBowl_kumbhaka_hold.wav"
            PracticePhase.RECHAKA -> "audio/singingBowl_rechaka_exhale.wav"
            PracticePhase.BAHYA_KUMBHAKA -> "audio/singingBowl_bahya_pause.wav"
            PracticePhase.NATURAL_BREATH -> "audio/singingBowl_grounding_bell.wav"
        }
        driver.playBellAsset(asset, volume)
    }

    fun playTick() {
        driver.playSystemTick()
    }

    fun playTrack(assetPath: String, looping: Boolean = false, onComplete: (() -> Unit)? = null) {
        currentTrackPath = assetPath
        status = AudioServiceStatus.PLAYING
        driver.playTrackAsset(assetPath, volume, looping = looping) {
            status = AudioServiceStatus.IDLE
            onComplete?.invoke()
        }
    }

    fun pauseTrack() {
        if (status != AudioServiceStatus.PLAYING) return
        driver.pauseTrack()
        status = AudioServiceStatus.PAUSED
    }

    fun resumeTrack() {
        if (status != AudioServiceStatus.PAUSED) return
        driver.resumeTrack()
        status = AudioServiceStatus.PLAYING
    }

    fun seek(positionMillis: Int) {
        driver.seekTrack(positionMillis)
    }

    fun stopAll() {
        status = AudioServiceStatus.IDLE
        currentTrackPath = null
        driver.stopAll()
    }

    fun setVolume(newVolume: Float) {
        volume = newVolume.coerceIn(0f, 1f)
        driver.setVolume(volume)
    }
}
