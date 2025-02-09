#!/bin/bash
set -e

echo "Starting benchmark..."
cd "$(dirname "$0")/.."

# Define arrays for tracker methods, REID models, and YOLO weights.
trackers=("ocsort" "bytetrack" "botsort" "hybridsort" "deepocsort" "imprassoc" "strongsort")
reid_models=("osnet_x1_0_dukemtmcreid.pt" "model2.pt" "model3.pt")  # Update these names as needed.
yolo_weights=("yolov8x.pt" "yolov8s.pt" "yolov8m.pt")                # Update these names as needed.

# Set the dataset directory.
DATASET_DIR="tracking/val_utils/data/MOT17-50/train"

# Count total frames in the dataset directory.
NUM_FRAMES=$(find "$DATASET_DIR" -type f | wc -l)
echo "Dataset has $NUM_FRAMES frames."

# Create a results directory inside benchmark_scripts with a timestamp.
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
RESULTS_DIR="benchmark_scripts/results_$TIMESTAMP"
mkdir -p "$RESULTS_DIR"

# Create (or clear) the combined results CSV file.
RESULTS_FILE="$RESULTS_DIR/results.csv"
echo "Tracker,REID Model,YOLO Model,Status,HOTA,MOTA,IDF1,FPS,Elapsed_time" > "$RESULTS_FILE"

# Loop through each combination.
for tracker in "${trackers[@]}"; do
    for reid_model in "${reid_models[@]}"; do
        for yolo_weight in "${yolo_weights[@]}"; do
            echo "Running benchmark for tracker: $tracker, REID: $reid_model, YOLO: $yolo_weight"
            
            # Record the start time.
            start=$(date +%s.%N)
            
            # Run the evaluation command.
            # (Assuming the evaluation script is at tracking/val.py in the repository root.)
            if poetry run python3 tracking/val.py --imgsz 320 --classes 0 --yolo-model "$yolo_weight" --reid-model "$reid_model" --tracking-method "$tracker" --verbose --source "$DATASET_DIR"; then
                status="✅"
            else
                status="❌"
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
            echo "$tracker,$reid_model,$yolo_weight,$status,$HOTA,$MOTA,$IDF1,$fps,$elapsed" >> "$RESULTS_FILE"
        done
    done
done

# Optionally, sort the results by HOTA (5th column) in descending order.
sort -t, -k5 -nr "$RESULTS_FILE" > "$RESULTS_DIR/sorted_results.csv"

# If the 'column' command is available, create a human-readable table.
if command -v column >/dev/null 2>&1; then
    column -s, -t "$RESULTS_DIR/sorted_results.csv" > "$RESULTS_DIR/pretty_results.txt"
    echo "Benchmarking complete. Combined results:"
    cat "$RESULTS_DIR/pretty_results.txt"
else
    echo "Benchmarking complete. Results:"
    cat "$RESULTS_DIR/sorted_results.csv"
fi
