# Getting Started with KubeVirtBMC

This guide will help you get KubeVirtBMC up and running in your Kubernetes cluster quickly.

## Prerequisites

- Kubernetes cluster (v1.32.0 or later)
- `kubectl` configured to access your cluster
- `helm` (v3.0+) installed (optional, only needed for Helm installation method)

## Installation

### Step 1: Install cert-manager

KubeVirtBMC requires cert-manager for webhook certificates and Redfish API TLS support.

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.2/cert-manager.yaml
```

Wait for cert-manager to be ready:

```bash
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/instance=cert-manager \
    -n cert-manager \
    --timeout=300s
```

For more information about cert-manager installation options and configuration, see the [cert-manager installation documentation](https://cert-manager.io/docs/installation/).

### Step 2: Install KubeVirt

KubeVirtBMC requires KubeVirt to be installed in your cluster.

**Install KubeVirt Operator:**

```bash
export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
echo $VERSION
kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"
```

**Verify components**


Check the deployment:

```bash
kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}"
```

Check the components:

```bash
kubectl get all -n kubevirt
```

For more information about KubeVirt installation and configuration, see the [KubeVirt quickstart guide](https://kubevirt.io/quickstart_kind/).

### Step 3: Install KubeVirtBMC

Choose one of the following installation methods:

**Option A: One-liner Installation (Recommended)**

```bash
kubectl apply -f https://github.com/kubevirtbmc/kubevirtbmc/releases/latest/download/kubevirtbmc.yaml
```

Or install a specific version:

```bash
kubectl apply -f https://github.com/kubevirtbmc/kubevirtbmc/releases/download/v0.4.1/kubevirtbmc.yaml
```

**Option B: Helm Repository**

```bash
helm repo add kubevirtbmc https://charts.zespre.com/
helm repo update
helm upgrade --install kubevirtbmc kubevirtbmc/kubevirtbmc \
    --namespace=kubevirtbmc-system \
    --create-namespace
```

**Verify Installation:**

```bash
# Check controller pod
kubectl get pods -n kubevirtbmc-system

# Verify CRD
kubectl get crd virtualmachinebmcs.bmc.kubevirt.io
```

## Create Your First Virtual BMC

### Step 1: Create a VirtualMachine

```bash
kubectl apply -f - <<EOF
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
  namespace: default
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
          interfaces:
            - name: default
              masquerade: {}
        resources:
          requests:
            memory: 64Mi
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/kubevirt/cirros-container-disk-demo
      networks:
        - name: default
          pod: {}
EOF
```

### Step 2: Create Authentication Secret

```bash
kubectl create secret generic bmc-secret \
    --from-literal=username=admin \
    --from-literal=password=admin123 \
    -n default
```

### Step 3: Create VirtualMachineBMC Resource

```bash
kubectl apply -f - <<EOF
apiVersion: bmc.kubevirt.io/v1beta1
kind: VirtualMachineBMC
metadata:
  name: test-bmc
  namespace: default
spec:
  virtualMachineRef:
    name: testvm
  authSecretRef:
    name: bmc-secret
EOF
```

### Step 4: Verify Virtual BMC Creation and all it's child component 

```bash
# Check VirtualMachineBMC 
kubectl get virtualmachinebmc test-bmc

# Verify Deployment, Pod and Service were created
kubectl get pods,services -l kubevirt.io/virtualmachinebmc-name=test-bmc
```

Expected output:
```
NAME       VIRTUALMACHINE   SECRET       CLUSTERIP       READY
test-bmc   testvm           bmc-secret   10.43.230.200   True
    
NAME                 READY   STATUS    RESTARTS   AGE
pod/testvm-virtbmc   1/1     Running   0          112s

NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/testvm-virtbmc   ClusterIP   10.43.230.200   <none>        623/UDP,80/TCP   112s
```

Additionally controller also create the [Service Account](https://kubernetes.io/docs/concepts/security/service-accounts/) and [RoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding) in the same namespace where VirtualMachineBMC object is created.


**Congratulations!** You have successfully installed KubeVirtBMC. Please continue to the [User Guide](ipmi-guide.md) to learn more about its capabilities.
