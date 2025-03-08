export DISPLAY=:0
poetry run python tracking/track.py --imgsz 320 \
    --yolo-model ../tpu_weights/v8/320/yolov8n_full_integer_quant_edgetpu.tflite  \
    --device tpu:0 \
    --tracking-method strongsort \
    --reid-model osnet_x1_0_market1501.pt \
    --classes 0 \
    --source video.mp4 