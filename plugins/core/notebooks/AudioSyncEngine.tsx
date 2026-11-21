import React, { useState, useRef, useEffect } from "react"
import { Mic, Square, Play, Pause } from "lucide-react"
import type { AudioRecording, AudioEvent } from "./types"

interface AudioSyncEngineProps {
  onRecordingStart?: () => void
  onRecordingStop?: (recording: AudioRecording) => void
  currentEvents: AudioEvent[]
  activeRecording: AudioRecording | null
  playbackTimeMs: number
  isPlaybackActive: boolean
  onSeekPlayback: (timeMs: number) => void
  onTogglePlayback: () => void
}

export const AudioSyncEngine: React.FC<AudioSyncEngineProps> = ({
  onRecordingStart,
  onRecordingStop,
  currentEvents,
  activeRecording,
  playbackTimeMs,
  isPlaybackActive,
  onSeekPlayback,
  onTogglePlayback,
}) => {
  const [isRecording, setIsRecording] = useState(false)
  const [recordingSeconds, setRecordingSeconds] = useState(0)
  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const audioChunksRef = useRef<Blob[]>([])
  const recordingTimerRef = useRef<number | null>(null)
  const startTimeRef = useRef<number>(0)

  // Clean up timer on unmount
  useEffect(() => {
    return () => {
      if (recordingTimerRef.current) clearInterval(recordingTimerRef.current)
    }
  }, [])

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      const recorder = new MediaRecorder(stream)
      mediaRecorderRef.current = recorder
      audioChunksRef.current = []

      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) {
          audioChunksRef.current.push(e.data)
        }
      }

      recorder.onstop = () => {
        const audioBlob = new Blob(audioChunksRef.current, { type: "audio/webm" })
        const audioUrl = URL.createObjectURL(audioBlob)
        const duration = Date.now() - startTimeRef.current

        const newRecording: AudioRecording = {
          id: `rec_${Date.now()}`,
          durationMs: duration,
          createdAt: Date.now(),
          audioDataUrl: audioUrl,
          events: [...currentEvents],
        }

        onRecordingStop?.(newRecording)
        // Stop stream tracks
        stream.getTracks().forEach((t) => t.stop())
      }

      startTimeRef.current = Date.now()
      recorder.start(250)
      setIsRecording(true)
      setRecordingSeconds(0)
      onRecordingStart?.()

      recordingTimerRef.current = window.setInterval(() => {
        setRecordingSeconds((prev) => prev + 1)
      }, 1000)
    } catch (err) {
      console.warn("Microphone access unavailable or denied:", err)
      // Fallback simulated recording for testing
      startTimeRef.current = Date.now()
      setIsRecording(true)
      setRecordingSeconds(0)
      onRecordingStart?.()
      recordingTimerRef.current = window.setInterval(() => {
        setRecordingSeconds((prev) => prev + 1)
      }, 1000)
    }
  }

  const stopRecording = () => {
    if (recordingTimerRef.current) {
      clearInterval(recordingTimerRef.current)
      recordingTimerRef.current = null
    }

    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== "inactive") {
      mediaRecorderRef.current.stop()
    } else {
      // Fallback simulated recording
      const duration = Date.now() - startTimeRef.current
      const newRecording: AudioRecording = {
        id: `rec_${Date.now()}`,
        durationMs: duration,
        createdAt: Date.now(),
        events: [...currentEvents],
      }
      onRecordingStop?.(newRecording)
    }

    setIsRecording(false)
  }

  const formatTime = (ms: number) => {
    const totalSecs = Math.floor(ms / 1000)
    const mins = Math.floor(totalSecs / 60)
    const secs = totalSecs % 60
    return `${mins}:${secs < 10 ? "0" : ""}${secs}`
  }

  return (
    <div className="flex items-center gap-2 bg-slate-100 dark:bg-slate-800/90 px-3 py-1 rounded-full border border-slate-300 dark:border-slate-700 shadow-sm text-xs">
      {/* Recording status or trigger */}
      {!isRecording ? (
        <button
          onClick={startRecording}
          className="flex items-center gap-1.5 text-rose-600 dark:text-rose-400 font-semibold hover:opacity-80 transition-opacity"
          title="Start Audio Recording (Timestamp-synced to handwriting)"
        >
          <Mic className="w-3.5 h-3.5" />
          <span>Record Audio</span>
        </button>
      ) : (
        <div className="flex items-center gap-2">
          <div className="w-2.5 h-2.5 rounded-full bg-rose-500 animate-pulse" />
          <span className="font-mono text-rose-600 dark:text-rose-400 font-bold">
            {formatTime(recordingSeconds * 1000)}
          </span>
          <button
            onClick={stopRecording}
            className="p-1 bg-rose-600 text-white rounded hover:bg-rose-700"
            title="Stop Recording"
          >
            <Square className="w-3 h-3 fill-current" />
          </button>
        </div>
      )}

      {/* Playback Controls (when an active recording exists) */}
      {activeRecording && !isRecording && (
        <div className="flex items-center gap-2 pl-2 border-l border-slate-300 dark:border-slate-700">
          <button
            onClick={onTogglePlayback}
            className="p-1 text-blue-600 dark:text-blue-400 hover:bg-slate-200 dark:hover:bg-slate-700 rounded-full"
            title={isPlaybackActive ? "Pause Audio & Ink Animation" : "Play Synced Audio & Animate Handwriting"}
          >
            {isPlaybackActive ? <Pause className="w-3.5 h-3.5 fill-current" /> : <Play className="w-3.5 h-3.5 fill-current" />}
          </button>

          {/* Timeline scrubber */}
          <input
            type="range"
            min={0}
            max={activeRecording.durationMs || 10000}
            value={playbackTimeMs}
            onChange={(e) => onSeekPlayback(Number(e.target.value))}
            className="w-24 h-1.5 bg-slate-300 dark:bg-slate-600 rounded-lg appearance-none cursor-pointer accent-blue-600"
            title="Seek Audio Timeline"
          />

          <span className="font-mono text-[10px] text-slate-500 min-w-[55px]">
            {formatTime(playbackTimeMs)} / {formatTime(activeRecording.durationMs)}
          </span>
        </div>
      )}
    </div>
  )
}
