function _get_image_filename() {
    name=`echo "$1" | sed 's!/!---!g' | sed 's!:!-!g'`
    echo ${name}.tar
}
