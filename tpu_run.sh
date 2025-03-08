export DISPLAY=:0
poetry run python tracking/track.py --imgsz 480 \
    --yolo-model myweights/yolov8n_480_full_integer_quant_edgetpu.tflite --device tpu:0 \
    --tracking-method bytetrack \
    --classes 0 \
    --source video.mp4 