#!/bin/bash -ex

# app=$1
# name=$2

app=adapt2
name=stream
# name=stream_test

# time="$(date +%Y%m%d-%H%M%S)"

source "$(dirname "$0")"/ffmpeg_config.sh

# input="-i srt://:19352?mode=listener"
input="-i rist://@[::]:19352?cname=live"
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
    -c:v:0 copy \
    -map 0:v:0 -map 0:a:0 \
    -f null src_"${time}".ts \
    \
    -c:a:0 copy \
    -c:v:0 copy -b:v:0 40M \
    \
    -filter:v:1 scale_qsv=w=1920:h=1080 \
    -c:v:1 hevc_qsv -b:v:1 10M -profile:v:1 main10 $qsv_hevc_params \
    \
    -map 0:v:0 -map 0:v:0 -map 0:a:0 \
    -f mpegts - | $ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -f mpegts -i - \
        \
        -c:a:0 copy \
        -c:a:1 aac -b:a:1 160k -ac 2 \
        \
        -c:v:0 copy \
        -c:v:1 copy \
        \
        -init_hw_device opencl=ocl -filter_hw_device ocl \
        -filter:v:2 scale_qsv=w=1280:h=720,hwdownload,format=p010le,hwupload,tonemap_opencl=format=nv12:p=bt709:t=bt709:m=bt709:tonemap=hable:peak=300:desat=0,hwdownload,format=nv12 \
        -c:v:2 h264_qsv -b:v:2 3500k -profile:v:2 baseline $qsv_h264_params \
        \
        -map 0:v:0 -map 0:v:1 -map 0:v:1 \
        -map 0:a:0 -map 0:a:0 \
        -f mpegts - | $ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -f mpegts -i - \
            \
            -c:a:0 copy \
            -c:a:1 copy \
            \
            -c:v:0 copy -tag:v:0 hvc1 -b:v:0 40M \
            -c:v:1 copy -tag:v:1 hvc1 -b:v:1 10M \
            -c:v:2 copy -tag:v:2 avc1 -b:v:2 3500k \
            \
            -filter:v:3 scale_qsv=format=nv12:w=854:h=480 \
            -c:v:3 h264_qsv -tag:v:3 avc1 -b:v:3 1800k -profile:v:3 baseline $qsv_h264_params \
            \
            -map 0:v:0 -map 0:v:1 -map 0:v:2 -map 0:v:2 \
            -map 0:a:0 -map 0:a:1 \
            -f mpegts - | $ffmpeg -hide_banner -f mpegts -i - \
                \
                -c:a:0 copy \
                -c:v:0 copy \
                -map 0:v:1 -map 0:a:0 \
                -f mpegts "${rec}_${time}.ts" \
                \
                \
                -c:a:0 copy \
                -c:v:0 copy \
                -map 0:v:3 -map 0:a:1 \
                -f flv rtmp://vps.wg:1935/live/${name} \
                \
                \
                -c:a:0 copy \
                -c:a:1 copy -b:a:1 160k \
                \
                -c:v:0 copy -tag:v:0 hvc1 -b:v:0 40M \
                -c:v:1 copy -tag:v:1 hvc1 -b:v:1 10M \
                -c:v:2 copy -tag:v:2 avc1 -b:v:2 3200k \
                -c:v:3 copy -tag:v:3 avc1 -b:v:3 1500k \
                \
                -map 0:v:0 -map 0:v:1 -map 0:v:2 -map 0:v:3 \
                -map 0:a:0 -map 0:a:1 \
                -f null "ffmpeg_${time}.ts" \
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
