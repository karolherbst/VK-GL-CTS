#!/bin/bash

DIR="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

cd $DIR

export MESA_GLSL_CACHE_MAX_SIZE=64G
export MESA_GLSL_CACHE_DIR=$DIR/cache/

TESTLIST_FILE=$DIR/$(echo "test-$RANDOM")
OUT_FILE=$DIR/$(echo "out-$RANDOM")

cores=1
# $(nproc --all)
CTS_VERSION="4.6.1.x"
GL_VERSION="46"
ARGS="--output $OUT_FILE --job $cores --timeout 60 -- --deqp-visibility=hidden"

function cleanup {
	rm $TESTLIST_FILE 2>/dev/null
	rm $OUT_FILE 2>/dev/null
}
trap cleanup EXIT

declare -A tests

echo "Creating testcase file"
#	"$DIR"/external/openglcts/data/mustpass/egl/aosp_mustpass/master/egl-master.txt \
#	"$DIR"/external/openglcts/data/mustpass/gles/aosp_mustpass/master/*.txt \
while read line; do
	group=${line%%.*}
	test_name=${line#*.}
	tests[$test_name]=$group
done < <(cat \
	"$DIR"/external/openglcts/data/mustpass/gles/khronos_mustpass/master/*-khr-master.txt \
	"$DIR"/external/openglcts/data/mustpass/gles/khronos_mustpass_noctx/master/gles*-khr-noctx-master.txt \
	"$DIR"/external/openglcts/data/mustpass/gles/khronos_mustpass_single/master/gles*-khr-single.txt \
	"$DIR"/external/openglcts/data/mustpass/gl/khronos_mustpass/${CTS_VERSION}/gl${GL_VERSION}-master.txt \
	"$DIR"/external/openglcts/data/mustpass/gl/khronos_mustpass/${CTS_VERSION}/gl${GL_VERSION}-gtf-master.txt \
	"$DIR"/external/openglcts/data/mustpass/gl/khronos_mustpass_noctx/${CTS_VERSION}/gl*-khr-master.txt \
	"$DIR"/external/openglcts/data/mustpass/gl/khronos_mustpass_single/${CTS_VERSION}/gl${GL_VERSION}-khr-single.txt \
| grep -v \
	-e multithread \
	-e multi_thread \
| sort -u)

for idx in "${!tests[@]}"; do
	echo "${tests[$idx]}.$idx"
done | sort -u > $TESTLIST_FILE

rm -rfv /tmp/deqp_runner.* > /dev/null
rm -rfv "$MESA_GLSL_CACHE_DIR" > /dev/null
../parallel-deqp-runner/build/deqp-runner --deqp "$DIR"/build/external/openglcts/modules/glcts --caselist $TESTLIST_FILE $ARGS
grep $OUT_FILE -v -e ,Pass -e ,Skip | sort > $1
#cd "$DIR"/build/external/openglcts/modules/
#gdb --args ./glcts --deqp-caselist-file $TESTLIST_FILE --deqp-visibility=hidden
