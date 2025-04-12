#!/bin/bash -ex

# app=$1
# name=$2

app=adapt2
name=stream

# w     h       b:v     b:a     b       bw/1000
# 3840  2160    32768   256     33024   33817
# 1920  1080    8192    196     8388    8589
# 1280  720     3641    128     3769    3859
# 854   480     1618    96      1714    1755

# input="src_20250319-192444.ts"
# src="videotestsrc is-live=true ! video/x-raw,width=3840,height=2160 ! qsvh265enc"
# src="rtmpsrc location=rtmp://localhost/$app/$name"
# dst="$name"

time="$(date +%Y%m%d-%H%M%S)"

# input="-f flv -listen 1 -i rtmp://0.0.0.0:19352/$app/$name"
# input="-i srt://:19352?mode=listener"
input="-re -i src_20250412-224805.ts"
# dst="/var/www/hls_adapt/$name"
dst="/mnt/nas/Media/Live/hls/hls_ffmpeg/$name"
# rec="/mnt/nas/Media/Live/hls/recording/${name}_${time}"
hls="max-files=16 target-duration=4 playlist-length=8"

scale="scale-method=fast hdr-tone-map=disabled"
h265="rate-control=vbr keyframe-period=0 quality-level=4"

# https://gist.github.com/nico-lab/58ac62e359bd63feed36af64db3e4406
# https://ffmpeg.org/ffmpeg-codecs.html

qsv_h264_params="-tune zerolatency -preset veryfast -scenario livestreaming"
# qsv_hevc_params="-profile:v main10 -tier main -preset veryfast -tune zerolatency -forced_idr 0 -idr_interval 1 -scenario livestreaming -adaptive_i 1 -look_ahead 1"
qsv_hevc_params="-tier main -preset veryfast -tune zerolatency -scenario livestreaming"
hls_params="-hls_time 4 -hls_list_size 10 -hls_flags delete_segments+split_by_time -master_pl_publish_rate 30"
# -hls_init_time 8

ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv \
    $input \
    \
    -c:a:0 copy \
    -c:v:0 copy -b:v:0 40M \
    \
    -filter:v:1 scale_qsv=w=1920:h=1080 \
    -c:v:1 hevc_qsv -b:v:1 10M -profile:v:1 main10 $qsv_hevc_params \
    \
    -filter:v:2 scale_qsv=w=1280:h=720 \
    -c:v:2 hevc_qsv -b:v:2 4000k -profile:v:2 main10 $qsv_hevc_params \
    \
    -filter:v:3 scale_qsv=w=854:h=480 \
    -c:v:3 hevc_qsv -b:v:3 1800k -profile:v:3 main10 $qsv_hevc_params \
    \
    -filter:v:4 vpp_qsv=tonemap=1:out_color_matrix=bt709:out_color_primaries=bt709:out_color_transfer=bt709:format=nv12:w=1920:h=1080 \
    -c:v:4 h264_qsv -b:v:4 8M -profile:v:4 baseline $qsv_h264_params \
    \
    -filter:v:5 vpp_qsv=tonemap=1:format=nv12:w=1280:h=720 \
    -c:v:5 h264_qsv -b:v:5 3200k -profile:v:5 baseline $qsv_h264_params \
    \
    -filter:v:6 vpp_qsv=tonemap=1:format=nv12:w=854:h=480 \
    -c:v:6 h264_qsv -b:v:6 1500k -profile:v:6 baseline $qsv_h264_params \
    \
    -map 0:v:0 -map 0:v:0 -map 0:v:0 -map 0:v:0 -map 0:v:0 -map 0:v:0 -map 0:v:0 -map 0:a:0 \
    -f mpegts ffmpeg.ts -y

exit



    ffmpeg -i -
    \
    -map 0:v:0 -map 0:v:0 -map 0:v:0 -map 0:v:0 -map 0:v:0 -map 0:v:0 -map 0:v:0 -map 0:a:0 \
    -f hls -tag:v hvc1 \
    -var_stream_map "a:0,name:audio,agroup:audio,default:yes "\
"v:0,name:src,agroup:audio "\
"v:1,name:1080_hevc,agroup:audio "\
"v:2,name:720_hevc,agroup:audio "\
"v:3,name:480_hevc,agroup:audio "\
"v:4,name:1080_h264,agroup:audio "\
"v:5,name:720_h264,agroup:audio "\
"v:6,name:480_h264,agroup:audio "\
    -master_pl_name "${name}.m3u8" $hls_params \
    "${dst}_%v.m3u8"

