export DISPLAY=:0
poetry run python tracking/track.py \
    --yolo-model yolov8n \
    --tracking-method imprassoc\
    --show --show-trajectories \
    --source 0 \
    # --source 'https://ultralytics.com/images/bus640.jpg'\

    # --show --show-trajectories