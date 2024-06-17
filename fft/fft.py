import json
import numpy as np
import scipy.fftpack
import scipy.io.wavfile as wav
from pydub import AudioSegment

def convert_mp3_to_wav(mp3_file_path, wav_file_path):
    audio = AudioSegment.from_mp3(mp3_file_path)
    audio.export(wav_file_path, format="wav")

def compute_fft(file_path, output_path):
    # Convert MP3 to WAV
    wav_file_path = "temp.wav"
    convert_mp3_to_wav(file_path, wav_file_path)
    
    # Read WAV file
    rate, data = wav.read(wav_file_path)
    
    # Ensure data is mono
    if len(data.shape) > 1:
        data = np.mean(data, axis=1)
    
    # Parameters
    chunk_size = 1024  # Slightly larger chunk size
    step_size = chunk_size // 2  # 50% overlap
    fft_data = []
    
    # Process audio in chunks
    for start in range(0, len(data) - chunk_size, step_size):
        chunk = data[start:start + chunk_size]
        fft_result = scipy.fftpack.fft(chunk)
        fft_magnitude = np.abs(fft_result[:chunk_size // 2])
        
        # Normalize FFT data
        max_value = np.max(fft_magnitude)
        if max_value > 0:
            normalized_fft = fft_magnitude / max_value
        else:
            normalized_fft = fft_magnitude
        
        # Downsample the FFT output less aggressively
        downsampled_fft = normalized_fft[::2]  # Keep every 2nd value
        
        # Quantize the FFT magnitudes
        quantized_fft = np.round(downsampled_fft * 100) / 100  # Round to 2 decimal places
        
        fft_data.append(quantized_fft.tolist())
    
    # Save FFT data to JSON file
    with open(output_path, 'w') as f:
        json.dump(fft_data, f)

if __name__ == "__main__":
    compute_fft('src/assets/game1.mp3', 'src/assets/fft_data_game1.json')
    compute_fft('src/assets/game2.mp3', 'src/assets/fft_data_game2.json')
    compute_fft('src/assets/game3.mp3', 'src/assets/fft_data_game3.json')
