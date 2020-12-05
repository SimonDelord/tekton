cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: default
  labels:
    app: pipelines   
---
apiVersion: apps.open-cluster-management.io/v1
kind: Channel
metadata:
  name: pipelines
  namespace: default
  labels:
    app: pipelines
spec:
  type: GitHub
  pathname: https://github.com/simonDelordtest/pipelines.git
---
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: local-cluster
  namespace: default
  labels:
    app: pipelines 
spec:
  clusterConditions:
  - status: "True"
    type: ManagedClusterConditionAvailable
  clusterSelector:
    matchExpressions: []
    matchLabels:
      name: local-cluster
---
apiVersion: app.k8s.io/v1beta1
kind: Application
metadata:
  name: pipelines
  namespace: default
  labels:
    app: pipelines 
spec:
  componentKinds:
  - group: apps.open-cluster-management.io
    kind: Subscription
  descriptor: {}
  selector:
    matchExpressions:
    - key: app
      operator: In
      values:
      - pipelines
---
apiVersion: apps.open-cluster-management.io/v1
kind: Subscription
metadata:
  name: pipelines
  namespace: default
  labels:
    app: pipelines
  annotations:
      apps.open-cluster-management.io/github-path:   
spec:
  channel: default/pipelines
  placement:
    placementRef:
      kind: PlacementRule
      name: local-cluster
      apiGroup: apps.open-cluster-management.io     
EOF
