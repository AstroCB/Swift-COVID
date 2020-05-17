for file in *.svg; do
    name=${file%.*}
    if [ ! -f "$name.png" ]; then
        svgexport "$name.svg" "$name.png" 1x;
    fi
done
