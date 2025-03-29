#!/bin/bash -ex
while killall ffmpeg; do sleep 1; done

exec &> /tmp/rtmp_adaptive.log
date
name="$1"
vopts="-c:v libx264 -tune zerolatency -preset veryfast -crf 26 -f flv"
#vopts="-c:v libx264 -preset fast -crf 28 -f flv"
aopts="-c:a aac"
hvopts="-c:v h264_qsv -f flv -tune zerolatency -preset veryfast"

# w	h	b:v	b:a	b	bw/1000
# 3840	2160	32768	256	33024	33817
# 1920	1080	8192	196	8388	8589
# 1600	900	5689	128	5817	5956
# 1365	768	4143	128	4271	4373
# 1280	720	3641	128	3769	3859
# 1024	576	2330	96	2426	2484
# 960	540	2048	96	2144	2195
# 853	480	1618	96	1714	1755
# 640	360	910	64	974	998
# 427	240	405	64	469	480

function hconv() {
  w=$1
  h=$2
  v=$3
  bv=$4
  ba=$5
  #echo -n "-vf hwupload=extra_hw_frames=64,format=qsv,scale_qsv=w=$w:h=$h " \
  #        "-c:v h264_qsv -b:v $bv -maxrate $bv" \
  #        "-f flv $aopts -b:a $ba rtmp://127.0.0.1/adapthls/${name}_$v"
  echo -n "$hvopts $aopts -b:v $bv -b:a $ba -vf vpp_qsv=w=$w:h=$h rtmp://127.0.0.1/adapthls/${name}_$v"
}

function cconv() {
  w=$1
  h=$2
  v=$3
  bv=$4
  ba=$5
  echo -n "$vopts $aopts -b:v $bv -b:a $ba -vf scale=$w:$h rtmp://127.0.0.1/adapthls/${name}_$v"
}

function nconv() {
  :
}


# Test publish to live with no conversion
if false; then
	ffmpeg -i rtmp://localhost/adapt/$name -c copy -f flv rtmp://127.0.0.1/live/$name
	exit
fi

# Recording
time="$(date +%Y%m%d-%H%M%S)"
rec="/mnt/nas/Media/Live/hls/recording/${name}_${time}"

# Hardware decoding and encoding
if true; then
	ffmpeg -hwaccel qsv -c:v h264_qsv -i rtmp://localhost/adapt/$name \
	  -c:v copy -c:a copy -f flv rtmp://127.0.0.1/adapthls/${name}_src \
	  $hvopts -c:a copy -b:v 8M -vf vpp_qsv=w=1920:h=1080 rtmp://127.0.0.1/adapthls/${name}_1080 \
	  $(nconv 1600 900 900 5689k 128k) \
	  $(nconv 1366 768 768 4143k 128k) \
	  $(hconv 1280 720 720 3641k 128k) \
	  $(nconv 1024 576 576 2330k  96k) \
	  $(nconv  960 540 540 2048k  96k) \
	  $(hconv  854 480 480 1618k  96k) \
	  $(nconv  654 368 360  910k  64k) \
	  $(nconv  426 240 240  405k  64k) \

	exit
fi

exit

if true; then
	ffmpeg -hwaccel qsv -c:v h264_qsv -i rtmp://localhost/adapt/$name \
	  -c:v copy -c:a copy -f flv rtmp://127.0.0.1/adapthls/${name}_src \
	  $hvopts -c:a copy -b:v 8M -vf scale_qsv=w=1920:h=1080 rtmp://127.0.0.1/adapthls/${name}_1080 \
	  $(nconv 1600 900 900 5689k 128k) \
	  $(nconv 1366 768 768 4143k 128k) \
	  $(hconv 1280 720 720 3641k 128k) \
	  $(nconv 1024 576 576 2330k  96k) \
	  $(nconv  960 540 540 2048k  96k) \
	  $(hconv  854 480 480 1618k  96k) \
	  $(nconv  654 368 360  910k  64k) \
	  $(nconv  426 240 240  405k  64k) \

	exit
fi

exit

ffmpeg -hwaccel qsv -c:v h264_qsv -i rtmp://localhost/adapt/$name \
  -c:v copy -c:a copy -f flv rtmp://127.0.0.1/adapthls/${name}_src \
  -c:v copy -c:a copy -f flv rtmp://127.0.0.1/adapthls/${name}_1080 \
  $(nconv 1600 900 900 5689k 128k) \
  $(nconv 1366 768 768 4143k 128k) \
  $(hconv 1280 720 720 3641k 128k) \
  $(nconv 1024 576 576 2330k  96k) \
  $(nconv  960 540 540 2048k  96k) \
  $(hconv  854 480 480 1618k  96k) \
  $(nconv  654 368 360  910k  64k) \
  $(nconv  426 240 240  405k  64k) \

exit

ffmpeg -threads 8 -i rtmp://localhost/adapt/$name \
  -c:v copy -c:a copy -f flv rtmp://127.0.0.1/adapthls/${name}_src \
  $vopts -c:a copy -b:v 8M -vf "scale=1920:1080" -f mpegts - 2> /tmp/rtmp_adaptive_src.log | \
ffmpeg -i - \
  $vopts -c:a copy -c:v copy rtmp://127.0.0.1/adapthls/${name}_1080 \
  -c:a copy -c:v copy -f mpegts - 2> /tmp/rtmp_adaptive_1080.log | \
ffmpeg -hwaccel qsv -c:v h264_qsv -i - \
  $(nconv 1600 900 900 5689k 128k) \
  $(nconv 1366 768 768 4143k 128k) \
  $(hconv 1280 720 720 3641k 128k) \
  $(nconv 1024 576 576 2330k  96k) \
  $(nconv  960 540 540 2048k  96k) \
  $(hconv  854 480 480 1618k  96k) \
  $(nconv  654 368 360  910k  64k) \
  $(nconv  426 240 240  405k  64k) \

exit

ffmpeg -i rtmp://localhost/adapt/$name \
  $vopts -c:a copy -b:v 8M -vf "scale=1920:1080" rtmp://127.0.0.1/adapthls/${name}_1080 \
  $(nconv 1600 900 900 5689k 128k) \
  $(nconv 1366 768 768 4143k 128k) \
  $(cconv 1280 720 720 3641k 128k) \
  $(nconv 1024 576 576 2330k  96k) \
  $(nconv  960 540 540 2048k  96k) \
  $(cconv  854 480 480 1618k  96k) \
  $(nconv  640 360 360  910k  64k) \
  $(nconv  426 240 240  405k  64k) \

exit

ffmpeg -i rtmp://localhost/adapt/$name \
  $vopts -c:a copy -b:v 8M -vf "scale=1920:1080" rtmp://127.0.0.1/adapthls/${name}_1080 \
  $(nconv 1600 900 900 5689k 128k) \
  $(cconv 1366 768 768 4143k 128k) \
  $(cconv 1280 720 720 3641k 128k) \
  $(cconv 1024 576 576 2330k  96k) \
  $(nconv  960 540 540 2048k  96k) \
  $(cconv  854 480 480 1618k  96k) \
  $(cconv  640 360 360  910k  64k) \
  $(nconv  426 240 240  405k  64k) \

exit

ffmpeg -i rtmp://localhost/adapt/$name \
  $vopts -c:a copy -b:v 32M -vf "scale=3840:2160" rtmp://127.0.0.1/adapthls/${name}_src \
  $vopts -c:a copy -b:v 8M -vf "scale=1920:1080" rtmp://127.0.0.1/adapthls/${name}_1080 \
  $(cconv 1280 720 720 3641k 128k) \

exit

ffmpeg -i rtmp://localhost/adapt/$name \
  -c:v copy -c:a copy -f flv -tune zerolatency rtmp://127.0.0.1/adapthls/${name}_src \
  $vopts -c:a copy -b:v 8M -vf "scale=1920:1080" - | \
ffmpeg -i - \
  -c:v copy -c:a copy -f flv -tune zerolatency rtmp://127.0.0.1/adapthls/${name}_1080 \
  $(nconv 1600 900 900 5689k 128k) \
  $(nconv 1366 768 768 4143k 128k) \
  $(cconv 1280 720 720 3641k 128k) \
  $(nconv 1024 576 576 2330k  96k) \
  $(nconv  960 540 540 2048k  96k) \
  $(nconv  854 480 480 1618k  96k) \
  $(nconv  640 360 360  910k  64k) \
  $(nconv  426 240 240  405k  64k) \
  &> /tmp/rtmp_adaptive_adapt.log

exit

ffmpeg -init_hw_device qsv=hw -filter_hw_device hw -i rtmp://localhost/adapt/$name \
  -c:v copy -c:a copy -f flv rtmp://127.0.0.1/adapthls/${name}_src \
  -vf hwupload=extra_hw_frames=64,format=qsv,scale_qsv=w=1920:h=1080 -c:v h264_qsv -b:v 8M -maxrate 8M \
  -c:a copy -f flv rtmp://127.0.0.1/adapthls/${name}_1080 \
  $(nconv 1600 900 900 5689k 128k) \
  $(nconv 1366 768 768 4143k 128k) \
  $(hconv 1280 720 720 3641k 128k) \
  $(nconv 1024 576 576 2330k  96k) \
  $(nconv  960 540 540 2048k  96k) \
  $(hconv  854 480 480 1618k  96k) \
  $(nconv  654 368 360  910k  64k) \
  $(nconv  426 240 240  405k  64k) \

exit

ffmpeg -hwaccel qsv -c:v h264_qsv -i rtmp://localhost/adapt/$name \
  -c:v copy -c:a copy -f flv rtmp://127.0.0.1/adapthls/${name}_src \
  $hvopts -c:a copy -b:v 8M -vf "scale_qsv=w=1920:h=1080" rtmp://127.0.0.1/adapthls/${name}_1080 \
  $(nconv 1600 900 900 5689k 128k) \
  $(nconv 1366 768 768 4143k 128k) \
  $(hconv 1280 720 720 3641k 128k) \
  $(nconv 1024 576 576 2330k  96k) \
  $(nconv  960 540 540 2048k  96k) \
  $(nconv  854 480 480 1618k  96k) \
  $(nconv  654 368 360  910k  64k) \
  $(nconv  426 240 240  405k  64k) \

exit

ffmpeg -i rtmp://localhost/adapt/$name \
  -c:v copy -c:a copy -f flv rtmp://127.0.0.1/adapthls/${name}_src \
  $vopts -c:a copy -b:v 8M -vf "scale=1920:1080" rtmp://127.0.0.1/adapthls/${name}_1080 \
  $(nconv 1600 900 900 5689k 128k) \
  $(nconv 1366 768 768 4143k 128k) \
  $(nconv 1280 720 720 3641k 128k) \
  $(nconv 1024 576 576 2330k  96k) \
  $(nconv  960 540 540 2048k  96k) \
  $(cconv  854 480 480 1618k  96k) \
  $(nconv  640 360 360  910k  64k) \
  $(nconv  426 240 240  405k  64k) \

exit

ffmpeg -hwaccel qsv -c:v h264_qsv -i rtmp://localhost/adapt/$name \
  -c:v copy -c:a copy -f flv rtmp://127.0.0.1/adapthls/${name}_src \
  $hvopts -c:a copy -b:v 8M -vf "scale_qsv=w=1934:h=1088" rtmp://127.0.0.1/adapthls/${name}_1080 \
  $(nconv 1600 900 900 5689k 128k) \
  $(hconv 1366 768 768 4143k 128k) \
  $(hconv 1280 720 720 3641k 128k) \
  $(hconv 1024 576 576 2330k  96k) \
  $(nconv  960 540 540 2048k  96k) \
  $(hconv  854 480 480 1618k  96k) \
  $(hconv  654 368 360  910k  64k) \
  $(nconv  426 240 240  405k  64k) \

exit
