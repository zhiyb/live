#!/bin/bash -ex

# app=$1
# name=$2

# app=adapt2
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

input="srt://:19352?mode=listener"
dst="/var/www/hls_adapt/$name"
rec="/mnt/nas/Media/Live/hls/recording/${name}_${time}"
hls="max-files=16 target-duration=4 playlist-length=8"

scale="scale-method=fast hdr-tone-map=disabled"
h265="rate-control=vbr keyframe-period=0 quality-level=4"

# https://gist.github.com/nico-lab/58ac62e359bd63feed36af64db3e4406
# https://ffmpeg.org/ffmpeg-codecs.html

# qsv_params="-profile:v main10 -tier main -preset veryfast -tune zerolatency -forced_idr 0 -idr_interval 1 -scenario livestreaming -adaptive_i 1 -look_ahead 1"
qsv_params="-profile:v main10 -tier main -preset veryfast -tune zerolatency -scenario livestreaming"
hls_params="-hls_time 4 -hls_init_time 8 -hls_list_size 10 -hls_flags delete_segments+split_by_time"

ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv \
    -i "$input" \
    -c:a:0 copy \
    -c:v:0 copy \
    -filter:v:1 scale_qsv=w=1920:h=1080 \
    -c:v:1 hevc_qsv -b:v:1 10M $qsv_params \
    -map 0:v:0 -map 0:v:0 -map 0:a:0 \
    -f mpegts - | \
    ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -i - \
        -c:a:0 copy \
        -c:v:0 copy \
        -map 0:v:1 -map 0:a:0 \
        -f mpegts ${rec}.ts \
        \
        -c:a:0 copy -b:a:0 160k \
        -c:v:0 copy -b:v:0 40M \
        -c:v:1 copy -b:v:1 10M \
        -filter:v:2 scale_qsv=w=1280:h=720 \
        -c:v:2 hevc_qsv -b:v:2 4000k $qsv_params \
        -filter:v:3 scale_qsv=w=854:h=480 \
        -c:v:3 hevc_qsv -b:v:3 1800k $qsv_params \
        -map 0:v:0 -map 0:v:1 -map 0:v:1 -map 0:v:1 -map 0:a:0 \
        -f hls -tag:v hvc1 \
        -var_stream_map "a:0,name:audio,agroup:audio,default:yes v:0,name:src,agroup:audio v:1,name:1080,agroup:audio v:2,name:720,agroup:audio v:3,name:480,agroup:audio" \
        -master_pl_name "${name}.m3u8" $hls_params \
        "${dst}_%v.m3u8"


exit



ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv \
    -i "$input" \
    -c:a:0 copy \
    -c:v:0 copy \
    -filter:v:1 scale_qsv=w=1920:h=1080 \
    -c:v:1 hevc_qsv -b:v:1 10M -profile:v:1 main10 -tier main -preset faster \
    -map 0:v:0 -map 0:v:0 -map 0:a:0 \
    -f mpegts - | \
    ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -i - \
        -c:a:0 copy \
        -c:v:0 copy \
        -c:v:1 copy \
        -filter:v:2 scale_qsv=w=1280:h=720 \
        -c:v:2 hevc_qsv -b:v:2 4000k -profile:v:2 main10 -tier main -preset faster \
        -filter:v:3 scale_qsv=w=854:h=480 \
        -c:v:3 hevc_qsv -b:v:3 1800k -profile:v:3 main10 -tier main -preset faster \
        -map 0:v:0 -map 0:v:1 -map 0:v:1 -map 0:v:1 -map 0:a:0 \
        -f mpegts out_${time}.ts \
        -c:a:0 copy \
        -c:v:0 copy \
        -map 0:v:1 -map 0:a:0 \
        -f mpegts rec_1080p_${time}.ts


exit



ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -i snow.ts \
    -c:v:0 copy \
    -filter:v:1 scale_qsv=w=1920:h=1080 \
    -c:v:1 hevc_qsv -low_power 0 -b:v:1 9000k -profile main10 -tier main -preset faster \
    -map 0:v:0 -map 0:v:0 \
    -f mpegts - | \
    ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -i - \
        -c:v:0 copy \
        -c:v:1 copy \
        -filter:v:2 scale_qsv=w=1280:h=720 \
        -c:v:2 hevc_qsv -b:v:2 4000k -profile main10 -tier main -preset faster \
        -filter:v:3 scale_qsv=w=854:h=480 \
        -c:v:3 hevc_qsv -b:v:3 1800k -profile main10 -tier main -preset faster \
        -map 0:v:0 -map 0:v:1 -map 0:v:1 -map 0:v:1 \
        -f mpegts out_${time}.ts


exit





gst-launch-1.0 videotestsrc pattern=snow ! video/x-raw,width=3840,height=2160 ! \
    filesink location=out_${time}.ts



exit



gst-launch-1.0 filesrc location=src_20250319-192444.ts ! queue ! tsdemux name=demux \
    demux. ! aacparse ! queue ! \
        hlssink2 $hls playlist-location=${dst}_audio.m3u8 location=${dst}_audio_%08d.aac \
    demux. ! h265parse ! queue ! tee name=vsrc_enc \
    vsrc_enc. ! queue ! h265parse config-interval=2 ! \
        hlssink2 $hls playlist-location=${dst}_src.m3u8 location=${dst}_src_%08d.ts \
    vsrc_enc. ! queue ! vaapidecodebin ! video/x-raw,format=P010_10LE,width=1920,height=1080,colorimetry=bt2020 ! tee name=v1080 \
    v1080. ! queue ! vaapih265enc $h265 bitrate=9000 ! video/x-h265,format=P010_10LE,profile=main-10,colorimetry=bt2020 ! h265parse config-interval=2 ! \
        hlssink2 $hls playlist-location=${dst}_1080.m3u8 location=${dst}_1080_%08d.ts \


exit



ffmpeg -t 5 -hwaccel qsv -hwaccel_output_format qsv \
    -colorspace bt2020nc -color_primaries bt2020 -color_trc smpte2084 \
    -f lavfi -i nullsrc=s=3840x2160 \
    -filter_complex "geq=random(1)*255:128:128;aevalsrc=-2+random(0)" \
    -c:v hevc_qsv -low_power 0 -b:v 60M -profile:v main10 -tier main -preset veryfast -pix_fmt p010 \
    out_${time}.ts


exit


ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -i src_20250319-193547.ts \
    -c:v:0 copy \
    -filter:v:1 scale_qsv=w=1920:h=1080 \
    -c:v:1 hevc_qsv -low_power 0 -b:v:1 9000k -profile main10 -tier main -preset faster \
    -map 0:v:0 -map 0:v:0 \
    -f mpegts - | \
    ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -i - \
        -c:v:0 copy \
        -c:v:1 copy \
        -filter:v:2 scale_qsv=w=1280:h=720 \
        -c:v:2 hevc_qsv -b:v:2 4000k -profile main10 -tier main -preset faster \
        -filter:v:3 scale_qsv=w=854:h=480 \
        -c:v:3 hevc_qsv -b:v:3 1800k -profile main10 -tier main -preset faster \
        -map 0:v:0 -map 0:v:1 -map 0:v:1 -map 0:v:1 \
        -f mpegts out_${time}.ts


exit



ffmpeg -hide_banner -loglevel error -hwaccel vaapi -hwaccel_output_format vaapi -i src_20250319-193547.ts \
    -c:v:0 copy \
    -filter:v:1 scale_vaapi=w=1920:h=1080 \
    -c:v:1 hevc_vaapi -b:v:1 9000k -profile:v main10 -level 5.1 -preset veryfast \
    -map 0:v:0 -map 0:v:0 \
    -f mpegts - | \
    ffmpeg -hide_banner -hwaccel vaapi -hwaccel_output_format vaapi -i - \
        -c:v:0 copy \
        -c:v:1 copy \
        -filter:v:2 scale_vaapi=w=1280:h=720 \
        -c:v:2 hevc_vaapi -b:v:2 4000k -profile:v:2 main10 -level 5.1 -preset veryfast \
        -filter:v:3 scale_vaapi=w=854:h=480 \
        -c:v:3 hevc_vaapi -b:v:3 1800k -profile:v:3 main10 -level 5.1 -preset veryfast \
        -map 0:v:0 -map 0:v:1 -map 0:v:1 -map 0:v:1 \
        -f mpegts out_${time}.ts



exit





ffmpeg -hide_banner -hwaccel qsv -hwaccel_output_format qsv -i src_20250319-193547.ts \
    -c:v:0 copy \
    -filter:v:1 scale_qsv=w=1920:h=1080 \
    -c:v:1 hevc_qsv -low_power 0 -b:v:1 9000k -profile main10 -tier main -preset faster \
    -map 0:v:0 -map 0:v:0 \
    -f null -


exit


ffmpeg -hide_banner -loglevel error -hwaccel qsv -i src_20250319-193547.ts \
    -c:v:0 copy \
    -filter:v:1 scale_qsv=w=1920:h=1080 \
    -c:v:1 hevc_qsv -low_power 0 -b:v:1 9000k -profile:v main10 -level 5.1 \
    -map 0:v:0 -map 0:v:0 \
    -f mpegts - | \
    ffmpeg -hide_banner -hwaccel vaapi -hwaccel_output_format vaapi -i - \
        -c:v:0 copy \
        -c:v:1 copy \
        -filter:v:2 scale_vaapi=w=1280:h=720 \
        -c:v:2 hevc_vaapi -b:v:2 4000k -profile:v:2 main10 -level 5.1 \
        -filter:v:3 scale_vaapi=w=854:h=480 \
        -c:v:3 hevc_vaapi -b:v:3 1800k -profile:v:3 main10 -level 5.1 \
        -map 0:v:0 -map 0:v:1 -map 0:v:1 -map 0:v:1 \
        -f mpegts out_${time}.ts



exit





ffmpeg -hide_banner -loglevel error -hwaccel vaapi -hwaccel_output_format vaapi -i src_20250319-193547.ts \
    -c:v:0 copy \
    -filter:v:1 scale_vaapi=w=1920:h=1080 \
    -c:v:1 hevc_vaapi -b:v:1 9000k -profile:v main10 -level 5.1 \
    -map 0:v:0 -map 0:v:0 \
    -f mpegts - | \
    ffmpeg -hide_banner -hwaccel vaapi -hwaccel_output_format vaapi -i - \
        -c:v:0 copy \
        -c:v:1 copy \
        -filter:v:2 scale_vaapi=w=1280:h=720 \
        -c:v:2 hevc_vaapi -b:v:2 4000k -profile:v:2 main10 -level 5.1 \
        -filter:v:3 scale_vaapi=w=854:h=480 \
        -c:v:3 hevc_vaapi -b:v:3 1800k -profile:v:3 main10 -level 5.1 \
        -map 0:v:0 -map 0:v:1 -map 0:v:1 -map 0:v:1 \
        -f mpegts out_${time}.ts



exit




ffmpeg -hide_banner -loglevel error \


    -filter:v:1 scale_vaapi=w=1280:h=720 -c:v:2 hevc_vaapi -b:v:2 4000k -profile:v main10 -level 5.1 \
    -map 0:v:0 -map 1:v:1 -map 1:v:1 \

ffmpeg -hwaccel vaapi -hwaccel_output_format vaapi -i src_20250319-193547.ts \
    -filter:v:0 "scale=1920:1080" -b:v:0 9000k -c:v:0 hevc_vaapi -profile:v main10 -level 5.1 \
    -filter:v:1 "scale=1280:720" -b:v:1 4000k -c:v:1 hevc_vaapi -profile:v main10 -level 5.1 \
    -filter:v:2 "scale=854:480" -b:v:2 1800k -c:v:2 hevc_vaapi -profile:v main10 -level 5.1 \
    -map 0:v:0 -map 0:v:0 -map 0:v:0 \
    -f null -



gst-launch-1.0 srtsrc uri=srt://:19352 mode=listener latency=1000 ! tee name=src \
    src. ! queue ! filesink location=src_${time}.ts \



exit










gst-launch-1.0 filesrc location=src_20250319-192444.ts ! queue ! tsdemux name=demux \
    demux. ! aacparse ! queue ! \
        hlssink2 $hls playlist-location=${dst}_audio.m3u8 location=${dst}_audio_%08d.aac \
    demux. ! h265parse ! queue ! tee name=vsrc_enc \
    vsrc_enc. ! queue ! h265parse config-interval=2 ! \
        hlssink2 $hls playlist-location=${dst}_src.m3u8 location=${dst}_src_%08d.ts \
    vsrc_enc. ! queue ! vaapidecodebin ! video/x-raw,format=P010_10LE,width=1920,height=1080,colorimetry=bt2020 ! tee name=v1080 \
    v1080. ! queue ! vaapih265enc $h265 bitrate=9000 ! video/x-h265,format=P010_10LE,profile=main-10,colorimetry=bt2020 ! h265parse config-interval=2 ! \
        hlssink2 $hls playlist-location=${dst}_1080.m3u8 location=${dst}_1080_%08d.ts \


exit







gst-launch-1.0 srtsrc uri=srt://:19352 mode=listener latency=1000 ! tee name=src \
    src. ! queue ! filesink location=src_${time}.ts \
    src. ! queue leaky=1 ! tsdemux name=demux \
    demux. ! aacparse ! queue ! \
        hlssink2 $hls playlist-location=${dst}_audio.m3u8 location=${dst}_audio_%08d.aac \
    demux. ! h265parse ! queue ! tee name=vsrc_enc \
    vsrc_enc. ! queue ! h265parse config-interval=2 ! \
        hlssink2 $hls playlist-location=${dst}_src.m3u8 location=${dst}_src_%08d.ts \
    vsrc_enc. ! queue ! vaapidecodebin ! video/x-raw,format=P010_10LE,width=1920,height=1080,colorimetry=bt2020 ! tee name=v1080 \
    v1080. ! queue ! vaapih265enc $h265 bitrate=9000 ! video/x-h265,format=P010_10LE,profile=main-10,colorimetry=bt2020 ! h265parse config-interval=2 ! \
        hlssink2 $hls playlist-location=${dst}_1080.m3u8 location=${dst}_1080_%08d.ts \










gst-launch-1.0 filesrc location=test.ts ! queue leaky=1 ! tsdemux name=demux \
    demux. ! aacparse ! queue ! \
        hlssink2 $hls playlist-location=${dst}_audio.m3u8 location=${dst}_audio_%08d.aac \
    demux. ! h265parse ! queue ! tee name=vsrc_enc \
    vsrc_enc. ! queue ! h265parse config-interval=2 ! \
        hlssink2 name=hsrc $hls playlist-location=${dst}_src.m3u8 location=${dst}_src_%08d.ts \
    vsrc_enc. ! queue ! vaapidecodebin ! video/x-raw,format=P010_10LE,width=1920,height=1080,colorimetry=bt2020 ! tee name=v1080 \
    v1080. ! queue ! qsvh265enc bitrate=9000 ! video/x-h265,format=P010_10LE,profile=main-10,colorimetry=bt2020 ! h265parse config-interval=2 ! \
        hlssink2 name=h1080 $hls playlist-location=${dst}_1080.m3u8 location=${dst}_1080_%08d.ts \


exit


gst-launch-1.0 srtsrc uri=srt://:19352 mode=listener latency=1000 ! queue leaky=1 ! tsdemux name=demux \
    demux. ! aacparse ! queue ! \
        hlssink2 $hls playlist-location=${dst}_audio.m3u8 location=${dst}_audio_%08d.aac \
    demux. ! h265parse ! queue ! tee name=vsrc_enc \
    vsrc_enc. ! queue ! h265parse config-interval=2 ! \
        hlssink2 name=hsrc $hls playlist-location=${dst}_src.m3u8 location=${dst}_src_%08d.ts \
    vsrc_enc. ! queue ! vaapidecodebin ! video/x-raw,format=P010_10LE,width=1920,height=1080,colorimetry=bt2020 ! tee name=v1080 \
    v1080. ! queue ! qsvh265enc bitrate=9000 ! video/x-h265,format=P010_10LE,profile=main-10,colorimetry=bt2020 ! h265parse config-interval=2 ! \
        hlssink2 name=h1080 $hls playlist-location=${dst}_1080.m3u8 location=${dst}_1080_%08d.ts \


exit




gst-launch-1.0 srtsrc uri=srt://:19352 mode=listener latency=1000 ! queue leaky=1 ! tsdemux name=demux \
    demux. ! aacparse ! queue ! \
        hlssink2 $hls playlist-location=${dst}_audio.m3u8 location=${dst}_audio_%08d.aac \
    demux. ! h265parse ! queue ! tee name=vsrc_enc \
    vsrc_enc. ! queue ! h265parse config-interval=2 ! \
        hlssink2 name=hsrc $hls playlist-location=${dst}_src.m3u8 location=${dst}_src_%08d.ts \
    vsrc_enc. ! queue ! vaapidecodebin ! video/x-raw,format=P010_10LE,width=1920,height=1080 ! tee name=v1080 \
    v1080. ! queue ! vaapih265enc $h265 bitrate=9000 ! h265parse config-interval=2 ! \
        hlssink2 name=h1080 $hls playlist-location=${dst}_1080.m3u8 location=${dst}_1080_%08d.ts \




gst-launch-1.0 srtsrc uri=srt://:19352 mode=listener latency=1000 ! queue leaky=1 ! tsdemux name=demux \
    demux. ! aacparse ! queue ! \
        hlssink2 $hls playlist-location=${dst}_audio.m3u8 location=${dst}_audio_%08d.aac \
    demux. ! h265parse ! queue ! tee name=vsrc_enc \
    vsrc_enc. ! queue ! h265parse config-interval=2 ! \
        hlssink2 name=hsrc $hls playlist-location=${dst}_src.m3u8 location=${dst}_src_%08d.ts \
    vsrc_enc. ! queue ! vaapih265dec ! video/x-raw,format=P010_10LE ! tee name=v1080 \
    v1080. ! queue ! vaapih265enc $h265 bitrate=9000 ! h265parse config-interval=2 ! \
        hlssink2 name=h1080 $hls playlist-location=${dst}_1080.m3u8 location=${dst}_1080_%08d.ts \



    v1080. ! queue ! vaapipostproc $scale width=1280 height=720 ! vaapih265enc $h265 bitrate=4000 ! h265parse config-interval=2 ! \
        hlssink2 name=v720 $hls playlist-location=${dst}_720.m3u8 location=${dst}_720_%08d.ts \
    v1080. ! queue ! vaapipostproc $scale width=854 height=480 ! vaapih265enc $h265 bitrate=1800 ! h265parse config-interval=2 ! \
        hlssink2 name=v480 $hls playlist-location=${dst}_480.m3u8 location=${dst}_480_%08d.ts \




gst-launch-1.0 srtsrc uri=srt://:19352 mode=listener latency=1000 ! queue leaky=1 ! tsdemux name=demux \
    demux. ! aacparse ! queue max-size-time=0 ! \
        hlssink2 $hls playlist-location=${dst}_audio.m3u8 location=${dst}_audio_%08d.aac \
    demux. ! h265parse ! queue max-size-time=0 ! tee name=vsrc_enc \
    vsrc_enc. ! queue ! \
        hlssink2 name=hsrc $hls playlist-location=${dst}_src.m3u8 location=${dst}_src_%08d.ts \
    vsrc_enc. ! queue ! qsvh265dec ! fakesink



    videoscale ! video/x-raw,width=1920,height=1080 ! tee name=v1080 \
    v1080. ! queue ! fakesink



    qsvh265enc rate-control=vbr max-bitrate=9000 disable-hrd-conformance=true ! \
        hlssink2 name=h1080 $hls playlist-location=${dst}_1080.m3u8 location=${dst}_1080_%08d.ts \

exit



gst-launch-1.0 srtsrc uri="srt://:19352?mode=listener" ! tsdemux name=demux \
    demux. ! aacparse ! tee name=asrc \
    demux. ! h265parse ! tee name=vsrc_enc \
    vsrc_enc. ! queue ! \
        hlssink2 name=hsrc $hls playlist-location=${dst}_src.m3u8 location=${dst}_src_%08d.ts \
    vsrc_enc. ! queue ! qsvh265dec ! videoscale ! video/x-raw,width=1920,height=1080 ! tee name=v1080 \
    v1080. ! queue ! qsvh265enc ! \
        hlssink2 name=h1080 $hls playlist-location=${dst}_1080.m3u8 location=${dst}_1080_%08d.ts \
    v1080. ! queue ! videoscale ! video/x-raw,width=1280,height=720 ! qsvh265enc ! \
        hlssink2 name=v720 $hls playlist-location=${dst}_720.m3u8 location=${dst}_720_%08d.ts \
    v1080. ! queue ! videoscale ! video/x-raw,width=854,height=480 ! qsvh265enc ! \
        hlssink2 name=v480 $hls playlist-location=${dst}_480.m3u8 location=${dst}_480_%08d.ts \
    asrc. ! queue ! \
        hlssink2 $hls playlist-location=${dst}_audio.m3u8 location=${dst}_audio_%08d.aac \



# -loglevel error
ffmpeg -hide_banner \
    -i "srt://:19352?mode=listener" \
    -c copy -f mpegts - | \
    gst-launch-1.0 fdsrc fd=0 ! tsdemux name=demux \



ffmpeg -hide_banner \
    -f flv -listen 1 -i rtmp://0.0.0.0:19352/$app/$name \
    -c copy -f mpegts - | \
     tee test.ts | \


cat /home/zhiyb/live/test.ts | \
    gst-launch-1.0 fdsrc fd=0 ! tsdemux name=demux \
    demux. ! aacparse ! tee name=asrc \
    demux. ! h265parse ! tee name=vsrc_enc \
    vsrc_enc. ! queue ! \
        hlssink2 name=hsrc $hls playlist-location=${dst}_src.m3u8 location=${dst}_src_%08d.ts \
        asrc. ! queue ! hsrc.audio \
    vsrc_enc. ! queue ! qsvh265dec ! videoscale ! video/x-raw,width=1920,height=1080 ! tee name=v1080 \
    v1080. ! queue ! qsvh265enc ! \
        hlssink2 name=h1080 $hls playlist-location=${dst}_1080.m3u8 location=${dst}_1080_%08d.ts \
        asrc. ! queue ! h1080.audio \
    v1080. ! queue ! videoscale ! video/x-raw,width=1280,height=720 ! qsvh265enc ! \
        hlssink2 name=v720 $hls playlist-location=${dst}_720.m3u8 location=${dst}_720_%08d.ts \
        asrc. ! queue ! v720.audio \
    v1080. ! queue ! videoscale ! video/x-raw,width=854,height=480 ! qsvh265enc ! \
        hlssink2 name=v480 $hls playlist-location=${dst}_480.m3u8 location=${dst}_480_%08d.ts \
        asrc. ! queue ! v480.audio \
    asrc. ! queue ! \
        hlssink2 $hls playlist-location=${dst}_audio.m3u8 location=${dst}_audio_%08d.aac \

exit



ffmpeg -hide_banner -loglevel error \
    -f flv -listen 1 -i rtmp://0.0.0.0:19352/$app/$name \
    -c copy -f mpegts - | tee test.ts | \
    gst-launch-1.0 -v fdsrc fd=0 ! tsdemux name=demux \
    demux. ! queue ! h265parse ! fakesink silent=false
exit


     ! mpeg2dec ! videoconvert ! autovideosink

    tee name=vsrc \
    vsrc_enc. ! queue ! hlssink2 location=${dst}_src_%08d.ts \
    vsrc. ! queue ! videoscale ! video/x-raw,width=1920,height=1080 ! tee name=v1080 \
    v1080. ! queue ! qsvh265enc ! hlssink2 location=${dst}_1080_%08d.ts \
    v1080. ! queue ! videoscale ! video/x-raw,width=1280,height=720 ! qsvh265enc ! hlssink2 location=${dst}_720_%08d.ts \
    v1080. ! queue ! videoscale ! video/x-raw,width=854,height=480 ! qsvh265enc ! hlssink2 location=${dst}_480_%08d.ts \


exit

gst-launch-1.0 -vvv $src ! identity ! fakesink
exit

gst-launch-1.0 $src ! tee name=vsrc_enc \
    vsrc_enc. ! queue ! qsvh265dec ! tee name=vsrc \
    vsrc_enc. ! queue ! hlssink2 location=${dst}_src_%08d.ts \
    vsrc. ! queue ! videoscale ! video/x-raw,width=1920,height=1080 ! tee name=v1080 \
    v1080. ! queue ! qsvh265enc ! hlssink2 location=${dst}_1080_%08d.ts \
    v1080. ! queue ! videoscale ! video/x-raw,width=1280,height=720 ! qsvh265enc ! hlssink2 location=${dst}_720_%08d.ts \
    v1080. ! queue ! videoscale ! video/x-raw,width=854,height=480 ! qsvh265enc ! hlssink2 location=${dst}_480_%08d.ts \

# gst-launch-1.0 videotestsrc ! video/x-raw,width=1920,height=1080 ! autovideosink
