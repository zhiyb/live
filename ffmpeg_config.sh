#!/config_only_do_not_run

# input="src_20250319-192444.ts"
# src="videotestsrc is-live=true ! video/x-raw,width=3840,height=2160 ! qsvh265enc"
# src="rtmpsrc location=rtmp://localhost/$app/$name"
# dst="$name"

time="$(date +%Y%m%d-%H%M%S)"

# input="-f flv -listen 1 -i rtmp://0.0.0.0:19352/$app/$name"
# input="-i srt://:19352?mode=listener"
# input="-i src_20250412-224805.ts"
# input="-re -i src_20250412-224805.ts"
# input="-re -i src_20250413-143826.ts"

# dst="/var/www/hls_adapt/$name"
dst="/mnt/nas/Media/Live/hls/hls_ffmpeg/$name"

rec="/mnt/nas/Media/Live/hls/recording/$name"
# rec="/mnt/nas/Media/Live/hls/recording/${name}_${time}"

# gstreamer
# hls="max-files=16 target-duration=4 playlist-length=8"
# scale="scale-method=fast hdr-tone-map=disabled"
# h265="rate-control=vbr keyframe-period=0 quality-level=4"

# ffmpeg
# https://ffmpeg.org/ffmpeg-codecs.html
qsv_h264_params="-low_power 0 -tune zerolatency -preset veryfast"
# qsv_hevc_params="-profile:v main10 -tier main -preset veryfast -tune zerolatency -forced_idr 0 -idr_interval 1 -scenario livestreaming -adaptive_i 1 -look_ahead 1"
qsv_hevc_params="-low_power 0 -tier main -preset veryfast -tune zerolatency -scenario livestreaming"
hls_params="-hls_time 4 -hls_list_size 32 -hls_flags delete_segments -master_pl_publish_rate 30"
# -hls_init_time 8
# -hls_segment_type fmp4
