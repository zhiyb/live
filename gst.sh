#!/bin/bash -ex

# app=$1
# name=$2

app=adapt2
name=gstreamer

# w     h       b:v     b:a     b       bw/1000
# 3840  2160    32768   256     33024   33817
# 1920  1080    8192    196     8388    8589
# 1280  720     3641    128     3769    3859
# 854   480     1618    96      1714    1755

src="videotestsrc is-live=true ! video/x-raw,width=3840,height=2160 ! qsvh265enc"
# src="rtmpsrc location=rtmp://localhost/$app/$name"
dst="/var/www/hls_adapt/$name"
# dst="$name"
hls="max-files=16 target-duration=4 playlist-length=8"

cat - > ${dst}.m3u8 <<MASTER
#EXTM3U

#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",DEFAULT=YES,URI="${name}_audio.m3u8"

#EXT-X-STREAM-INF:BANDWIDTH=1800000,RESOLUTION=854x480,AUDIO="audio",CODECS="hvc1.1.4.L123.B0"
${name}_480.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=4000000,RESOLUTION=1280x720,AUDIO="audio",CODECS="hvc1.1.4.L123.B0"
${name}_720.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=9000000,RESOLUTION=1920x1080,AUDIO="audio",CODECS="hvc1.1.4.L123.B0"
${name}_1080.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=35000000,RESOLUTION=3840x2160,AUDIO="audio",CODECS="hvc1.1.4.L123.B0"
${name}_src.m3u8
MASTER

scale="scale-method=fast hdr-tone-map=disabled"
h265="rate-control=vbr keyframe-period=0 quality-level=4"

time="$(date +%Y%m%d-%H%M%S)"

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
