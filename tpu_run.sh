export DISPLAY=:0
poetry run python tracking/track.py --imgsz 640 \
    --yolo-model myweights/yolov8n_640_full_integer_quant_edgetpu.tflite --device tpu:0 \
    --tracking-method imprassoc\
    --show --show-trajectories \
    --source 0 \
    # --source 'https://ultralytics.com/images/bus640.jpg'\

    # --show --show-trajectories