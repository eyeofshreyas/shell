#!/usr/bin/env bash
set -e
cd "$(dirname "$(readlink -f "$0")")"

mkdir -p "$PWD/.local"

if [ ! -d build ]; then
    cmake -S . -B build \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_INSTALL_PREFIX=$PWD/.local \
      -DINSTALL_LIBDIR=lib/caelestia \
      -DINSTALL_QMLDIR=lib/qt6/qml \
      -DINSTALL_QSCONFDIR=etc/xdg/quickshell/caelestia \
      -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
fi

cmake --build build
cmake --install build

run_quickshell() {
    cmake --build build
    cmake --install build

    pkill -x quickshell || true
    pkill -f 'qs -c caelestia' || true

    export QML2_IMPORT_PATH="$PWD/.local/lib/qt6/qml:$QML2_IMPORT_PATH"
    QS_CONFIG_NAME=caelestia \
    XDG_CONFIG_DIRS="$PWD/.local/etc/xdg" \
    quickshell &
}

export -f run_quickshell

# Same as run.sh but -n so entr works with no controlling TTY (needed at login)
find \
    "$PWD" \
    -name '*.qml' -o -name '*.cpp' -o -name '*.hpp' \
| grep -v "^$PWD/build" \
| entr -rn bash -c run_quickshell
