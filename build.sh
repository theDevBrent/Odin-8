function build() {
    OUT_DIR="build"
    mkdir -p $OUT_DIR
    odin build src -out:$OUT_DIR/odin-8
    cp -r ROMS $OUT_DIR
    echo "Build created in ${OUT_DIR}"
}

case "$1" in
    -h|--help)
        show_help
        ;;
    -b|--build)
        build
        ;;
    *)
        echo "Invalid option. Use -h or --help to see available options."
        exit 1
        ;;
esac