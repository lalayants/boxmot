from ultralytics import YOLO
import numpy as np
from PIL import Image
import time
import os
import cv2

model = YOLO(
    f"yolov8n_256_sim_best_full_integer_quant_edgetpu.tflite",
    task="detect",
)

img_file = np.asarray(Image.open('bus.jpg').resize((256, 256)))
print(img_file.shape)
res = model.predict(img_file, imgsz=256, verbose=False)
frames = 10

print(f"Eval {frames} frames on YOLO EdgeTpu")
start_time = time.time()
i = 0
while i < frames:
    res = model.predict(img_file, imgsz=256, verbose=False)
    i += 1
print(f"Average FPS: {frames / (time.time() - start_time)}")
res = model.predict(img_file, verbose=True)
