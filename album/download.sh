#!/bin/sh

ID=`cat .id`
INDEX='index.html'
LIST='album.json'
REQUEST_TOKEN=`cat .requestToken`
RTK=`cat .rtk`

#---

if [ ! -f $INDEX ]
then
    echo 'Downloading index file...'
    URL="http://photo.renren.com/photo/$ID/albumlist/v7?offset=0&limit=40&showAll=1#"
    curl -H @.header $URL | gunzip -c > $INDEX
else
    echo 'Index file downloaded.'
fi

#---

if [ ! -f $LIST ]
then
    echo 'Processing album list...'
    pattern="'albumList': \[{"
    sed -e "/$pattern/p" -n index.html | sed -e 's/,$//' | sed -e 's/^[^ ]* //' > $LIST
else
    echo 'Album list processed.'
fi

#---

total_num=`cat $LIST | jq '. | length' -r`
for i in `seq $total_num $total_num`
do
    id=`cat $LIST | jq '.['$i'-1].albumId' -r`
    name=`cat $LIST | jq '.['$i'-1].albumName' -r`

    dir=`echo "album-$name" | sed -e 's/ /-/g'`
    if [ ! -d "$dir" ]
    then
        mkdir "$dir"
    fi
    
    A_URL="http://photo.renren.com/photo/$ID/album-$id/v7"
    if [ ! -f "$dir/index.html" ]
    then
        curl -H @.header $A_URL 2>/dev/null | gunzip > $dir/index.html
    fi

    list="$dir/photo.json"
    pattern="'photoList':\["
    sed -e "/$pattern/p" -n $dir/index.html | sed -e 's/,$//' | sed -e 's/^[^:]*://' > $list

    photo_num=`cat $list | jq '. | length' -r`
    echo "There are in all $photo_num photo(s) in album $name."
    if [ $photo_num -eq 0 ]
    then
        continue
    fi

    sed -e '/Referer/d' -e '/Host/d' .header > $dir/.header
    echo "Referer: $A_URL" >> $dir/.header
    echo "Host: fmn.rrfmn.com" >> $dir/.header

    sed -e '/Accept/d' -e '/Referer/d' -e '/Host/d' .header > $dir/.header_description
    echo "Referer: $A_URL" >> $dir/.header_description
    echo "Host: photo.renren.com" >> $dir/.header_description
    echo "Accept: application/json, text/javascript, */*; q=0.01" >> $dir/.header_description

    for j in `seq 1 $photo_num`
    do
        echo -ne "\rWorking on photo #$j..."
        photo_id=`cat $list | jq '.['$j'-1].photoId' -r`

        if [ 1 -eq $j ]
        then
            desc_url="http://photo.renren.com/photo/$ID/photo-$photo_id/layer?psource=3&requestToken=$REQUEST_TOKEN&_rtk=$RTK"
            desc="$dir/desc.json"
            curl -H @$dir/.header_description $desc_url 2>/dev/null > $desc
        fi

        if [ ! -f "$dir/$j.jpg" ]
        then
            photo_url=`cat $desc | jq 'if (.list['$j'-1].xLargeUrl // .list['$j'-1].large | length) > 0 then .list['$j'-1].xLargeUrl else .list['$j'-1].large end' -r`
            curl -H @$dir/.header $photo_url > $dir/$j.jpg 2>/dev/null

            comment_url="http://comment.renren.com/comment/xoa2?desc=true&offset=0&replaceUBBLarge=true&type=photo&entryId=$photo_id&entryOwnerId=$ID&&requestToken=$REQUEST_TOKEN&_rtk=$RTK"
            curl -H @$dir./header_comment $comment_url 2>/dev/null > $dir/${j}_comment.json
        fi
    done
    echo
done
