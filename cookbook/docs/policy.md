# MCM Compliance Manager
**Author:** Fabio Gomez (fabiogomez@us.ibm.com)

## Introduction
In the previous chapter we spoke of the complexities of managing applications across multiple clusters and how MCM takes that complexity away with its placement policies. We also covered a DevOps demo where you can get first hand experience on how easy it is to deploy an application to multiple clusters by leveraging MCM's placement policies.

What was not mentioned in the above scenario was that, outside of setting up MCM Hub Cluster and Klusterlets properlies, to get the Guestbook app to work we had to create a `Cluster Image Policy` in both clusters so they are able to download Docker images from Docker Hub and other Docker registries. This manual step may be trivial when you have just 2 clusters. However, the more granular your configuration requirements become and the more environments/clusters you have, it gets more difficult, time-consuming, and error-prone to manage cluster configuration.

Configuration management tools, such as `Chef` & `Ansible`, have existed for a while and have become imperative for managing infrastructure configuration at scale. However, at the time of writing, there is no major configuration management solution for Kubernetes native resources such as `Deployments`, `Quotas`, `Roles`, `Role Bindings`, etc.

MCM attempts to solve this with its `MCM Compliance Manager` feature, which provides a desired state-based management approach for informing and enforcing on the policy compliance of a set of clusters managed by MCM. Currently, the only Kubernetes resources that the Compliance Manager is able to manage are:
* Roles
* Roles Bindings

The goal in future versions is to be able to manage Kubernets resources such as `Namespaces`, `Quotas`, `Network Policies`, `Pod resources & image policies`, and `Istio policies`. Please checkout the [Beyond Tech Previous Features](https://github.ibm.com/IBMPrivateCloud/roadmap/blob/master/feature-specs/hcm/compliance-manager/compliance-spec.md#beyond-tech-preview-features) section in IBM Cloud Private's roadmap for more information.

Though currently we are presented with a limited selection, the fact that we can use `MCM Compliance Manager` to manage Roles and Role Bindings is paramount. By managing Roles and Role Bindings, we can ensure that the users and/or the service accounts in your ICP clusters only have the permissions they require and, therefore, prevent an all-powerful user from existing and being compromised by malicious users.

## The Basics
From a bottom-up approach, there are 3 concepts that you need to understand to make sense of the Compliance Manager's features. These concepts are:

* Template
* Policy
* Compliance

### Template
Starting at the bottom, we have `Template`. A Template defines a list of `policyRule`s that determine whether a particular Kubernetes Resource is compliant or not. These rules are basically a list of attributes that the given Kubernetes Resource must and/or must not have in order to be compliant.

To better understand a `Template`, let's look an actual YAML file for a Template of kind `RoleTemplate`:
```yaml
apiVersion: roletemplate.mcm.ibm.com/v1alpha1
kind: RoleTemplate
complianceType: "musthave" # at this level, it means the role must exist with the rules that it musthave below
metadata:
  namespace: "" # will be inferred
  name: operator
rules:
  - complianceType: "musthave" # at this level, it means if the role exists the rule is a musthave
    policyRule:
      apiGroups: ["extensions", "apps"]
      resources: ["deployments"]
      verbs: ["get", "list", "watch", "delete"]
  - complianceType: "mustnothave" # at this level, it means if the role exists the rule is a mustnothave
    policyRule:
      apiGroups: ["core"]
      resources: ["pods"]
      verbs: ["create", "update", "patch"]
  - policyRule:
      apiGroups: ["core"]
      resources: ["secrets"]
      verbs: ["get", "watch", "list", "create", "delete", "update", "patch"]
```

Here is a breakdown of the fields above:

* **apiVersion**: The path where the custom API is defined.
* **kind**: Defines the template kind, which is `RoleTemplate` in this case.
* **complianceType**: This field determines whether the resource (`Role` in this case) that matches the given `rules` must exist or not.
	+ `musthave`: Means that the resource with the matching `rules` must exist.
	+ `mustnothave`: Means that the resource with the matching `rules` must NOT exist.
* **metadata**:
	+ **namespace**: The Kubernetes namespace for the template.
	+ **name**: The name of the template.

Note that the above fields are specific to `Template`s in general. The following fields are specific to `RoleTemplate`:

* **rules**: List of rules (`policyRule` in this case) that will determine the compliance of a resource (`Role` in this case).
	+ **complianceType**: `musthave` or `mustnothave`. Similar to a Template's higher level `complianceType`, this field determines whether the rule inside the template must exist or not.
	+ **policyRule**: This is the actual compliance rule, which is defined by the fields below:
		- **apiGroups**: Array of API Groups to apply this rule against.
		- **resources**: Array of Resources from API Groups mentioned above to apply this rule against.
		- **verbs**: Array of verbs that apply to the API Groups and Resources mentioned above.

The contents of the templates will vary based on the target Kubernetes resource. But just know that the contents of a template is what defines the rules that Compliance Manager will be checking for in order to meet compliance.

A **Template** is the most important concept to grasp correctly as everything that follows revolves around it. But don't worry, it's all downhill from here.

### Policy
Now that we understand what a `Template` is, it will be much easier to explain what a `Policy` is. A `Policy` is responsible for the following:
* Take a list of `Template`s and enforce their rules in a cluster.
* Determine which namespaces to enforce the rules into.
* Determine what remediation action to take when compliance is not met.

To better understand a `Policy`, let's look an actual YAML file for a Policy object:
```yaml
apiVersion: policy.mcm.ibm.com/v1alpha1
kind: Policy
metadata:
  name: policy02
  description: Instance descriptor for policy resource
spec:
  remediationAction: "enforce" # or inform
  namespaces:
    include: ["default"]
    exclude: ["kube*"]
  role-templates:
    - kind: RoleTemplate
      apiVersion: roletemplate.mcm.ibm.com/v1alpha1
      complianceType: "musthave" # at this level, it means the role must exist with the rules that it musthave below
      metadata:
        namespace: "" # will be inferred
        name: operator
      rules:
        - complianceType: "musthave" # at this level, it means if the role exists the rule is a musthave
          policyRule:
            apiGroups: ["extensions", "apps"]
            resources: ["deployments"]
            verbs: ["get", "list", "watch", "delete"]
        - complianceType: "mustnothave" # at this level, it means if the role exists the rule is a mustnothave
          policyRule:
            apiGroups: ["core"]
            resources: ["pods"]
            verbs: ["create", "update", "patch"]
        - policyRule:
            apiGroups: ["core"]
            resources: ["secrets"]
            verbs: ["get", "watch", "list", "create", "delete", "update", "patch"]
```

Here is a breakdown of the fields above:

* **apiVersion**: The path where the custom API is defined.
* **kind**: `Policy` in this case.
* **spec**:
	+ **remediationAction**: this is where you specify what you would like the Compliance Manager to do when there is a non-compliance for the given Policy. Here are the options:
		+ `enforce`: If non-compliance is found, enforce policy by creating/deleting the resources in `role-templates`.
		+ `inform`: If non-compliance is found, don't enforce policy but inform the MCM Admin of the non-compliance via the Dashboard.
	+ **namespaces**: These are the namespaces where the policies will be inforced in.
		**include**: Array or expression of namespaces to INCLUDE in the policy checks.
		**exclude**: Array or expression of namespaces to EXCLUDE in the policy checks.
	+ **role-templates**: List of Templates (`RoleTemplates` in this case), which contain the rules to enforce.

Note that, we skipped `role-templates` as we already broke down and explained the contents of a Template. The only comment to add is that the templates' namespace will be inherited from the Policy's `namespaces` field.

### Compliance
We now understand that a `Template` defines the rules to enforce and a `Policy` defines how and where (namespaces) the rules are enforced in a cluster. However, a `Policy` must still be a applied to each cluster. Applying the policies manually may be fine for 1 or 2 clusters. But once again, the more abundant and more granular the policies become and the more clusters you have to manage, the more cumbersome managing the policies become.

Luckily, the Compliance Manager can manage this for you with a `Compliance` object. A `Compliance` object takes a list of `Policy` objects (and their respective `Template`s) and determines what clusters to apply them to based on cluster selectors. A `Compliance`, though not apparent by its name alone, is the final piece that ties the policies into the actual infrastructure (clusters) and, therefore, fully implement Compliance.

To better understand a `Compliance`, let's look an actual YAML file for a Compliance object, which contains 2 Policy objects:
```yaml
apiVersion: compliance.mcm.ibm.com/v1alpha1
kind: Compliance
metadata:
  name: compliance1
  namespace: mcm
  description: Instance descriptor for compliance resource
spec:
  clusterSelector:
    matchNames:
    - "se-stg-31"
    - "se-dev-31"
#    matchLabels:
#      cloud: "IBM"
#      hippa: "true"
#    matchExpressions:
#    - key: key1
#      operator: "NotIn"
#      values:
#      - "cl3"
#      - "cl4"
#    matchConditions:
#    - type: "OK"
#      status: "True"
  runtime-rules:
    - apiVersion: policy.mcm.ibm.com/v1alpha1
      kind: Policy
      metadata:
        name: policy01
        description: Instance descriptor for policy resource
      spec:
        remediationAction: "inform" # or inform
        namespaces:
          include: ["default"]
          exclude: ["kube*"]
        role-templates:
          - kind: RoleTemplate
            apiVersion: roletemplate.mcm.ibm.com/v1alpha1
            complianceType: "musthave" # at this level, it means the role must exist with the rules that it musthave below
            metadata:
              namespace: "" # will be inferred
              name: dev
            selector:
              # matchLabels:
              # hipaa: "true"
            rules:
              - complianceType: "musthave" # at this level, it means if the role exists the rule is a musthave
                policyRule:
                  apiGroups: ["extensions", "apps"]
                  resources: ["deployments"]
                  verbs: ["get", "list", "watch", "create", "delete","patch"]
    - apiVersion: policy.mcm.ibm.com/v1alpha1
      kind: Policy
      metadata:
        name: policy02
        description: Instance descriptor for policy resource
      spec:
        remediationAction: "enforce" # or inform
        namespaces:
          include: ["default"]
          exclude: ["kube*"]
        role-templates:
          - kind: RoleTemplate
            apiVersion: roletemplate.mcm.ibm.com/v1alpha1
            complianceType: "musthave" # at this level, it means the role must exist with the rules that it musthave below
            metadata:
              namespace: "" # will be inferred
              name: operator
            selector:
              matchLabels:
                hipaa: "true"
            rules:
              - complianceType: "musthave" # at this level, it means if the role exists the rule is a musthave
                policyRule:
                  apiGroups: ["extensions", "apps"]
                  resources: ["deployments"]
                  verbs: ["get", "list", "watch", "delete"]
              - complianceType: "mustnothave" # at this level, it means if the role exists the rule is a mustnothave
                policyRule:
                  apiGroups: ["core"]
                  resources: ["pods"]
                  verbs: ["create", "update", "patch"]
              - policyRule:
                  apiGroups: ["core"]
                  resources: ["secrets"]
                  verbs: ["get", "watch", "list", "create", "delete", "update", "patch"]
```

The above may look overwhelming, but outside a few fields specific to the `Compliance` object, there is nothing we haven't already seen above. Here is a breakdown of the fields above:

* **apiVersion**: The path where the custom API is defined.
* **kind**: `Compliance` in this case.
* **metadata**: The common Kubernetes metadata object. There are a couple of fields that are of interest for Compliance Manager.
	+ **namespace**: This is the name of the namespace that was created specifically for MCM to put Compliance objects during MCM installation.
	+ **description**: Description of the Compliance object, which will be displayed in the MCM Dashboard.
* **spec**:
	+ **clusterSelector**: Here is where we define the criteria to select the clusters where the policies will be applied and/or enforced. You can use a combination of the following filters to select clusters:
		- **matchNames**: List of cluster names to match against.
		- **matchLabels**: List of cluster labels to match against. These are the labels which fields you for a cluster during Klusterlet installation.
		- **matchExpressions**: List of expressions to match against.
		- **matchConditions**: List of cluster conditions to match against, usually involving cluster health status.
	+ **runtime-rules**: This is a list of `Policy` objects that will be applied to the clusters that match the criteria in `clusterSelector`.

Once again, the `Compliance` object is responsible for applying the specified `Policy` objects to the matching clusters and reporting status back to the Compliance Manager dashboard in MCM.

## Compliance Manager Tutorial
Now that we know the basic concepts and understand on a high level the components that power the Compliance Manager, let's go ahead and apply a sample Compliance object to our clusters and see what that looks like on the Compliance Manager dashboard.

### Pre-requisites
This tutorial will assume you have the following pre-requisites:

* **2 IBM Cloud Private 3.1 Clusters loaded with the MCM 3.1.1 PPA loaded**
* **Cluster 1 Setup**:
	+ **Install MCM Controller Chart**
		- Create a separate namespace called `mcm`, which will be used to store the `Compliance` objects.
	+ **Install MCM Klusterlet Chart and enter the following values:**
		- **Name**: se-stg-31
		- **Namespace**: mcm-se-stg
		- **Labels**:
			* **cloud**: IBM
			* **datacenter**: dallas
			* **environment**: Staging
			* **owner**: case
			* **region**: US
			* **vendor**: ICP
* **Cluster 2 Setup**:
	+ **Install MCM Klusterlet Chart and enter the following values:**
		- **Name**: se-dev-31
		- **Namespace**: mcm-se-dev
		- **Labels**:
			* **cloud**: IBM
			* **datacenter**: austin
			* **environment**: Dev
			* **owner**: case
			* **region**: US
			* **vendor**: ICP

### 1. Apply the Compliance
Now that we have installed MCM in both clusters, let's create a `Compliance` object located at [cookbook/docs/demos/compliance/compliance-v0.2.yaml](demos/compliance/compliance-v0.2.yaml). Here is a high level breakdown of the contents of the `Compliance` object:

* A cluster selector that uses `matchNames` to select clusters matching the names listed.
* A `Policy` that only `inform`s whether compliance is met based on the policy's `RoleTemplate`.
	+ This means the roles in the `RoleTemplate` won't be created by the Policy even if the cluster is found non-compliant.
* A `Policy` that `enforce`s the creation of the policy's `RoleTemplate` if the cluster is found non-compliant.
	+ This means that even if the cluster was found compliant and, for some reason, a cluster admin deletes the role, the Compliance Manager will recreate it.

Let's proceed with the `Compliance` object creation. If your cluster names are different to the ones mentioned in the previous section, make sure to open the compliance file and change the cluster names in lines [12](demos/compliance/compliance-v0.2.yaml#L12) and [13](demos/compliance/compliance-v0.2.yaml#L13) to be the names of your clusters as indicated when installing the Klusterlet, then save the file.
```bash
# Login against MCM Hub Cluster
cloudctl login -a https://${MCM_HUB_CLUSTER_MASTER_IP}:8443 -u ${USERNAME} -p ${PASSWORD} -n mcm --skip-ssl-validation;

# Clone the repo
git clone git@github.ibm.com:CASE/refarch-mcm.git

# Cd to repo folder
cd refarch-mcm

# Apply the Compliance
kubectl apply -f cookbook/docs/demos/compliance/compliance-v0.2.yaml
```

Where:

* `${MCM_HUB_CLUSTER_MASTER_IP}` is the IP Address of the master node in the MCM Hub Cluster.
* `${USERNAME}` is admin user.
* `${PASSWORD}` is the admin password.
* `mcm` is the namespace in which the `Compliance` object will be created.

In the next section, we will use the MCM Compliance Manager dashboar to see the compliance results of the above `Compliance` object.

### 2. View Compliance Status on the Dashboard
To access the Policies view for the Compliance Manager, open a new browser window and go to https://${MCM_HUB_CLUSTER_MASTER_IP}:8443/multicloud/policies, where `${MCM_HUB_CLUSTER_MASTER_IP}` is the IP Address of the master node in the MCM Hub Cluster.

If the `Compliance` object was created successfully, you wil see a screen that looks like this:
![1. Compliance](images/policy/1-mcm-compliance.png?raw=true)

Notice that under `Policy Compliant` only 2 out of 4 created policies are compliant, which means for both clusters only 1 of the policies is actually compliant. Because of this, none of the clusters are 100% compliant, as indicated by the `0/2` value under `Cluster Compliant` column.

Now click on `compliance1` to see more details on the `Compliance` object. The first thing you will see are some high level details for the `Compliance`, which are similar to what we saw in the previous screenshot:
![2. Compliance Details - 1](images/policy/2-mcm-compliance-details-1.png?raw=true)

If you scroll further down you can see the following 2 sections:
![3. Compliance Details - 2](images/policy/3-mcm-compliance-details-2.png?raw=true)

Here is a breakdown of the above 2 sections:

* **Compliance Status**: The overall compliance status of an individual cluster.
	+ **Cluster Name**: The name of the cluster.
	+ **Policy Compliant**: Ratio of compliant policies to total number of policies.
	+ **Policy Valid**: Ratio of policies with valid syntax to total number of policies.
* **Compliance Policies**: A breakdown of all the policies and their compliance status for each cluster .
	+ **Compliant**: Whether the given policy is compliant.
	+ **Name**: Name of the policy.
	+ **Cluster Name**: Name of the cluster that this policy belongs to.
	+ **Valid**: Whether the policy has a valid syntax.

The above should give you a high level idea of the compliance status for each policy in each cluster.

### 3. View Individual Policy
The above section showed us how to get a high level compliance status for each policy on each cluster. If we want to investigate, for example, what exactly causing the policies to show a non-compliant status, the we have to inspect the contents of the policy itself.

To view the contents of any policy, click the name of the policy in the `Compliance Policies` section shown in the last screenshot. For this example, we are going to click on `policy01` from the `se-dev-31` cluster.

You shold now be greeted with the following screen, which gives you the high level policy details, which gives you the Compliance `Status` (which is `NonCompliant`) and the `Enforcement` type (which is `inform)`:
![4. Policy Details - 1](images/policy/4-mcm-policy-details-1.png?raw=true)

If you scroll down, you will encounter the `Template Details` and the `Rules` sections:
![5. Policy Details - 2](images/policy/5-mcm-policy-details-2.png?raw=true)

Here is a breakdown of the above 2 sections:

* **Template Details**:
	+ **Name**: Name of the template, which is `dev` in this case.
	+ **Last Transition**: The compliance status change for the template.
	+ **Template Type**: The type of template, which is `role-template` in this case.
* **Rules**:
	+ **Name**: The name of the rule, which was auto-generated in this case to be `dev-rule-0`
	+ **Template Type**: The type of template, which is `role-template` in this case.
	+ **Compliance Type**: This field determines whether the resource (`Role` in this case) that matches the given `rules` must exist or not, which in this case must exist based on its `musthave` value.
	+ **API Groups**: Array of API Groups to apply this rule against.
	+ **Verbs**: Array of verbs that apply to the API Groups and Resources.
	+ **Resources**: Array of Resources from API Groups mentioned above to apply this rule against.

### Conclusion
Though this tutorial did not go into extreme detail on all possible `Compliance`, `Policy`, and `Template` iterations and compliance scenarios (which are left for the reader to experiment with), it did cover the basics on how to apply policies to clusters using `Compliance` objects.

The tutorial also covered how you can access the Compliance Manager dashboard to view the compliance status of all the policies and how to inspect non-compliant policies to understand the rules inside the policy templates.

The more you use the Compliance Manager and implement `Compliance` objects into more clusters, the easier it becomes to maintain increasingly complicated configurations across multiple clusters.

<!--## Short End-to-End Video Demo
If you would like to see a more involved demo or prefer a video tutorial format, then feel free to checkout this video that was put together by the MCM Compliance Manager team.
[![Watch the video](images/policy/video-demo-screenshot.png)](https://COMING_SOON)-->