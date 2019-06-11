#!/bin/bash

# NOTE: this is a direct copy of README.md and meant to be up-to-dated
# accordingly

# 1. Create a GCE cluster with CustomResourceWebhookConversion feature enabled

#MASTER_SIZE=n1-standard-4 KUBE_FEATURE_GATES="ExperimentalCriticalPodAnnotation=true,CustomResourceWebhookConversion=true" KUBE_UP_AUTOMATIC_CLEANUP=true $GOPATH/src/k8s.io/kubernetes/cluster/kube-up.sh

# 2. Create a secret containing a TLS key and certificate

hack/webhook-create-signed-cert.sh \
    --service admission-webhook-service.default.svc \
    --secret admission-webhook-tls-certs \
    --namespace default

# 3. Create a CRD with the caBundle correctly configured from the TLS certificate

cat artifacts/validating-template.yaml | hack/webhook-patch-ca-bundle.sh --secret admission-webhook-tls-certs > artifacts/validating-webhook.yaml
kubectl apply -f artifacts/validating-webhook.yaml

cat artifacts/mutating-template.yaml | hack/webhook-patch-ca-bundle.sh --secret admission-webhook-tls-certs > artifacts/mutating-webhook.yaml
kubectl apply -f artifacts/mutating-webhook.yaml

# 4. Create a conversion webhook that uses the TLS certificate and key

kubectl apply -f artifacts/admission-pod.yaml
kubectl apply -f artifacts/admission-service.yaml

# Wait a few seconds for endpoints to be available for service
sleep 10

# 5. TODO: test with some simple pods
