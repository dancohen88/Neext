# Neext task runner. Run `make` on its own to list the targets.

CLUSTER := neext
# Always name the cluster explicitly. Once prod exists, running against the wrong
# kubectl context could change prod by accident.
KUBECTL := kubectl --context k3d-$(CLUSTER)

# Kubernetes manifests to validate, and the version whose schemas they're checked
# against. Keep K8S_VERSION in step with the k3s image in platform/k3d/cluster.yaml.
K8S_MANIFESTS := $(wildcard platform/*.yaml)
K8S_VERSION := 1.35.5

.DEFAULT_GOAL := help
.PHONY: help lint cluster-up cluster-down cluster-status smoke

help: ## List the available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

lint: ## Check YAML formatting, then validate Kubernetes manifests against the API schema
	yamllint --strict .
	kubeconform -strict -summary -kubernetes-version $(K8S_VERSION) $(K8S_MANIFESTS)

cluster-up: ## Create the local dev cluster (skips creation if it already exists)
	@k3d cluster list $(CLUSTER) >/dev/null 2>&1 || k3d cluster create --config platform/k3d/cluster.yaml
	@$(KUBECTL) apply -f platform/namespaces.yaml
	@$(KUBECTL) get nodes

cluster-down: ## Delete the local dev cluster and its registry
	k3d cluster delete $(CLUSTER)

cluster-status: ## Show nodes, namespaces and anything unhealthy
	@$(KUBECTL) get nodes -o wide
	@$(KUBECTL) get namespaces -l app.kubernetes.io/part-of=neext
	@$(KUBECTL) get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded

smoke: ## Check a request reaches a pod through Traefik, then clean up
	@$(KUBECTL) apply -f platform/smoke-test.yaml >/dev/null
	@$(KUBECTL) -n neext-local rollout status deployment/smoke --timeout=90s
	@ok=1; for i in $$(seq 1 20); do \
	    resp=$$(curl -fs http://localhost:8080/) && echo "$$resp" | grep -q '^Hostname: smoke-' && { ok=0; break; }; \
	    sleep 1; done; \
	  if [ $$ok -eq 0 ]; then echo "✔ smoke passed: localhost:8080 → Traefik → pod"; echo "$$resp" | sed -n '1,2p'; \
	  else echo "✘ smoke failed: no response from the smoke pod"; fi; \
	  $(KUBECTL) delete -f platform/smoke-test.yaml --wait=false >/dev/null; exit $$ok
