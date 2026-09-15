#!/usr/bin/env bash
set -euo pipefail

manifest="${1:-multipass.json}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 ||
    { echo "Required command not found: $1" >&2; exit 127; }
}

require_cmd multipass
require_cmd jq

jq -e '.vms | type == "array"' "$manifest" >/dev/null

jq -c '. as $root | $root.vms[] | {defaults: ($root.defaults // {}), vm: .}' \
  "$manifest" |
while IFS= read -r entry; do
  defaults="$(jq -c '.defaults' <<<"$entry")"
  vm="$(jq -c '.vm' <<<"$entry")"

  name="$(jq -r '.name' <<<"$vm")"
  image="$(jq -r '.image // $defaults.image // "lts"' \
    --argjson defaults "$defaults" <<<"$vm")"
  cpus="$(jq -r '.cpus // $defaults.cpus // 2' \
    --argjson defaults "$defaults" <<<"$vm")"
  memory="$(jq -r '.memory // $defaults.memory // "2G"' \
    --argjson defaults "$defaults" <<<"$vm")"
  disk="$(jq -r '.disk // $defaults.disk // "10G"' \
    --argjson defaults "$defaults" <<<"$vm")"
  bridged="$(jq -r '.bridged // $defaults.bridged // false' \
    --argjson defaults "$defaults" <<<"$vm")"
  cloud_init="$(jq -r '.cloud_init // empty' <<<"$vm")"

  if multipass info "$name" >/dev/null 2>&1; then
    echo "Exists: $name" >&2
    continue
  fi

  args=(
    launch "$image"
    --name "$name"
    --cpus "$cpus"
    --memory "$memory"
    --disk "$disk"
  )

  if [[ "$bridged" == "true" ]]; then
    args+=(--bridged)
  fi

  if [[ -n "$cloud_init" ]]; then
    [[ -f "$cloud_init" ]] ||
      { echo "Cloud-init file not found for $name: $cloud_init" >&2; exit 1; }
    args+=(--cloud-init "$cloud_init")
  fi

  echo "Launching: $name ($image, ${cpus} CPU, $memory RAM, $disk disk)" >&2
  multipass "${args[@]}"
done
