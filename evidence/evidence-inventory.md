# Evidence Inventory: Kubernetes DevOps Course-End Project

This inventory catalogs the experimental screenshots captured during the execution of the Kubernetes course-end project (**Kubernetes Deployment with Monitoring for a To-Do App**), providing verified empirical evidence extracted directly from command outputs and container runtime states.

## Summary Evidence Table

| Screenshot filename | Experiment | Actual observation | Report section |
|---|---|---|---|
| `S1-Cluster.jpg` | Step 1: Cluster Initialization & Node Verification | `minikube status` confirms control plane components (`host`, `kubelet`, `apiserver`) are Running and kubeconfig is configured. `kubectl get nodes` confirms 1 single-node cluster (`minikube`) with Status `Ready`, role `control-plane`, Age `112s`, running Kubernetes version `v1.37.0`. | Section 3 / Section 4 (Step 1) |
| `S2-Create_Deployment&services.jpg` | Step 2: Application Deployment & Service Creation | `kubectl apply` created `deployment.apps/todo-app` and `service/todo-app`. `kubectl rollout status` confirms successful rollout. `kubectl get pods` shows 3 pods (`todo-app-79cb47d867-5stst`, `bnhpl`, `npr8b`) in `1/1 Running` state with `0` restarts (ages 74s–75s). `kubectl get deployments` shows `3/3 READY`, `3 UP-TO-DATE`, `3 AVAILABLE`. `kubectl get services` verifies NodePort Service on port `80:30080/TCP` (ClusterIP: `10.96.59.15`). | Section 4 (Step 2) / Section 5 (Table 2 & Table 5) |
| `S3-Todo_application.jpg` | Step 2: Browser Verification (v1 Baseline) | Browser accessed at `http://127.0.0.1:52074` displaying "Team To-Do" web UI with `Deployment version: v1`. Interactive task list functionality demonstrated with 3 active tasks ("Complete Assignment", "Walk 10000 steps", "Solve Daily question in LC"). | Section 4 (Step 2) / Section 5 (Table 5) |
| `S4-rollout.jpg` | Step 3: Zero-Downtime Rolling Update (v1 to v2) | `kubectl set image deployment/todo-app todo-app=todo-app:v2` initiated rolling update. `kubectl rollout status` showed phased rollout (1 of 3 updated, 2 of 3 updated, old replicas terminating). `kubectl get pods` shows 3 new pods (`todo-app-74ff75b85d-2djpw`, `cv2jt`, `xvgzf`) in `1/1 Running` state (0 restarts). `kubectl get rs` shows new ReplicaSet `todo-app-74ff75b85d` (Desired: 3, Current: 3, Ready: 3) and old ReplicaSet `todo-app-79cb47d867` scaled down to 0. `kubectl rollout history` records revision 1 and revision 2. | Section 4 (Step 3) / Section 5 (Table 2, Table 5, Table 6) |
| `S5-Todo_application_v2.jpg` | Step 3: Browser Verification (v2 Rolling Update) | Browser accessed at `http://127.0.0.1:52074` showing "Team To-Do" web UI with `Deployment version: v2`. Confirms successful live traffic migration to the new container version without service disruption. | Section 4 (Step 3) / Section 5 (Table 5) |
| `S6-failed_pods(L4 analysis).jpg` | Step 4: Deliberately Failed Image Update & Fault Isolation | `kubectl get pods` shows 1 new surge pod `todo-app-67f5995897-ssd77` in `ErrImagePull` state (0/1 Ready, age 43s), while all 3 existing v2 pods (`74ff75b85d-2djpw`, `cv2jt`, `xvgzf`) remain `1/1 Running` (ages 4m39s–5m4s). `kubectl describe pod` on failing pod confirms image `todo-app:does-not-exist`, State `Waiting (ImagePullBackOff)`, Ready `False`. Proves `maxUnavailable: 0` prevented termination of healthy pods. | Section 4 (Step 4) / Section 5 (Table 3, Table 5) / Section 6 (L4 Analysis, Table 7) |
| `S7-rollback.jpg` | Step 5: Rollback Execution (`kubectl rollout undo`) | `kubectl rollout undo deployment/todo-app` executed with warning regarding `kubectl apply` last-applied annotation. Rollout status confirms successful rollout. `kubectl get pods` shows 3 v2 pods (`74ff75b85d-*`) intact and `1/1 Running` (ages ~9m, 0 restarts); failing pod terminated. `kubectl get rs` confirms failed RS `todo-app-67f5995897` scaled down to 0, and healthy RS `todo-app-74ff75b85d` maintained at 3/3/3. | Section 4 (Step 5) / Section 5 (Table 3, Table 5, Table 6) / Section 6 (L4 Analysis) |
| `S8-selfhealing.jpg` | Step 6: Pod Deletion & Autonomous Self-Healing | Baseline pods `cv2jt` (12m), `wrrfl` (13s), `xvgzf` (11m). Execution of `kubectl delete pod todo-app-74ff75b85d-cv2jt` deletes target pod. `kubectl get pods -w` captures immediate reconciliation: new pod `todo-app-74ff75b85d-rcdz4` created by ReplicaSet and observed `1/1 Running` within 9 seconds (Age: 9s). Desired count (3) fully restored. | Section 4 (Step 6) / Section 5 (Table 3, Table 5, Table 6) / Section 6 (L4 Analysis) |
| `S9-Cpu_restarts.jpg` | Step 7: Resource Metrics & Stability Verification | `kubectl top pods` reports exact resource usage: `rcdz4` (1m CPU, 7Mi RAM), `wrrfl` (1m CPU, 7Mi RAM), `xvgzf` (1m CPU, 7Mi RAM); total cluster load = 3m CPU, 21Mi RAM. Custom-columns command confirms `STATUS: Running` and `RESTARTS: 0` across all pods. `kubectl get pods` shows pod stability with ages up to 19m. | Section 4 (Monitoring) / Section 5 (Table 4) / Section 7 (L5 Evaluation, Table 8) |
| `S10-application_logs.jpg` | Step 7: Container Logging & Health Probes | `kubectl logs todo-app-74ff75b85d-rcdz4 -c todo-app` shows Nginx 1.27.5 on Alpine Linux startup, worker processes initialization (workers 30–37), and continuous HTTP 200 health probe requests (`GET / HTTP/1.1 200 1899`) from User-Agent `kube-probe/1.37` adhering to readiness (5s period) and liveness (10s period) intervals. | Section 4 (Monitoring) / Section 5 (Table 4) / Section 7 (Scorecard) |
| `S11-events.jpg` | Step 7: Cluster Event Audit Trail | `kubectl get events --sort-by=.metadata.creationTimestamp` logs chronological Kubernetes lifecycle events: Node conditions (`NodeReady`), Deployment `ScalingReplicaSet` for v1 (`79cb47d867`), scheduling (`Scheduled`), pod creation (`SuccessfulCreate`), image pull (`Pulled`), and container lifecycle (`Created`, `Started`). Also captures rollout events for v2 (`74ff75b85d-cv2jt`). | Section 4 (Monitoring) / Section 6 (L4 Analysis, Table 7) |
| `S12-deployment_description.jpg` | Step 7: Deployment Configuration & Status Inspection | `kubectl describe deployment todo-app` verifies Deployment metadata: Revision 4, 3 desired / 3 updated / 3 available / 0 unavailable, Strategy `RollingUpdate` (0 max unavailable, 1 max surge), container image `todo-app:v2`, Port 80/TCP, limits (250m CPU, 128Mi RAM), requests (50m CPU, 32Mi RAM), active probes, conditions (`Progressing: True`, `Available: True`), active ReplicaSet `todo-app-74ff75b85d` (3/3), and inactive historical ReplicaSets `79cb47d867` (0/0) and `67f5995897` (0/0). | Section 3 / Section 4 / Section 6 / Section 10 (Appendix) |

---

## Detailed Metric and Parameter Extraction

### 1. Workload Architecture & ReplicaSet Tracking
- **Deployment Name**: `todo-app` (Namespace: `default`, Selector: `app=todo-app`)
- **Revision 1 ReplicaSet**: `todo-app-79cb47d867` (Image: `todo-app:v1`, 3 replicas)
- **Revision 2 ReplicaSet**: `todo-app-74ff75b85d` (Image: `todo-app:v2`, 3 replicas)
- **Revision 3 ReplicaSet (Failed)**: `todo-app-67f5995897` (Image: `todo-app:does-not-exist`, 1 surge replica stuck in `ImagePullBackOff`)
- **Revision 4 ReplicaSet (Rollback)**: `todo-app-74ff75b85d` (Restored `todo-app:v2`, 3 replicas active; `67f5995897` scaled to 0)

### 2. Pod Lifecycle & Naming
- **v1 Initial Pods**: `todo-app-79cb47d867-5stst`, `todo-app-79cb47d867-bnhpl`, `todo-app-79cb47d867-npr8b`
- **v2 Rolled-out Pods**: `todo-app-74ff75b85d-2djpw`, `todo-app-74ff75b85d-cv2jt`, `todo-app-74ff75b85d-xvgzf`
- **Failed Pod**: `todo-app-67f5995897-ssd77` (`ErrImagePull` -> `ImagePullBackOff`, Ready: `0/1`)
- **Post-Self-Healing Pods**: `todo-app-74ff75b85d-rcdz4` (replacement for deleted `cv2jt`), `todo-app-74ff75b85d-wrrfl`, `todo-app-74ff75b85d-xvgzf`

### 3. Resource Utilization & Operational Health
- **CPU Consumption per Pod**: `1m` (0.001 core)
- **Memory Consumption per Pod**: `7Mi`
- **Total Workload Utilization (3 pods)**: `3m` CPU, `21Mi` RAM
- **Configured Requests / Limits**: Requests: `cpu: 50m`, `memory: 32Mi`; Limits: `cpu: 250m`, `memory: 128Mi`
- **Restart Count across all operational pods**: `0` restarts recorded across all experiments
- **Health Probing**: HTTP GET `/` on port 80; User-Agent: `kube-probe/1.37`; Readiness: delay 2s, timeout 2s, period 5s; Liveness: delay 5s, timeout 2s, period 10s.

### 4. Operational Timings (Measured vs. Evidenced)
- **Rolling Update**: Progressive replacement observed across ~36s–61s (individual pod ages at completion in S4: `xvgzf` 36s, `2djpw` 47s, `cv2jt` 61s); exact stopwatch millisecond timing was not captured in screenshot console output and is marked as approximate.
- **Failed Update Isolation**: 15-second observation window configured; pod in `ImagePullBackOff` observed at age 43s in S6.
- **Rollback Operation**: Near-instantaneous reconciliation to existing ReplicaSet `74ff75b85d` in under ~5–10s; screenshot S7 captures existing v2 pods running with age ~9m.
- **Self-Healing Pod Replacement**: Deleted pod `cv2jt`; replacement pod `rcdz4` reached `1/1 Running` state within **9 seconds** (evidenced by `AGE: 9s` and `READY: 1/1` in S8).

