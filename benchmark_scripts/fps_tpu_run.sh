#!/bin/bash
set -e
cd "$(dirname "$0")/.."
export DISPLAY=:0

# Define arrays (adjust as needed)
yolo_weights=("../tpu_weights/v8/512/yolov8n_full_integer_quant_edgetpu.tflite" "../tpu_weights/v8/512/yolov8s_full_integer_quant_edgetpu.tflite")
reid_models=("osnet_x1_0_market1501.pt" "osnet_x0_75_market1501.pt" "osnet_x0_5_market1501.pt" "osnet_x0_25_market1501.pt" "lmbn_n_market.pt" "clip_market1501.pt" "osnet_ibn_x1_0_msmt17.pt" "osnet_ain_x1_0_msmt17.pt")
trackers=("strongsort" "ocsort" "bytetrack" "botsort" "deepocsort" "imprassoc")
# yolo_weights=("yolov8n.pt")

# Output CSV file; header includes one row per object count (group)
output_file="benchmark_scripts/fps_tpu_512_results.csv"
echo "tracker,yolo_model,reid_model,object_count,avg_fps,avg_time_per_frame,min_time_per_frame,max_time_per_frame" > "$output_file"
# Initialize associative arrays to accumulate per object count group.
declare -A sum_fps sum_time count_group min_time max_time

# Iterate over all combinations
for tracker in "${trackers[@]}"; do
  for yolo_model in "${yolo_weights[@]}"; do
    for reid_model in "${reid_models[@]}"; do
      echo "Running: Tracker=$tracker, YOLO=$yolo_model, ReID=$reid_model"
      date +%Y%m%d---%H:%M:%S
      
      # Run the tracking script and capture output (both stdout and stderr)
      output=$(poetry run python tracking/track.py --imgsz 512 \
                --yolo-model "$yolo_model" \
                --tracking-method "$tracker" \
                --reid-model "$reid_model" \
                --source generate_video/output_640_175.mp4 2>&1)
      
      # Extract lines starting with "video 1/1" (object info) and "FPS" (timing info)
      video_lines=$(echo "$output" | grep "^video 1/1")
      fps_lines=$(echo "$output" | grep "^FPS")
      
      # Reset the arrays for this run
      unset sum_fps sum_time count_group min_time max_time
      
      # Process the pairs in parallel: read from video_lines and fps_lines simultaneously.
      exec 3<<<"$fps_lines"
      while IFS= read -r video_line; do
          IFS= read -r fps_line <&3 || break
          
          # Extract object count from video_line.
          # Example: "... 321x321 1 person, 25.7ms" or "... 321x321 2 persons, 22.8ms"
          if [[ $video_line =~ ([0-9]+)[[:space:]]+person ]]; then
              oc="${BASH_REMATCH[1]}"
          else
              oc=0
          fi
          
          # Extract FPS and time per frame from fps_line.
          # Example fps_line: "FPS 26.438299347599987 -- 37.8 ms"
          fps_val=$(echo "$fps_line" | awk '{print $2}')
          time_val=$(echo "$fps_line" | awk '{print $4}')
          
          # Accumulate values for group "oc"
          sum_fps[$oc]=$(echo "${sum_fps[$oc]:-0} + $fps_val" | bc -l)
          sum_time[$oc]=$(echo "${sum_time[$oc]:-0} + $time_val" | bc -l)
          count_group[$oc]=$((${count_group[$oc]:-0} + 1))
          
          # Update minimum time per frame for this group
          if [[ -z "${min_time[$oc]}" ]] || (( $(echo "$time_val < ${min_time[$oc]}" | bc -l) )); then
              min_time[$oc]=$time_val
          fi
          # Update maximum time per frame for this group
          if [[ -z "${max_time[$oc]}" ]] || (( $(echo "$time_val > ${max_time[$oc]}" | bc -l) )); then
              max_time[$oc]=$time_val
          fi
      done < <(echo "$video_lines")
      exec 3<&-
      
      # For each object count group, compute averages and write a CSV line.
      for oc in "${!count_group[@]}"; do
          avg_fps=$(echo "scale=6; ${sum_fps[$oc]} / ${count_group[$oc]}" | bc -l)
          avg_time=$(echo "scale=6; ${sum_time[$oc]} / ${count_group[$oc]}" | bc -l)
          echo "$tracker,$yolo_model,$reid_model,$oc,$avg_fps,$avg_time,${min_time[$oc]},${max_time[$oc]}" >> "$output_file"
      done
      
    done
  done
done

echo "All tracking experiments completed. Results saved to $output_file."
