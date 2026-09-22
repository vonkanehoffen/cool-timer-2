extends AudioStreamPlayer

const CHIME_FREQUENCY := 880.0
const CHIME_DURATION := 0.35


func _ready() -> void:
	stream = _build_chime_stream()


func play_chime() -> void:
	if stream == null:
		return
	stop()
	play()


func _build_chime_stream() -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * CHIME_DURATION)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var envelope := 1.0 - (t / CHIME_DURATION)
		envelope = envelope * envelope
		var sample := sin(TAU * CHIME_FREQUENCY * t) * envelope
		var value := int(clampf((sample * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		data[i] = value
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav
