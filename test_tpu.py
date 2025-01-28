from ultralytics import YOLO
import numpy as np
from PIL import Image
import time

model = YOLO(
    f"myweights/yolov8n_640_full_integer_quant_edgetpu.tflite",
    task="detect",
)

img_file = np.asarray(Image.open('bus.jpg').resize((640, 640)))
print(img_file.shape)
res = model.predict(img_file, imgsz=640, device="tpu:1", verbose=False)
frames = 10

print(f"Eval {frames} frames on YOLO EdgeTpu")
start_time = time.time()
i = 0
while i < frames:
    res = model.predict(img_file, imgsz=640, verbose=False)
    i += 1
print(f"Average FPS: {frames / (time.time() - start_time)}")
res = model.predict(img_file, verbose=True)
