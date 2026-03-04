#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
TARGET="BeatMakerNoRecord"
APP_PATH="${BUILD_DIR}/examples/BeatMakerNoRecord/BeatMakerNoRecord_artefacts/BeatMakerNoRecord.app"
OPEN_APP=1
CONFIGURE_IF_NEEDED=1
USE_JUCE_DEVELOP=0

print_help() {
  cat <<HELP
Usage: $(basename "$0") [options]

Builds BeatMakerNoRecord and optionally opens the app.

Options:
  --no-open         Build only, do not open the .app
  --skip-configure  Skip CMake configure step
  --juce-develop    Use JUCE develop branch via CPM (not recommended for first-time builds)
  -h, --help        Show this help message
HELP
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-open)
      OPEN_APP=0
      shift
      ;;
    --skip-configure)
      CONFIGURE_IF_NEEDED=0
      shift
      ;;
    --juce-develop)
      USE_JUCE_DEVELOP=1
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      print_help
      exit 1
      ;;
  esac
done

configure_args=()
if [[ "${USE_JUCE_DEVELOP}" -eq 1 ]]; then
  echo "[run_beatmaker] Using JUCE develop branch via CPM."
  configure_args+=("-DJUCE_CPM_DEVELOP=ON")
fi

if [[ "${CONFIGURE_IF_NEEDED}" -eq 1 ]]; then
  echo "[run_beatmaker] Configuring CMake (stable JUCE by default)..."
  cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" "${configure_args[@]}"
fi

echo "[run_beatmaker] Building ${TARGET}..."
cmake --build "${BUILD_DIR}" --target "${TARGET}" -j8

if [[ ! -d "${APP_PATH}" ]]; then
  echo "[run_beatmaker] Build finished but app not found at:" >&2
  echo "  ${APP_PATH}" >&2
  exit 1
fi

if [[ "${OPEN_APP}" -eq 1 ]]; then
  echo "[run_beatmaker] Opening app..."
  open "${APP_PATH}"
else
  echo "[run_beatmaker] App ready at:"
  echo "  ${APP_PATH}"
fi
