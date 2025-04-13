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
input="-i srt://:19352?mode=listener"
# input="-i src_20250412-224805.ts"
# input="-re -i src_20250412-224805.ts"
# input="-re -i src_20250413-143826.ts"
# dst="/var/www/hls_adapt/$name"
dst="/mnt/nas/Media/Live/hls/hls_ffmpeg/$name"
rec="/mnt/nas/Media/Live/hls/recording/$name"
# rec="/mnt/nas/Media/Live/hls/recording/${name}_${time}"
hls="max-files=16 target-duration=4 playlist-length=8"

scale="scale-method=fast hdr-tone-map=disabled"
h265="rate-control=vbr keyframe-period=0 quality-level=4"

# https://gist.github.com/nico-lab/58ac62e359bd63feed36af64db3e4406
# https://ffmpeg.org/ffmpeg-codecs.html

qsv_h264_params="-low_power 0 -tune zerolatency -preset veryfast -scenario livestreaming"
# qsv_hevc_params="-profile:v main10 -tier main -preset veryfast -tune zerolatency -forced_idr 0 -idr_interval 1 -scenario livestreaming -adaptive_i 1 -look_ahead 1"
qsv_hevc_params="-low_power 0 -tier main -preset veryfast -tune zerolatency -scenario livestreaming"
hls_params="-hls_time 4 -hls_list_size 32 -hls_flags delete_segments -master_pl_publish_rate 30"
# -hls_init_time 8

rm -f "${dst}_"*

ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv $input \
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
    -f mpegts - | ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -f mpegts -i - \
        \
        -c:a:0 copy \
        \
        -c:v:0 copy \
        -c:v:1 copy \
        \
        -filter:v:2 scale_qsv=w=1280:h=720 \
        -c:v:2 hevc_qsv -b:v:2 4000k -profile:v:2 main10 $qsv_hevc_params \
        \
        -filter:v:3 scale_qsv=w=854:h=480 \
        -c:v:3 hevc_qsv -b:v:3 1800k -profile:v:3 main10 $qsv_hevc_params \
        \
        -map 0:v:0 -map 0:v:1 -map 0:v:1 -map 0:v:1 -map 0:a:0 \
        -f mpegts - | ffmpeg -hide_banner -f mpegts -i - \
            \
            -c:a:0 copy \
            -c:a:1 aac -b:a:1 160k -ac 2 \
            \
            -c:v:0 copy \
            -c:v:1 copy \
            -c:v:2 copy \
            -c:v:3 copy \
            \
            -filter:v:4 zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p \
            -c:v:4 libx264 -profile:v:4 baseline -crf 25 -maxrate 3200k -bufsize 8M -preset ultrafast -tune zerolatency \
            \
            -map 0:v:0 -map 0:v:1 -map 0:v:2 -map 0:v:3 -map 0:v:2 \
            -map 0:a:0 -map 0:a:0 \
            -f mpegts - | ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -f mpegts -i - \
                \
                -c:a:0 copy \
                -c:a:1 copy \
                \
                -c:v:0 copy -tag:v:0 hvc1 -b:v:0 40M \
                -c:v:1 copy -tag:v:1 hvc1 -b:v:1 10M \
                -c:v:2 copy -tag:v:2 hvc1 -b:v:2 4000k \
                -c:v:3 copy -tag:v:3 hvc1 -b:v:3 1800k \
                -c:v:4 copy -tag:v:4 avc1 -b:v:4 3200k \
                \
                -filter:v:5 scale_qsv=format=nv12:w=854:h=480,vpp_qsv=tonemap=1 \
                -c:v:5 h264_qsv -tag:v:5 avc1 -b:v:5 1500k -profile:v:5 baseline $qsv_h264_params \
                \
                -map 0:v:0 -map 0:v:1 -map 0:v:2 -map 0:v:3 -map 0:v:4 -map 0:v:4 \
                -map 0:a:0 -map 0:a:1 \
                -f mpegts - | ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -f mpegts -i - \
                    \
                    -c:a:0 copy \
                    -c:v:0 copy \
                    -map 0:v:1 -map 0:a:0 \
                    -f mpegts "${rec}_${time}.ts" \
                    \
                    \
                    -c:a:0 copy \
                    -c:v:0 copy \
                    -map 0:v:4 -map 0:a:1 \
                    -f flv rtmp://vps.wg:1935/live/${name} \
                    \
                    \
                    -c:a:0 copy \
                    -c:a:1 copy -b:a:1 160k \
                    \
                    -c:v:0 copy -tag:v:0 hvc1 -b:v:0 40M \
                    -c:v:1 copy -tag:v:1 hvc1 -b:v:1 10M \
                    -c:v:2 copy -tag:v:2 hvc1 -b:v:2 4000k \
                    -c:v:3 copy -tag:v:3 hvc1 -b:v:3 1800k \
                    -c:v:4 copy -tag:v:4 avc1 -b:v:4 3200k \
                    -c:v:5 copy -tag:v:5 avc1 -b:v:5 1500k \
                    \
                    -map 0:v:0 -map 0:v:1 -map 0:v:2 -map 0:v:3 -map 0:v:4 -map 0:v:5 \
                    -map 0:a:0 -map 0:a:1 \
                    -f null "ffmpeg_${time}.ts" \
                    \
                    \
                    -c:a:0 copy \
                    \
                    -c:v:0 copy -tag:v:0 hvc1 -b:v:0 40M \
                    -c:v:1 copy -tag:v:1 hvc1 -b:v:1 10M \
                    -c:v:2 copy -tag:v:2 hvc1 -b:v:2 4000k \
                    -c:v:3 copy -tag:v:3 hvc1 -b:v:3 1800k \
                    \
                    -map 0:v:0 -map 0:v:1 -map 0:v:2 -map 0:v:3 \
                    -map 0:a:0 \
                    -f hls \
                    -var_stream_map "a:0,name:audio,agroup:audio,default:yes "\
"v:0,name:src,agroup:audio "\
"v:1,name:1080_hevc,agroup:audio "\
"v:2,name:720_hevc,agroup:audio "\
"v:3,name:480_hevc,agroup:audio "\
                    -master_pl_name "${name}_hevc.m3u8" $hls_params \
                    "${dst}_%v.m3u8" \
                    \
                    \
                    -c:a:0 copy -b:a:0 160k \
                    -c:a:1 copy -b:a:1 160k \
                    \
                    -c:v:0 copy -tag:v:0 avc1 -b:v:0 3200k \
                    -c:v:1 copy -tag:v:1 avc1 -b:v:1 1500k \
                    \
                    -map 0:v:4 -map 0:v:5 \
                    -map 0:a:1 -map 0:a:1 \
                    -f hls \
                    -var_stream_map \
"v:0,a:0,name:720_h264_audio "\
"v:1,a:1,name:480_h264_audio "\
                    -master_pl_name "${name}_h264.m3u8" $hls_params \
                    "${dst}_%v.m3u8"









#                     -c:a:0 copy \
#                     -c:a:1 copy -b:a:1 160k \
#                     -c:a:2 copy -b:a:2 160k \
#                     \
#                     -c:v:0 copy -tag:v:0 hvc1 -b:v:0 40M \
#                     -c:v:1 copy -tag:v:1 hvc1 -b:v:1 10M \
#                     -c:v:2 copy -tag:v:2 hvc1 -b:v:2 4000k \
#                     -c:v:3 copy -tag:v:3 hvc1 -b:v:3 1800k \
#                     -c:v:4 copy -tag:v:4 avc1 -b:v:4 3200k \
#                     -c:v:5 copy -tag:v:5 avc1 -b:v:5 1500k \
#                     \
#                     -map 0:v:0 -map 0:v:1 -map 0:v:2 -map 0:v:3 -map 0:v:4 -map 0:v:5 \
#                     -map 0:a:0 -map 0:a:1 -map 0:a:1 \
#                     -f hls \
#                     -var_stream_map "a:0,name:audio,agroup:audio,default:yes "\
# "v:0,name:src,agroup:audio "\
# "v:1,name:1080_hevc,agroup:audio "\
# "v:2,name:720_hevc,agroup:audio "\
# "v:3,name:480_hevc,agroup:audio "\
# "v:4,a:1,name:720_h264_audio "\
# "v:5,a:2,name:480_h264_audio "\
#                     -master_pl_name "${name}.m3u8" $hls_params \
#                     "${dst}_%v.m3u8"



                    # -f mpegts "ffmpeg_${time}.ts" -y


        # -f mpegts - | ffmpeg -hide_banner -hwaccel vaapi -hwaccel_output_format vaapi -f mpegts -i - \


            # -filter:v:4 "tonemap_vaapi=format=nv12:t=bt709:p=bt709:m=bt709:display=7500 3000|34000 16000|13250 34500|15635 16450|500 10000000" \
            # -c:v:4 h264_vaapi -profile:v:4 main -b:v:4 3200k -preset veryfast -tune zerolatency \




            # -filter:v:4 zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p \
            # -c:v:4 libx264 -profile:v:4 baseline -crf 25 -maxrate 3200k -bufsize 8M -preset ultrafast -tune zerolatency \
            # \



# ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv $input \
#     \
#     -c:a:0 copy \
#     -c:v:0 copy -b:v:0 40M \
#     \
#     -filter:v:1 scale_qsv=w=1920:h=1080 \
#     -c:v:1 hevc_qsv -b:v:1 10M -profile:v:1 main10 $qsv_hevc_params \
#     \
#     -map 0:v:0 -map 0:v:0 -map 0:a:0 \
#     -f mpegts - | ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -f mpegts -i - \
#         \
#         -c:a:0 copy \
#         -c:v:0 copy \
#         \
#         -c:a:1 copy \
#         -c:v:1 copy \
#         \
#         -filter:v:2 scale_qsv=w=1280:h=720 \
#         -c:v:2 hevc_qsv -b:v:2 4000k -profile:v:2 main10 $qsv_hevc_params \
#         \
#         -filter:v:3 scale_qsv=w=854:h=480 \
#         -c:v:3 hevc_qsv -b:v:3 1800k -profile:v:3 main10 $qsv_hevc_params \
#         \
#         -map 0:v:0 -map 0:v:1 -map 0:v:1 -map 0:v:1 -map 0:a:0 \
#         -f mpegts - | ffmpeg -hide_banner -f mpegts -i - \
#             \
#             -c:a:0 copy \
#             -c:v:0 copy \
#             \
#             -c:a:1 copy \
#             -c:v:1 copy \
#             \
#             -c:a:2 copy \
#             -c:v:2 copy \
#             \
#             -c:a:3 copy \
#             -c:v:3 copy \
#             \
#             -filter:v:4 zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p \
#             -c:v:4 libx264 -profile:v:4 baseline -crf 25 -maxrate 3200k -bufsize 8M -preset ultrafast -tune zerolatency \
#             \
#             -map 0:v:0 -map 0:v:1 -map 0:v:2 -map 0:v:3 -map 0:v:2 -map 0:a:0 \
#             -f mpegts "ffmpeg_${time}.ts" -y




        # -filter:v:2 zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p \
        # -c:v:2 libx264 -crf 25 -maxrate 8M -bufsize 2M -profile:v:2 baseline -preset ultrafast -tune zerolatency \
        # \


    # -c:v:1 hevc_qsv -b:v:1 10M -profile:v:1 main10 $qsv_hevc_params \


        # -c:v:1 libx264 -x264-params opencl=true -crf 32 -maxrate 8M -bufsize 2M -profile:v:1 baseline -preset ultrafast -tune zerolatency \
        # -c:v:1 libx264 -crf 22 -preset ultrafast -tune zerolatency \
        # -c:v:1 h264_qsv -b:v:1 8M -profile:v:1 baseline $qsv_h264_params \

# ffmpeg -vf   video-output.mp4


