#!/bin/bash -ex

# app=$1
# name=$2

app=adapt2
name=stream
# name=stream_test

# time="$(date +%Y%m%d-%H%M%S)"

source "$(dirname "$0")"/ffmpeg_config.sh

# input="-i srt://:19352?mode=listener"
# input="-i rist://@[::]:19352?cname=live&session-timeout=5000&keepalive-interval=2000&overrun_nonfatal=0&fifo_size=4096"
input="-overrun_nonfatal 1 -fifo_size 262144 -i rist://@[::]:19352?cname=live&session-timeout=5000&keepalive-interval=2000"
# input="-i rist://@[::]:19352?cname=live&session-timeout=5000&keepalive-interval=2000&overrun_nonfatal=1&fifo_size=16384"
# input="-f flv -listen 1 -analyzeduration 10000000 -probesize 50000000 -i rtmp://0.0.0.0:19352/$app/$name"
# input="-re -i src_20250413-143826.ts"

# w     h       b:v     b:a     b       bw/1000
# 3840  2160    32768   256     33024   33817
# 1920  1080    8192    196     8388    8589
# 1280  720     3641    128     3769    3859
# 854   480     1618    96      1714    1755

qsv_h264_params="-low_power 1 -tune zerolatency -preset medium"
qsv_hevc_params="-low_power 1 -tier main -preset medium -tune zerolatency -scenario livestreaming"


rm -f "${dst}-"*

ffmpeg="$(dirname "$0")/ffmpeg-master-latest-linux64-gpl/bin/ffmpeg"

$ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv $input \
    \
    -c:a:0 copy \
    -c:v:0 copy -b:v:0 40M \
    -f mpegts "${rec}_src.ts" -y \
    \
    \
    -c:a:0 copy \
    -c:v:0 copy -b:v:0 40M \
    \
    -filter:v:1 scale_qsv=w=1920:h=1080 \
    -c:v:1 hevc_qsv -b:v:1 10M -profile:v:1 main $qsv_hevc_params \
    \
    -map 0:v:0 -map 0:v:0 -map 0:a:0 \
    -f mpegts - | $ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -f mpegts -i - \
        \
        -c:a:0 copy \
        -c:v:0 copy \
        -map 0:v:1 -map 0:a:0 \
        -f segment -segment_format mpegts -strftime 1 -segment_time 24:00:00 "${rec}_%Y-%m-%dT%H-%M-%S%z.ts" \
        \
        \
        -c:a:0 copy \
        -c:a:1 aac -b:a:1 160k -ac 2 \
        \
        -c:v:0 copy \
        -c:v:1 copy \
        \
        -filter:v:2 scale_qsv=format=nv12:w=1280:h=720 \
        -c:v:2 h264_qsv -b:v:2 3500k -profile:v:2 baseline $qsv_h264_params \
        \
        -filter:v:3 scale_qsv=format=nv12:w=854:h=480 \
        -c:v:3 h264_qsv -b:v:3 1800k -profile:v:3 baseline $qsv_h264_params \
        \
        -map 0:v:0 -map 0:v:1 -map 0:v:1 -map 0:v:1 \
        -map 0:a:0 -map 0:a:0 \
        -f mpegts -overrun_nonfatal 1 -fifo_size 262144 \
            "rist://vps.wg:19352?cname=live_mvar&session-timeout=5000&keepalive-interval=2000" \
