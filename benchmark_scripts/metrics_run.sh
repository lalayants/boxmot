#!/bin/bash
set -e

echo "Starting benchmark..."
cd "$(dirname "$0")/.."

trackers=("strongsort" "ocsort" "bytetrack" "botsort" "deepocsort" "imprassoc")
yolo_weights=("yolov8n_runs_512p_450epoches.pt" "yolov8s_runs_512p_450epoches.pt" "yolov8m_runs_512p_450epoches.pt" "yolov8l_runs_512p_450epoches.pt" "yolov8x_runs_512p_450epoches.pt"
            "yolov8n_runs_320p_600epoches.pt" "yolov8s_runs_320p_600epoches.pt" "yolov8m_runs_320p_600epoches.pt" "yolov8l_runs_320p_600epoches.pt" "yolov8x_runs_320p_600epoches.pt"
            )
reid_models=("osnet_x1_0_market1501.pt" "osnet_x0_75_market1501.pt" "osnet_x0_5_market1501.pt" "osnet_x0_25_market1501.pt" "clip_market1501.pt" "lmbn_n_market.pt" "osnet_ibn_x1_0_msmt17.pt" "osnet_ain_x1_0_msmt17.pt")



# Set the dataset directory.
FPS=15
DATASET_DIR="tracking/val_utils/data/MOT17${FPS}FPS/train"

# Count total frames in the dataset directory.
NUM_FRAMES=$(find "$DATASET_DIR" -type f | wc -l)
echo "Dataset has $NUM_FRAMES frames."

# Create a results directory inside benchmark_scripts with a timestamp.
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
RESULTS_DIR="benchmark_scripts/results_${FPS}fps_$TIMESTAMP"
mkdir -p "$RESULTS_DIR"

# Create (or clear) the combined results CSV file.
RESULTS_FILE="$RESULTS_DIR/results.csv"
echo "Tracker,REID Model,YOLO Model,ImgSz,Status,HOTA,MOTA,IDF1,FPS,Elapsed_time" > "$RESULTS_FILE"

# Loop through each combination.
for tracker in "${trackers[@]}"; do
    for reid_model in "${reid_models[@]}"; do
        for yolo_weight in "${yolo_weights[@]}"; do
            # Extract the image size from the YOLO weight name.
            # The expected pattern is *_runs_<imgsz>p_*, e.g., yolov8n_runs_512p_450epoches.pt
            imgsz=$(echo "$yolo_weight" | sed -E 's/.*_runs_([0-9]+)p_.*/\1/')
            
            echo "Running benchmark for tracker: $tracker, REID: $reid_model, YOLO: $yolo_weight (imgsz: $imgsz)"
            
            # Record the start time.
            start=$(date +%s.%N)
            
            # Run the evaluation command.
            if poetry run python3 tracking/val.py --ci --imgsz "$imgsz" --classes 0 --yolo-model "$yolo_weight" --reid-model "$reid_model" --tracking-method "$tracker" --verbose --source "$DATASET_DIR"; then
                status="OK"
            else
                status="ERROR"
            fi
            
            # Record the end time and calculate elapsed time.
            end=$(date +%s.%N)
            elapsed=$(echo "$end - $start" | bc)
            
            # Calculate FPS as (number of frames) / (elapsed time in seconds).
            if (( $(echo "$elapsed > 0" | bc -l) )); then
                fps=$(echo "scale=2; $NUM_FRAMES / $elapsed" | bc)
            else
                fps="N/A"
            fi
            
            # Handle the output JSON.
            # (Assuming the evaluation produces an output file named "<tracker>_output.json")
            OUTPUT_ORIG="${tracker}_output.json"
            reid_base=$(basename "$reid_model" .pt)
            yolo_base=$(basename "$yolo_weight" .pt)
            OUTPUT_FILE="$RESULTS_DIR/${tracker}_${reid_base}_${yolo_base}_output.json"
            
            if [ -f "$OUTPUT_ORIG" ]; then
                mv "$OUTPUT_ORIG" "$OUTPUT_FILE"
                HOTA=$(jq -r '.HOTA' "$OUTPUT_FILE")
                MOTA=$(jq -r '.MOTA' "$OUTPUT_FILE")
                IDF1=$(jq -r '.IDF1' "$OUTPUT_FILE")
            else
                HOTA=""
                MOTA=""
                IDF1=""
            fi
            
            # Append this run’s result to the CSV file.
            echo "$tracker,$reid_model,$yolo_weight,$imgsz,$status,$HOTA,$MOTA,$IDF1,$fps,$elapsed" >> "$RESULTS_FILE"
        done
    done
done

# Optionally, sort the results by HOTA (5th column) in descending order.
sort -t, -k6 -nr "$RESULTS_FILE" > "$RESULTS_DIR/sorted_results.csv"

# If the 'column' command is available, create a human-readable table.
if command -v column >/dev/null 2>&1; then
    column -s, -t "$RESULTS_DIR/sorted_results.csv" > "$RESULTS_DIR/pretty_results.txt"
    echo "Benchmarking complete. Combined results:"
    cat "$RESULTS_DIR/pretty_results.txt"
else
    echo "Benchmarking complete. Results:"
    cat "$RESULTS_DIR/sorted_results.csv"
fi
