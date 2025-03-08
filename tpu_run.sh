export DISPLAY=:0
poetry run python tracking/track.py --imgsz 320 \
    --yolo-model ../tpu_weights/v8/320/yolov8n_full_integer_quant_edgetpu.tflite  \
    --device tpu:0 \
    --tracking-method bytetrack \
    --classes 0 \
    --source video.mp4 