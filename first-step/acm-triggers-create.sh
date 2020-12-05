cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: default
  labels:
    app: triggers  
---
apiVersion: apps.open-cluster-management.io/v1
kind: Channel
metadata:
  name: triggers
  namespace: default
  labels:
    app: triggers
spec:
  type: GitHub
  pathname: https://github.com/simonDelordtest/triggers.git
---
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: local-cluster
  namespace: default
  labels:
    app: triggers 
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
  name: triggers
  namespace: default
  labels:
    app: triggers 
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
      - triggers
---
apiVersion: apps.open-cluster-management.io/v1
kind: Subscription
metadata:
  name: triggers
  namespace: default
  labels:
    app: triggers
  annotations:
      apps.open-cluster-management.io/github-path: 
spec:
  channel: default/triggers
  placement:
    placementRef:
      kind: PlacementRule
      name: local-cluster
      apiGroup: apps.open-cluster-management.io     
EOF
