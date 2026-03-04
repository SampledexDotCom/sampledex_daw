#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
TARGET="TheSampledexWorkflow"
APP_PATH="${BUILD_DIR}/BeatMakerNoRecord_build/TheSampledexWorkflow_artefacts/TheSampledexWorkflow.app"
TRACKTION_ROOT="${ROOT_DIR}/../ThirdParty/tracktion_engine"
OPEN_APP=1
USE_JUCE_DEVELOP=0

print_help() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Builds TheSampledexWorkflow and optionally opens the app.

Options:
  --no-open         Build only, do not open the .app
  --juce-develop    Use JUCE develop branch via CPM (not recommended for first-time builds)
  -h, --help        Show this help message
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-open)
      OPEN_APP=0
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

if [[ ! -d "${TRACKTION_ROOT}" ]]; then
  echo "[BeatMakerApp] Engine folder not found at ${TRACKTION_ROOT}" >&2
  exit 1
fi

if [[ -f "${BUILD_DIR}/CMakeCache.txt" ]]; then
  cached_home="$(sed -n 's/^CMAKE_HOME_DIRECTORY:INTERNAL=//p' "${BUILD_DIR}/CMakeCache.txt" | head -n 1 || true)"
  if [[ -n "${cached_home}" && "${cached_home}" != "${ROOT_DIR}" ]]; then
    echo "[BeatMakerApp] Clearing stale build cache (source moved from ${cached_home})..."
    rm -rf "${BUILD_DIR}"
  fi
fi

configure_args=()
if [[ "${USE_JUCE_DEVELOP}" -eq 1 ]]; then
  echo "[BeatMakerApp] Using JUCE develop branch via CPM."
  configure_args+=("-DJUCE_CPM_DEVELOP=ON")
fi

echo "[BeatMakerApp] Configuring..."
cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" "${configure_args[@]}"

echo "[BeatMakerApp] Building ${TARGET}..."
cmake --build "${BUILD_DIR}" --target "${TARGET}" -j8

if [[ ! -d "${APP_PATH}" ]]; then
  echo "[BeatMakerApp] App not found at ${APP_PATH}" >&2
  exit 1
fi

if [[ "${OPEN_APP}" -eq 1 ]]; then
  echo "[BeatMakerApp] Opening app..."
  open "${APP_PATH}"
else
  echo "[BeatMakerApp] App ready: ${APP_PATH}"
fi
