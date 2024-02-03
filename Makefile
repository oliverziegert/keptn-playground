LFC_NAMESPACE ?= keptn-system
PODTATO_NAMESPACE ?= podtato-kubectl
ARGO_NAMESPACE ?= argocd
# renovate: datasource=github-tags depName=argoproj/argo-cd
ARGO_VERSION ?= v2.9.3
ARGO_SECRET = $(shell kubectl -n ${ARGO_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)
GRAFANA_USER = $(shell kubectl -n prometheus get secret prometheus-grafana -o jsonpath="{.data.admin-user}" | base64 -d; echo)
GRAFANA_SECRET = $(shell kubectl -n prometheus get secret prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d; echo)

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
	@echo "--------------------------------------"
	@echo "Install "Cert-Manager" unsing ArgoCD"
	@echo "--------------------------------------"
	kubectl apply -f cert-manager.yaml -n "$(ARGO_NAMESPACE)"

.PHONY: cert-manager-uninstall
cert-manager-uninstall:
	@echo "--------------------------------------"
	@echo "Remove Cert-Manager unsing ArgoCD"
	@echo "--------------------------------------"
	kubectl delete -f cert-manager.yaml -n "$(ARGO_NAMESPACE)" --ignore-not-found=true

.PHONY: observability-install
observability-install:
	@echo "---------------------------------------------------------"
	@echo "Install "Observability Tools" using ArgoCD"
	@echo "---------------------------------------------------------"
	kubectl apply -f observability-root.yaml -n "$(ARGO_NAMESPACE)"

.PHONY: observability-uninstall
observability-uninstall:
	@echo "---------------------------------------------------------"
	@echo "Remove "Observability Tools" using ArgoCD"
	@echo "---------------------------------------------------------"
	kubectl delete -f observability-root.yaml -n "$(ARGO_NAMESPACE)" --ignore-not-found=true

.PHONY: prometheus-install
prometheus-install:
	@echo "---------------------------------------------------------"
	@echo "Install "Prometheus and Grafana" using ArgoCD"
	@echo "---------------------------------------------------------"
	kubectl apply -f prometheus-root.yaml -n "$(ARGO_NAMESPACE)"

.PHONY: prometheus-uninstall
prometheus-uninstall:
	@echo "---------------------------------------------------------"
	@echo "Remove "Prometheus and Grafana" using ArgoCD"
	@echo "---------------------------------------------------------"
	kubectl delete -f prometheus-root.yaml -n "$(ARGO_NAMESPACE)" --ignore-not-found=true

.PHONY: opentelemetry-install
opentelemetry-install:
	@echo "---------------------------------------------------------"
	@echo "Install "Open Telemetry Operator and Collector" using ArgoCD"
	@echo "---------------------------------------------------------"
	kubectl apply -f opentelemetry-root.yaml -n "$(ARGO_NAMESPACE)"

.PHONY: opentelemetry-uninstall
opentelemetry-uninstall:
	@echo "---------------------------------------------------------"
	@echo "Remove "Open Telemetry Operator and Collector" using ArgoCD"
	@echo "---------------------------------------------------------"
	kubectl delete -f opentelemetry-root.yaml -n "$(ARGO_NAMESPACE)" --ignore-not-found=true

.PHONY: keptn-install
keptn-install:
	@echo "---------------------------------------------------------"
	@echo "Install "Open Telemetry Operator and Collector" using ArgoCD"
	@echo "---------------------------------------------------------"
	kubectl apply -f keptn-root.yaml -n "$(ARGO_NAMESPACE)"

.PHONY: keptn-uninstall
keptn-uninstall:
	@echo "---------------------------------------------------------"
	@echo "Remove "Open Telemetry Operator and Collector" using ArgoCD"
	@echo "---------------------------------------------------------"
	kubectl delete -f keptn-root.yaml -n "$(ARGO_NAMESPACE)" --ignore-not-found=true

.PHONY: port-forward-argocd
port-forward-argocd:
	@echo ""
	@echo "Open ArgoCD in your Browser: http://localhost:8080"
	@echo "CTRL-c to stop port-forward"

	@echo ""
	kubectl port-forward svc/argocd-server -n "$(ARGO_NAMESPACE)" 8080:443

.PHONY: port-forward-jaeger
port-forward-jaeger:
	@echo ""
	@echo "Open Jaeger in your Browser: http://localhost:16686"
	@echo "CTRL-c to stop port-forward"

	@echo ""
	kubectl port-forward -n "keptn-system" svc/jaeger-query 16686

.PHONY: port-forward-prometheus
port-forward-prometheus:
	@echo ""
	@echo "Open Prometheus in your Browser: http://localhost:9090"
	@echo "CTRL-c to stop port-forward"
	@echo ""
	kubectl port-forward -n prometheus svc/prometheus-kube-prometheus-prometheus 9090

.PHONY: port-forward-grafana
port-forward-grafana:
	@echo ""
	@echo "Open Grafana in your Browser: http://localhost:3000"
	@echo "CTRL-c to stop port-forward"
	@echo ""
	@echo "#######################################################"
	@echo "- Get Admin user: make grafana-get-user"
	@echo "- Get Admin password: make grafana-get-password"
	@echo "#######################################################"
	kubectl port-forward -n prometheus svc/prometheus-grafana 3000:80


.PHONY: grafana-get-user
grafana-get-user:
	@echo $(GRAFANA_USER)

.PHONY: grafana-get-password
grafana-get-password:
	@echo $(GRAFANA_SECRET)