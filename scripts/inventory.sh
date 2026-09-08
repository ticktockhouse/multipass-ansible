#!/usr/bin/env bash
set -euo pipefail

multipass list --format json |
jq -r '
  {
    all: {
      children: {
        multipass: {
          hosts: (
            .list
            | map(
                select(.state == "RUNNING")
                | {
                    (.name): {
                      ansible_host: .ipv4[0],
                      ansible_user: "ubuntu",
                      ansible_become: true
                    }
                  }
              )
            | add
          )
        }
      }
    }
  }
' | yq -P
