# Spark Operator Chart Findings

The official Kubeflow Spark Operator `SparkApplication` guide states that `.spec.driver.env` and `.spec.executor.env` accept Kubernetes `EnvVar` entries, including `valueFrom.secretKeyRef`, and that `.spec.driver.envFrom` / `.spec.executor.envFrom` accept `secretRef`. It also documents `.spec.driver.secrets` and `.spec.executor.secrets` for mounted secrets. The older `envSecretKeyRefs` field is explicitly deprecated.

The imported Sedona chart currently declares three secret names under `values.yaml` but does not emit any of them in `templates/sparkapplication.yaml`; those values therefore provide no runtime authentication. Its NetworkPolicy selects only `spark-role: executor`, leaving driver pods outside the egress policy. These are source defects in the chart baseline, not proof of any live exposure because the chart remains unrenderable without approved values and is not deployed.

**Authoritative sources:**

1. [Kubeflow Spark Operator — Writing a SparkApplication](https://www.kubeflow.org/docs/components/spark-operator/user-guide/writing-sparkapplication/)
2. [Kubeflow Spark Operator — v1beta2 API documentation](https://github.com/kubeflow/spark-operator/blob/master/docs/api-docs.md)

Apache Spark’s official Kubernetes guide requires driver service-account credentials to create pods, services and ConfigMaps, and states that users need permissions to list, create, edit and delete pods. The imported Sedona chart created a ServiceAccount but no Role or RoleBinding, so the rendered job could not create executors. The remediation will add namespace-scoped RBAC for pods, services and ConfigMaps, rather than a cluster-wide or generic `edit` binding.

3. [Apache Spark — Running Spark on Kubernetes](https://spark.apache.org/docs/latest/running-on-kubernetes.html)
