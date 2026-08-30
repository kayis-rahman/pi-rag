#!/bin/zsh
set -euo pipefail

# Runs an opt-in writer/reader CloudKit test on two physical devices. Both must
# use the same dedicated test Apple Account; never run this against personal data.
if (( $# != 2 )); then
  print -u2 'Usage: ./scripts/run-cloudkit-capture-integration.sh <writer-udid> <reader-udid>'
  exit 64
fi

WRITER_ID="$1"
READER_ID="$2"
RUN_ID="${SYNAPSE_CLOUDKIT_INTEGRATION_RUN_ID:-$(uuidgen | tr '[:lower:]' '[:upper:]')}"
PROJECT="apple/Synapse/Synapse.xcodeproj"
SCHEME="Synapse iOS"
DERIVED_DATA="/tmp/synapse-cloudkit-integration-${RUN_ID}"
CONFIRMATION="DEDICATED_TEST_APPLE_ACCOUNT"

run_role() {
  local role="$1"
  local device_id="$2"
  local test_name="$3"

  env \
    SYNAPSE_CLOUDKIT_INTEGRATION=1 \
    SYNAPSE_CLOUDKIT_INTEGRATION_CONFIRM="$CONFIRMATION" \
    SYNAPSE_CLOUDKIT_INTEGRATION_ROLE="$role" \
    SYNAPSE_CLOUDKIT_INTEGRATION_RUN_ID="$RUN_ID" \
    SYNAPSE_CAPTURE_FORCE_HEURISTICS=1 \
    xcodebuild test \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "id=$device_id" \
      -derivedDataPath "$DERIVED_DATA" \
      -only-testing:"SynapseTests/CloudKitCaptureIntegrationTests/$test_name" \
      -allowProvisioningUpdates
}

print "CloudKit integration run: $RUN_ID"
print "Writer: $WRITER_ID"
run_role writer "$WRITER_ID" testWriterCreatesCaptureThroughTheRealAppIntent
print "Reader: $READER_ID"
run_role reader "$READER_ID" testReaderReceivesCaptureFromTheOtherPhysicalDevice
print "CloudKit integration passed; the reader deleted the test capture."
