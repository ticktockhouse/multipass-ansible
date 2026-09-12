#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  --list)
    multipass list --format json |
      jq '
        {
          "multipass": {
            "hosts": [
              .list[]
              | select(.state == "Running")
              | select((.ipv4 // []) | length > 0)
              | .name
            ]
          },
          "_meta": {
            "hostvars": (
              [
                .list[]
                | select(.state == "Running")
                | select((.ipv4 // []) | length > 0)
                | {
                    key: .name,
                    value: {
                      "ansible_host": .ipv4[0],
                      "ansible_user": "ubuntu",
                      "ansible_become": true
                    }
                  }
              ]
              | from_entries
            )
          }
        }
      '
    ;;

  --host)
    # _meta.hostvars above already supplies every host's variables.
    echo '{}'
    ;;

  *)
    echo "Usage: $0 --list | --host <hostname>" >&2
    exit 1
    ;;
esac
