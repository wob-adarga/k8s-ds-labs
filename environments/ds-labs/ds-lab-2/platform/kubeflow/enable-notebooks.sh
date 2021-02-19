#!/bin/bash

## see https://github.com/kubeflow/pipelines/issues/4440

kubectl -n kubeflow get profile -o go-template='{{range .items}}{{if ne .metadata.name "anonymous"}}{{.metadata.name}} {{.spec.owner.name}}{{"\n"}}{{end}}{{end}}' | \
  while read line; do
    eval set -- $line
    NAMESPACE=$1
    USER=$2
    echo "ENABLING USER $USER ($NAMESPACE)"

    kubectl apply -f - << EOM
      apiVersion: rbac.istio.io/v1alpha1
      kind: ServiceRoleBinding
      metadata:
        name: bind-ml-pipeline-nb-${NAMESPACE}
        namespace: kubeflow
      spec:
        roleRef:
          kind: ServiceRole
          name: ml-pipeline-services
        subjects:
        - properties:
            source.principal: cluster.local/ns/${NAMESPACE}/sa/default-editor
EOM

    kubectl -n $NAMESPACE get notebook -o go-template='{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | \
      while read line; do
        eval set -- $line
        NOTEBOOK=$1
        echo "ENABLING NOTEBOOK $NOTEBOOK ($USER)"

        kubectl apply -f - << EOM
          apiVersion: networking.istio.io/v1alpha3
          kind: EnvoyFilter
          metadata:
            name: add-header-${NOTEBOOK}
            namespace: ${NAMESPACE}
          spec:
            workloadLabels:
              notebook-name: ${NOTEBOOK}
            filters:
              - listenerMatch:
                  listenerType: SIDECAR_OUTBOUND
                  listenerProtocol: HTTP
                  address:
                    - ml-pipeline.kubeflow.svc.cluster.local
                  portNumber: 8888
                filterName: envoy.lua
                filterType: HTTP
                filterConfig:
                  inlineCode: |
                    function envoy_on_request(request_handle)
                      request_handle:headers():add("kubeflow-userid", "${USER}")
                    end
EOM

      done
  done
