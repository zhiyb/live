#!/bin/bash -ex

# app=$1
# name=$2

app=adapt2
# name=stream
name=stream_test

# time="$(date +%Y%m%d-%H%M%S)"

source "$(dirname "$0")"/ffmpeg_config.sh

# input="-i srt://:19352?mode=listener"
input="-re -i src_20250413-143826.ts"
# input="-i src_20250413-143826.ts"

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
            -f segment -segment_format mpegts -strftime 1 -segment_time 24:00:00 step4_%Y-%m-%dT%H-%M-%S%z.ts -y

exit

            # -f mpegts step4_${time}.ts -y

            # -f mpegts step3_${time}.ts -y

            # -init_hw_device opencl=ocl -init_hw_device qsv -filter_hw_device ocl \

# :w=854:h=480

# hwdownload,format=nv12,hwupload=extra_hw_frames=64,format=qsv

# scale_qsv=w=1280:h=720:format=nv12,hwmap=derive_device=opencl

        # -init_hw_device vaapi=va -init_hw_device qsv=qs@va -init_hw_device opencl=ocl@va -filter_hw_device qs \
            # -init_hw_device vaapi=va:/dev/dri/renderD128,driver=iHD -init_hw_device qsv=qs@va -init_hw_device opencl=ocl@va -filter_hw_device ocl \

            # -c:v:3 h264_qsv -b:v:3 3500k -profile:v:3 baseline $qsv_h264_params \

# vpp_qsv=procamp=1:saturation=1.10:contrast=1.01:brightness=5:out_range=limited

            # -filter:v:3 hwupload,tonemap_opencl=format=nv12:p=bt709:t=bt709:m=bt709:tonemap=hable:peak=100:desat=0,hwdownload,format=nv12 \
            # -c:v:3 libx264 -profile:v:3 baseline -crf 25 -maxrate 3500k -bufsize 8M -preset ultrafast -tune zerolatency \

            # -filter:v:3 hwmap=derive_device=opencl,tonemap_opencl=format=nv12:p=bt709:t=bt709:m=bt709:tonemap=hable:peak=300:desat=0,hwmap=derive_device=qsv \
            # -c:v:3 h264_qsv -b:v:3 3500k -profile:v:3 baseline $qsv_h264_params \

            # -filter:v:3 vpp_qsv=tonemap=1,vpp_qsv=procamp=1:saturation=1.10:contrast=1.01:brightness=5:out_range=limited,vpp_qsv=format=nv12:out_color_matrix=bt709:out_color_primaries=bt709:out_color_transfer=bt709 \
            # -c:v:3 h264_qsv -b:v:3 3500k -profile:v:3 baseline $qsv_h264_params \

            # -filter:v:3 zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p \
            # -c:v:3 libx264 -profile:v:3 baseline -crf 25 -maxrate 3500k -bufsize 8M -preset ultrafast -tune zerolatency \



