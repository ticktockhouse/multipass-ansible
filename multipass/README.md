# multipass provisioner script

This script is create-only/idempotent-ish:

- If a named instance exists, it does nothing.
- If it is absent, it launches it.
- It does not resize or recreate existing VMs when the JSON changes.

That last point is intentional. Changes to a Multipass launch spec do not automatically reconcile a running VM. For immutable lab VMs, delete and recreate the specific VM:

```bash
bash
multipass delete web-01
multipass purge
scripts/apply-multipass.sh
```

## Cloud-init remains YAML

Use YAML for the guest’s first-boot configuration, because Multipass’s --cloud-init input is cloud-init user-data in YAML form. It can supply a filename or URL and applies that configuration on first boot.

Keep it deliberately small: SSH bootstrap, Python, perhaps package-cache updates. Let Ansible do the actual desired-state configuration.
