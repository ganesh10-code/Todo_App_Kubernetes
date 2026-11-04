# Run from the project root in Windows PowerShell.
# Prerequisites: Docker, kubectl, Minikube. Start Docker Desktop first.
$ErrorActionPreference = "Stop"

# 1. Start local Kubernetes cluster
minikube start --driver=docker
kubectl config current-context
kubectl get nodes

# 2. Build and load v1 and v2 images into Minikube
minikube image build -t todo-app:v1 --build-arg APP_VERSION=v1 -f Dockerfile .
minikube image build -t todo-app:v2 --build-arg APP_VERSION=v2 -f Dockerfile .
minikube image ls | Select-String "todo-app"

# 3. Deploy three replicas and Service
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/todo-app --timeout=120s
kubectl get deployments,replicasets,pods,services -o wide
minikube service todo-app --url

# 4. Verify v1 via browser (open the URL printed above) and collect baseline evidence
kubectl get pods -o wide
kubectl describe deployment todo-app
kubectl get events --sort-by=.metadata.creationTimestamp

# 5. Rolling update v1 -> v2; measure elapsed time
$sw = [System.Diagnostics.Stopwatch]::StartNew()
kubectl set image deployment/todo-app todo-app=todo-app:v2
kubectl rollout status deployment/todo-app --timeout=120s
$sw.Stop()
"Rolling update elapsed seconds: {0:N2}" -f $sw.Elapsed.TotalSeconds
kubectl rollout history deployment/todo-app
kubectl get rs,pods -o wide

# 6. Deliberately failed update. This image tag intentionally does not exist.
# maxUnavailable: 0 should preserve the old available replicas while new pod fails.
$sw = [System.Diagnostics.Stopwatch]::StartNew()
kubectl set image deployment/todo-app todo-app=todo-app:does-not-exist
Start-Sleep -Seconds 15
kubectl get pods
kubectl describe deployment todo-app
kubectl describe pods
kubectl get events --sort-by=.metadata.creationTimestamp
$sw.Stop()
"Failed update observation window seconds: {0:N2}" -f $sw.Elapsed.TotalSeconds
# The rollout status command may time out because the new ReplicaSet cannot become ready.
kubectl rollout status deployment/todo-app --timeout=20s

# 7. Roll back to the last working revision; measure elapsed time
$sw = [System.Diagnostics.Stopwatch]::StartNew()
kubectl rollout undo deployment/todo-app
kubectl rollout status deployment/todo-app --timeout=120s
$sw.Stop()
"Rollback elapsed seconds: {0:N2}" -f $sw.Elapsed.TotalSeconds
kubectl get deployment,rs,pods -o wide
kubectl rollout history deployment/todo-app

# 8. Delete one pod and observe self-healing; measure recovery time
$pod = kubectl get pods -l app=todo-app -o jsonpath="{.items[0].metadata.name}"
"Deleting pod: $pod"
$sw = [System.Diagnostics.Stopwatch]::StartNew()
kubectl delete pod $pod
kubectl wait --for=condition=Ready pod -l app=todo-app --timeout=120s
$sw.Stop()
"Pod recovery elapsed seconds (until selected pods Ready): {0:N2}" -f $sw.Elapsed.TotalSeconds
kubectl get pods -l app=todo-app -o wide
kubectl get events --sort-by=.metadata.creationTimestamp

# 9. Monitoring. Metrics require metrics-server to be available.
kubectl top pods
kubectl top nodes
kubectl get pods -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount"
# Replace <pod-name> with a real pod name:
# kubectl logs <pod-name> -c todo-app
# For a pod-level event trail:
# kubectl describe pod <pod-name>

# 10. Optional cleanup after collecting all evidence
# kubectl delete -f k8s/
