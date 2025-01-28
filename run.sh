export DISPLAY=:0
poetry run python tracking/track.py --imgsz 480 \
    --yolo-model yolov8n \
    --tracking-method imprassoc\
    --show --show-trajectories \
    --source video.mp4 \
    # --source 'https://ultralytics.com/images/bus640.jpg'\

    # --show --show-trajectories