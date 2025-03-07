export DISPLAY=:0
poetry run python tracking/track.py --imgsz 640 \
    --yolo-model yolov8x \
    --tracking-method bytetrack \
    --source generate_video/output_640_175.mp4\
    --classes 0 
    # --show --show-trajectories 