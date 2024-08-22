SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

vagrant destroy -f
rm -rf ../confs/token