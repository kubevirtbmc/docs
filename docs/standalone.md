# Standalone Mode

Besides the controller-managed deployment, the virtbmc agent can run as a self-contained binary. In standalone mode the agent talks to the Kubernetes API directly with a kubeconfig you provide — no `VirtualMachineBMC` CRD, no controller, and no cert-manager are required.

One process manages exactly one VirtualMachine.

## When to Use It

- Development and debugging against a live cluster from your workstation
- Lab environments where installing the CRD/controller is not an option
- CI setups (e.g. Metal3-style provisioning flows) that only need IPMI/Redfish endpoints in front of existing VMs

If you need multiple BMCs, lifecycle automation, or Service exposure inside the cluster, use the [controller-managed deployment](getting-started.md) instead.

## Prerequisites

- A KubeVirt `VirtualMachine` already exists in the cluster
- A kubeconfig whose identity can manage that VM (see [RBAC](#rbac-requirements))
- [CDI](https://kubevirt.io/user-guide/storage/containerized_data_importer/) installed if you plan to use virtual media

### RBAC Requirements

The kubeconfig needs the following permissions in the VM's namespace (the `bmc.kubevirt.io` permissions used by the in-cluster agent are **not** needed in standalone mode):

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: virtbmc-standalone
rules:
  - apiGroups: ["kubevirt.io"]
    resources: ["virtualmachines"]
    verbs: ["get", "watch", "update", "patch"]
  - apiGroups: ["subresources.kubevirt.io"]
    resources: ["virtualmachines/start", "virtualmachines/stop", "virtualmachines/restart"]
    verbs: ["update"]
  - apiGroups: ["kubevirt.io"]
    resources: ["virtualmachineinstances"]
    verbs: ["get", "watch"]
  - apiGroups: ["cdi.kubevirt.io"]
    resources: ["datavolumes"]
    verbs: ["create", "delete"]
```

## Running

Build the binary:

```bash
git clone https://github.com/kubevirtbmc/kubevirtbmc.git
cd kubevirtbmc
go build -o bin/virtbmc cmd/virtbmc/main.go
```

Start the agent for VM `testvm` in namespace `default`:

```bash
export BMC_USERNAME=admin
export BMC_PASSWORD=admin123

./bin/virtbmc --standalone \
    --kubeconfig ~/.kube/config \
    --address 0.0.0.0 \
    --enable-ipmi \
    default testvm
```

The container image works too. Mount both the kubeconfig and a writable state
directory; IPMI needs host networking since it is UDP:

```bash
docker run --rm --network host \
    --user "$(id -u):$(id -g)" \
    -e BMC_USERNAME=admin -e BMC_PASSWORD=admin123 \
    -v "$HOME/.kube/config:/kubeconfig:ro" \
    -v "$PWD:/state" \
    kubevirtbmc/virtbmc:latest \
    --standalone \
    --kubeconfig /kubeconfig \
    --state-file /state/default_testvm.json \
    --enable-ipmi \
    default testvm
```

Then use it like any other BMC:

```bash
# IPMI
ipmitool -I lanplus -H 127.0.0.1 -p 10623 -U admin -P admin123 power status

# Redfish
curl -u admin:admin123 http://127.0.0.1:10080/redfish/v1/Systems/1
```

## Flags

| Flag | Default | Description |
|---|---|---|
| `--standalone` | `false` | Enable standalone mode |
| `--kubeconfig`, `-k` | `/root/.kube/config` | Kubeconfig file used to reach the cluster |
| `--address`, `-a` | `127.0.0.1` | Listen address |
| `--redfish-port` | `10080` | Redfish listen port |
| `--ipmi-port` | `10623` | IPMI listen port |
| `--enable-ipmi` | `false` | Enable the IPMI simulator |
| `--state-file` | `./<ns>_<vm>.json` | Where boot override state is persisted |
| `--storage-class` | cluster default | StorageClass for virtual media DataVolumes |
| `--volume-mode` | CDI default | Volume mode for virtual media DataVolumes: `block` or `filesystem` |
| `--datavolume-size-margin` | `0` | Pad virtual media DataVolume size by this many percent (see [Volume Mode and Size Margin](virtual-media.md#volume-mode-and-size-margin)) |

Credentials are always passed via the `BMC_USERNAME` and `BMC_PASSWORD` environment variables.

## State File

The agent persists boot override state (e.g. a pending one-shot boot backup) to a local JSON file so the state survives agent restarts. By default the file is named after the managed VM in the current working directory, e.g. `./default_testvm.json`, which keeps concurrent agents for different VMs from colliding. Writes are atomic (temporary file + rename). When running the container image, pass `--state-file` under a writable bind mount as shown above.

Delete the file to reset the BMC to its default boot behavior.

!!! note

    One-shot boot restore runs in-process: after a one-shot boot override is consumed (detected via the VMI UID change), the agent patches the original boot order back onto the VM itself. Keep the agent running until the VM has rebooted once, or the restore happens on the next agent start.

## Differences from Controller-Managed Mode

- No `VirtualMachineBMC` CR, Deployment, Service, or Secret is created — you reach the agent directly at `--address` and its ports
- Boot override state lives in the local state file instead of the CR status
- Virtual media settings come from flags (`--storage-class`, `--volume-mode`, `--datavolume-size-margin`) instead of the `VirtualMachineBMC` CR spec and annotations
- Nothing garbage-collects the agent; its lifecycle is yours to manage
