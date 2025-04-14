import numpy as np
import wave
import struct

def generate_beep(freq=800, duration=0.2, volume=0.5, sample_rate=44100):
    # 사인파 생성
    frames = int(duration * sample_rate)
    arr = np.sin(2 * np.pi * freq * np.linspace(0, duration, frames))
    arr = arr * volume * 32767
    arr = arr.astype(np.int16)
    return arr

def write_wave(path, audio, sample_rate=44100):
    # 16비트 PCM WAV 파일로 저장
    with wave.open(path, 'w') as fp:
        fp.setnchannels(1)
        fp.setsampwidth(2)
        fp.setframerate(sample_rate)
        fp.writeframes(audio.tobytes())

# Windows 스타일 비프음 생성
beep1 = generate_beep(freq=800, duration=0.15)
beep2 = generate_beep(freq=600, duration=0.15)
silence = np.zeros(int(0.1 * 44100), dtype=np.int16)
combined = np.concatenate([beep1, silence, beep2])

write_wave('alarm_sound.wav', combined)
print('Windows 스타일 비프음이 생성되었습니다!')