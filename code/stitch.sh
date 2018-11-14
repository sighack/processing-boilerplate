if [ "$#" != "2" ]; then
    echo "usage: $0 <seed> <output>"
    exit 1
fi
COLS=`ls ${1}-tile-*.png | sed -e 's/.*tile-\(.*\).png/\1/g' | tr '-' ' ' | cut -d\  -f 1 | sort | uniq | wc -l | awk '{ print $1 }'`
ROWS=`ls ${1}-tile-*.png | sed -e 's/.*tile-\(.*\).png/\1/g' | tr '-' ' ' | cut -d\  -f 2 | sort | uniq | wc -l | awk '{ print $1 }'`
echo "Found a ${COLS}x${ROWS} tiled image"
montage -limit memory 16000000000 -limit map 16000000000 -mode concatenate -tile ${COLS}x${ROWS} ${1}-tile-*.png $2
