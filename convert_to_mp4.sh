#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <inputfile.mov>"
  exit 1
fi

INPUT_FILE="$1"
FRAMERATE=30

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File '$INPUT_FILE' not found!"
  exit 2
fi

if [[ "$INPUT_FILE" != *.mov ]]; then
  echo "Error: Input file must have a .mov extension"
  exit 3
fi

OUTPUT_FILE="/home/roman/Videos/DaVinci/${INPUT_FILE%.mov}.mp4"

# Get total duration in seconds
DURATION_SEC=$(ffprobe -v error -select_streams v:0 \
  -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
DURATION_SEC=${DURATION_SEC%.*}

echo "Total Duration: ${DURATION_SEC}s"
echo "Starting conversion..."
echo "Have a look at: https://youtu.be/WLcW4UWPC5Y"

PIPE=$(mktemp -u)
mkfifo "$PIPE"

# ffmpeg in background, writing progress to pipe
{
  ffmpeg -i "$INPUT_FILE" -c:v libx264 -preset ultrafast -crf 0 "$OUTPUT_FILE" -progress "$PIPE" -nostats -y
} &

# Read progress
while read -r line; do
  if [[ "$line" == out_time_ms=* ]]; then
    ms=${line#*=}
    if [ "$ms" != "N/A" ]; then
	    seconds=$((ms / 1000000))
	    percent=$(awk "BEGIN {printf \"%.2f\", ($seconds/$DURATION_SEC)*100}")
	    eta=$((DURATION_SEC - seconds))
	    printf "\rProgress: %5.2f%% | Elapsed: %ds | ETA: %ds" "$percent" "$seconds" "$eta"
	fi
  fi
done < "$PIPE"

wait
rm -f "$PIPE"
echo -e "\nDone."
