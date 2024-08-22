argo_passwd=$(kubectl get secret -n argocd argocd-initial-admin-secret -ojsonpath='{.data.password}' | base64 --decode)
argocd login --insecure --username "admin" --password $argo_passwd 127.0.0.1:8081