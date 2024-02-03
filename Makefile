LFC_NAMESPACE ?= keptn-system
PODTATO_NAMESPACE ?= podtato-kubectl
ARGO_NAMESPACE ?= argocd
# renovate: datasource=github-tags depName=argoproj/argo-cd
ARGO_VERSION ?= v2.9.3
ARGO_SECRET = $(shell kubectl -n ${ARGO_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)

################################ General ################################
.PHONY: install
install: argo-install

.PHONY: uninstall
uninstall: argo-uninstall

################################ Tools ################################
.PHONY: install-tools
install-tools: cert-manager-install observability-install prometheus-install opentelemetry-install

.PHONY: uninstall-tools
uninstall-tools: cert-manager-uninstall observability-uninstall prometheus-uninstall opentelemetry-uninstall

################################ ArgoCD ################################

.PHONY: argo-install
argo-install:
	@echo "-----------------------------------"
	@echo "Create Namespace and install ArgoCD"
	@echo "-----------------------------------"
	kubectl create namespace "$(ARGO_NAMESPACE)" --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGO_VERSION)/manifests/install.yaml
	kubectl apply -n argocd -f argocd/argo_cm.yaml

	@echo ""
	@echo "-------------------------------"
	@echo "Wait for Resources to get ready"
	@echo "-------------------------------"
	kubectl wait --for=condition=available deployment/argocd-dex-server -n "$(ARGO_NAMESPACE)" --timeout=120s
	kubectl wait --for=condition=available deployment/argocd-redis -n "$(ARGO_NAMESPACE)" --timeout=120s
	kubectl wait --for=condition=available deployment/argocd-repo-server -n "$(ARGO_NAMESPACE)" --timeout=120s
	kubectl wait --for=condition=available deployment/argocd-server  -n "$(ARGO_NAMESPACE)" --timeout=120s


	@echo ""
	@echo "#######################################################"
	@echo "ArgoCD Demo installed"
	@echo "- Get Admin Password: make argo-get-password"
	@echo "- Port-Forward ArgoCD: make port-forward-argocd"
	@echo "- Get Argo CLI: https://argo-cd.readthedocs.io/en/stable/cli_installation/"
	@echo "- Configure ArgoCD CLI (needs port-forward): make argo-configure-cli"
	@echo "- Install PodTatoHead via ArgoCD: make argo-install-podtatohead"	
	@echo "#######################################################"

.PHONY: argo-configure-cli
argo-configure-cli:
	@argocd login localhost:8080 --username admin --password $(ARGO_SECRET) --insecure

.PHONY: argo-get-password
argo-get-password:
	@echo $(ARGO_SECRET)

.PHONY: port-forward-argocd
port-forward-argocd:
	@echo ""
	@echo "Open ArgoCD in your Browser: http://localhost:8080"
	@echo "CTRL-c to stop port-forward"

	@echo ""
	kubectl port-forward svc/argocd-server -n "$(ARGO_NAMESPACE)" 8080:443

.PHONY: argo-install-podtatohead
argo-install-podtatohead:
	@echo ""
	kubectl apply -f argocd/app.yaml -n "$(ARGO_NAMESPACE)" 

.PHONY: argo-uninstall
argo-uninstall:
	kubectl delete -n $(ARGO_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGO_VERSION)/manifests/install.yaml --ignore-not-found=true
	kubectl delete namespace $(ARGO_NAMESPACE) --ignore-not-found=true
	@echo ""
	@echo "##########################"
	@echo "Argo Demo deleted"
	@echo "##########################"


################################ ArgoCD Apps ################################
.PHONY: cert-manager-install
cert-manager-install:
	kubectl apply -f cert-manager.yaml -n "$(ARGO_NAMESPACE)"

.PHONY: cert-manager-uninstall
cert-manager-uninstall:
	kubectl delete -f cert-manager.yaml -n "$(ARGO_NAMESPACE)" --ignore-not-found=true

.PHONY: observability-install
observability-install:
	kubectl apply -f observability-root.yaml -n "$(ARGO_NAMESPACE)"

.PHONY: observability-uninstall
observability-uninstall:
	kubectl delete -f observability-root.yaml -n "$(ARGO_NAMESPACE)" --ignore-not-found=true

.PHONY: prometheus-install
prometheus-install:
	kubectl apply -f prometheus-root.yaml -n "$(ARGO_NAMESPACE)"

.PHONY: prometheus-uninstall
prometheus-uninstall:
	kubectl delete -f prometheus-root.yaml -n "$(ARGO_NAMESPACE)" --ignore-not-found=true

.PHONY: opentelemetry-install
opentelemetry-install:
	kubectl apply -f opentelemetry-root.yaml -n "$(ARGO_NAMESPACE)"

.PHONY: opentelemetry-uninstall
opentelemetry-uninstall:
	kubectl delete -f opentelemetry-root.yaml -n "$(ARGO_NAMESPACE)" --ignore-not-found=true