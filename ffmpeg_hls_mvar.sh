#!/bin/bash -ex

name=stream
# name=stream_test

# input="-i srt://:19352?mode=listener"
input="-overrun_nonfatal 1 -fifo_size 262144 -i rist://@[::]:19352?cname=live_mvar&session-timeout=5000&keepalive-interval=2000"
# input="-re -i src_20250413-143826.ts"

hls_params="-hls_time 4 -hls_list_size 32 -hls_flags delete_segments -master_pl_publish_rate 30"

dst="/var/www/hls_ffmpeg/$name"
rm -f "${dst}-"*

ffmpeg="$(dirname "$0")/ffmpeg-master-latest-linux64-gpl/bin/ffmpeg"


# w     h       b:v     b:a     b       bw/1000
# 3840  2160    32768   256     33024   33817
# 1920  1080    8192    196     8388    8589
# 1280  720     3641    128     3769    3859
# 854   480     1618    96      1714    1755

# Input streams:
#
# 0:v:0 HEVC 2160p 40M
# 0:v:1 HEVC 1080p 10M
# 0:v:2 H264  720p  3M5
# 0:v:3 H264  480p  1M8
#
# 0:a:0 aac 7.1
# 0:a:1 aac 2.0 160k

while sleep 1; do

$ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv $input \
    \
    -c:a:0 copy \
    -c:v:0 copy \
    -map 0:v:3 -map 0:a:1 \
    -f flv rtmp://localhost:1935/live/${name} \
    \
    \
    -c:a:0 copy \
    \
    -c:v:0 copy -tag:v:0 hvc1 -b:v:0 40M \
    -c:v:1 copy -tag:v:1 hvc1 -b:v:1 10M \
    \
    -map 0:v:0 -map 0:v:1 \
    -map 0:a:0 \
    -f hls \
    -var_stream_map "a:0,name:audio,agroup:audio,default:yes "\
"v:0,name:src,agroup:audio "\
"v:1,name:1080_hevc,agroup:audio "\
    -master_pl_name "${name}-hevc.m3u8" $hls_params \
    "${dst}-%v.m3u8" \
    \
    \
    -c:a:0 copy -b:a:0 160k \
    -c:a:1 copy -b:a:1 160k \
    \
    -c:v:0 copy -tag:v:0 avc1 -b:v:0 3500k \
    -c:v:1 copy -tag:v:1 avc1 -b:v:1 1800k \
    \
    -map 0:v:2 -map 0:v:3 \
    -map 0:a:1 -map 0:a:1 \
    -f hls \
    -var_stream_map \
"v:0,a:0,name:720_h264_audio "\
"v:1,a:1,name:480_h264_audio "\
    -master_pl_name "${name}.m3u8" $hls_params \
    "${dst}-%v.m3u8"

done
