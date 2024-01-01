#!/command/with-contenv bash
# shellcheck shell=bash

# Import healthchecks-framework
# shellcheck disable=SC1091
source /opt/healthchecks-framework/healthchecks.sh

# Default original codes
EXITCODE=0

# ===== Local Helper Functions =====

function get_pid_of_decoder {

  # $1: service_dir
  service_dir="$1"

  # Ensure variables are unset
  unset SOAPYSDR ACARS_BIN FREQ_STRING

  # Get SOAPYSDR
  eval "$(grep "SOAPYSDR=\"" "$service_dir")"

  # Get FREQS_ACARS
  eval "$(grep "FREQ_STRING=\"" "$service_dir")"

  # Get ACARS_BIN
  eval "$(grep "ACARS_BIN=\"" "$service_dir")"

  # Get PS output for the relevant process
  if [[ -n "$ACARS_BIN" ]]; then
    if [[ -n "$SOAPYSDR" ]]; then
      # shellcheck disable=SC2009
      ps_output=$(ps aux | grep "$ACARS_BIN" | grep " -d $SOAPYSDR " | grep "$FREQ_STRING")
    fi
  fi

  # Find the PID of the decoder based on command line
  process_pid=$(echo "$ps_output" | tr -s " " | cut -d " " -f 2)

  # Return the process_pid
  echo "$process_pid"

}

# ===== Check acarsdec processes =====

# For each service...
for service_dir in /etc/s6-overlay/scripts/*; do
  service_name=$(basename "$service_dir")

  # If the service is acarsdec-*...
  if [[ "$service_name" == acarsdec ]]; then

    decoder_pid=$(get_pid_of_decoder "$service_dir")
    decoder_udp_port="5550"
    decoder_server_prefix="acars"

  # If the server isn't acarsdec-.
  else
    # skip it!
    continue
  fi

  # If the process doesn't exists, then fail

  echo "==== Checking $service_name ====="

  if [[ -z "$decoder_pid" ]]; then
    echo "Cannot find PID of decoder $service_name: UNHEALTHY"
    EXITCODE=1
  else
    # If the process does exist, then make sure it has made a connection to localhost on the relevant port.
    if ! check_udp4_connection_established_for_pid "127.0.0.1" "ANY" "127.0.0.1" "$decoder_udp_port" "$decoder_pid"; then
      echo "Decoder $service_name (pid $decoder_pid) not connected to ${decoder_server_prefix}_server at 127.0.0.1:$decoder_udp_port: UNHEALTHY"
      EXITCODE=1
    else
      echo "Decoder $service_name (pid $decoder_pid) is connected to ${decoder_server_prefix}_server at 127.0.0.1:$decoder_udp_port: HEALTHY"
    fi
  fi

done

echo "==== Check Service Death Tallies ====="

# Check service death tally
mapfile -t SERVICES < <(find /run/service -maxdepth 1 -not -name "*s6*" | tail +2)
for service in "${SERVICES[@]}"; do
  SVDT=$(s6-svdt "$service" | grep -cv 'exitcode 0')
  if [[ "$SVDT" -gt 0 ]]; then
    echo "abnormal death tally for $(basename "$service") since last check is: $SVDT: UNHEALTHY"
    EXITCODE=1
  else
    echo "abnormal death tally for $(basename "$service") since last check is: $SVDT: HEALTHY"
  fi
  s6-svdt-clear "$service"
done

exit "$EXITCODE"
