#!/bin/bash
set -e

# Change to the repository root (one directory up from benchmark_scripts)
cd "$(dirname "$0")/.."

echo "Preparing environment..."

# Install required system dependencies (jq and curl)
echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y jq curl

# Adjust pyproject.toml for OS-specific dependency replacement
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS. Adjusting pyproject.toml..."
    sed -i '' 's/source="torch_cuda121"/source="torchcpu"/g' pyproject.toml
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected Linux. Adjusting pyproject.toml..."
    sed -i 's/source="torch_cuda121"/source="torchcpu"/g' pyproject.toml
fi

# Install Python dependencies using Poetry
echo "Installing Python dependencies..."
python -m pip install --upgrade pip setuptools wheel poetry
poetry config virtualenvs.create false
poetry lock
poetry install --with yolo

# Clone the evaluation tools repository if not already present
if [ ! -d "tracking/val_utils" ]; then
    echo "Cloning TrackEval repository..."
    git clone https://github.com/JonathonLuiten/TrackEval.git tracking/val_utils
else
    echo "TrackEval repository already exists. Skipping clone."
fi

# Ensure the data directory exists
mkdir -p tracking/val_utils/data

# Download evaluation datasets if not already downloaded
if [ ! -f "tracking/val_utils/MOT17-50.zip" ]; then
    echo "Downloading MOT17-50 dataset..."
    wget https://github.com/mikel-brostrom/boxmot/releases/download/v10.0.83/MOT17-50.zip -O tracking/val_utils/MOT17-50.zip
    unzip tracking/val_utils/MOT17-50.zip -d tracking/val_utils/data/
else
    echo "MOT17-50 dataset already downloaded."
fi

if [ ! -f "runs.zip" ]; then
    echo "Downloading runs.zip..."
    wget https://github.com/mikel-brostrom/boxmot/releases/download/v10.0.83/runs.zip -O runs.zip
    unzip runs.zip -d .
else
    echo "runs.zip already downloaded."
fi

echo "Environment preparation complete."
