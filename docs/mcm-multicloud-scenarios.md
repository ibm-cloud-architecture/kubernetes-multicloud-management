# Scenarios for Multi-cluster Management
## The Era of Multicloud

Author: Gang Chen (gangchen@us.ibm.com)

We are in a Multicloud arena with 8 out of 10 enterprises committing to multicloud and 71% use three or more cloud providers. Embracing Multicloud will be the end game. IBM Multicloud Manager is the enterprise-grade multicloud management solution for Kubernetes.

Many enterprises deploy multiple Kubernetes clusters on premises and in the public cloud, such as IBM Cloud™, Amazon Web Services (AWS), and Azure. You might find yourself using different vendor-supported Kubernetes releases, including IBM Cloud Private, Red Hat® OpenShift®, IBM Cloud Kubernetes Service, Amazon EKS, and Azure AKS. As each cloud provider or Kubernetes solution comes with its own tools and operations, managing a Multicloud Kubernetes environment can be overwhelming.

We summarized the top multicloud multi-cluster Kubernetes management challenges into the following 4 categories:

* Cross-cluster visibility
* Workload deployment and placement
* Compliance and Security
* Day 2 operation

## The Client Story

Let's start by walking through a client story. The acmeAir company (a fictitious airline company combining multiple real client scenarios and requirements) is adopting cloud with following key principles:

* Multi-cloud (On-prem, IBM Cloud, AWS, Azure)
* Kubernetes based container runtime
* Automated DevOps
* Security is the top priority of the adoption

acmeAir has many isolated Kubernetes clusters dedicated for different development teams and business unit (LoB). For example, they are running web and mobile consumer facing sites for the acmeair.com on IBM Cloud Private (ICP) on on-prem datacenter and ICP on AWS. While the airline booking API service is running on IBM Cloud Kubernetes Service (IKS) and ICP on AWS.

Even within the Booking API project, there are multiple Kubernetes (IKS and ICP) clusters that separate the Dev/QA from Staging/Production environment. And for High availability and Disaster Recovery consideration, acmeAir plans to deploy the production clusters in multiple cloud providers (regions). In summary, they end up having more than 12 clusters to support the various project. By adding other LoBs, the number grows.

What are Ops/SRE/Devops engineers doing with these clusters now (As-Is with or without MCM):

* Single consolidated view of all the clusters for corporate Ops team.
* Patch and upgrade many clusters and components.
* A single DevOps pipeline will build Microservices app and deployment them as builds and promote through the environment (Dev -> QA -> Staging -> Prod).
* Token Rotation. Every 30 days, access tokens stored in secrets will need to be rotated in every environment and updated in CICD build tools.
* Ops/DevOps engineer has to enforce Secrets and ConfigMaps synchronization in every cluster.
* The acmeair.com site clusters contains customer PCI data that needs to ensure compliance in staging/prod clusters.
* The booking API engine needs to handle the workload bursting situation to scale up a new auto-provisioned ICP cluster on public Cloud IaaS.
* Ops team is looking for a tool to manage multiple clusters from a single location including dashboards, command & control, deployments.
* Ops team needs to keep things in sync across clusters, so need to create/update objects only once - teams, helm catalogs used by teams etc. 
* Ops/DevOps wants single action (anything from hamburger menu in the console) to execute for a set of clusters.

This list gives you a big picture of the issues when dealing with multiple Kubernetes clusters.


## Cross-cluster Visibility

** User Story (Client needs): **

More and more clients adopt multiple-cloud strategy where they will host and operate multiple Kubernetes clusters across multiple cloud IaaS environment (including on-prem). Operators need a single management interface and utility to manage all these clusters with secure access. Operators can easily get health status of all the clusters managed including overall health condition, the key resource usage information. This function should be delivered through both a UI and CLI utility. Operators can easily add, remove and update the labels of a managed cluster.

** MCM Capability **

The current release of MCM provides the following features in cluster inventory:

* View all the managed clusters from a central location.
* Query/search clusters and Kubernetes resources based on cluster labels.
* View the health of all the clusters in a given region.
* Know how many nodes are down in all the clusters.
* View the pods in a given namespace in all development clusters.
* View (read only) the health status of pods, nodes, persistent volumes and applications running in those clusters.

## Workload Deployment and Placement

** User Story (client needs): **

Developers and Operators may want to deploy workloads (Cloud-Native apps, App modernization packages) to multiple clusters. For example, Developers or DevOps engineer would like to deploy the application Helm Chart to Dev cluster environment, and later promote it to QA environment, both through a single Catalog UI or CLI utility. The Operators often deploy workload to multiple clusters as well. In our acmeAir example, production workload needs to be deployed to 2 cloud provider clusters and ensure the consistency of the application.

Users would like to embed the multi-cluster support capability in their existing CI/CD DevOps pipeline. That way, they don't have to manage and update the different endpoint, access token and artifact repo (Helm repo) for each cluster.

Sometimes, developers and operators may need to deploy and manage the workload in a higher abstract format where several modules/Helm charts are grouped as deployment unit with dependency and other relationship built-in. Particularly, when some of the dependent components may end up in different clusters, the capability to have an abstract Application component spanning cross multiple cluster becomes very helpful.

** MCM Capability **

* Abstract Application component. This defines the representation of the common resource across clusters. This part is similar to [Kubernetes Federation V2](https://github.com/kubernetes-sigs/federation-v2) feature. MCM has more exposure in dependency management capability. As well as reflect the relationship in a visual `topology` format.
* Component placement. More information will be addressed in below section. In general, MCM can place a workload on different clusters/namespaces based on a set of selectors and criteria. This can be powerful in a multiple-clusters scenario. For example, solving the request from Air Canada, Telus.
* MCM CLI integration with CI/CD pipeline.
* Managed cross-cluster Helm repository.
* Local or Remote Helm chart deployment through multi-cluster catalog or CLI.

** Features/Gaps **

* Package and creating MCM Application is a manual process requiring knowledge of the MCM application schema. A scaffolding tool could be very helpful to package components into MCM application.
* Integrating with existing CI/CD toolchain seems rudimentary at CLI level. Perhaps a dedicated MCM plugin for Jenkins can prove useful.

## Compliance and Security

This feature is meant to address the following requests:

* How do I set consistent security policies across environments?
* Which clusters are compliant?
* How can I place workloads based on capacity and/or policy?
* How can I ensure that all the clusters are configured properly based on their desired state.

** User Story **

Operators need to ensure that the clusters are operating properly by comparing the current configuration of various resources against a desired state. And operator would like to enforce role or pod object placement within the clusters through a set of policy templates.

Let's use some examples to walk through the user story.
The acmeair.com site will be deployed to both IBM Cloud and AWS. However, only IBM Cloud is certified by the company as PCI compliant given customer payment information will be stored in the system. Thus, the policy needs to enforce the payment services can only run on Kuberentes clusters hosted in IBM Cloud.

Another example is associated with Workload deployment explained in above section. acmeair.com is planning to roll out a new feature, but they would like it to be first deployed in Dev and QA environments to run various tests. Instead of manually configuring the CI/CD pipelines with the Dev and QA environment credentials to do the deployment, DevOps engineers can simply update the MCM Application Placement Policy (explained in [MCM Applications chapter](mcm-applications.md)) with the cluster selector labels of the Dev and QA environments and MCM will take of finding the Dev and QA environments (based on the provided labels) and deploy the feature on those clusters.

** MCM capability **

* Set and enforce polices for Security, Applications and Infrastructure (Auto enforcement at cluster level).
* Check compliance against deployment parameters, configuration and policies.

## Conclusion
Multicloud is the way the industry is going right now. However, the management of multiple Kubernetes clusters across multiple cloud providers is no easy feat, as shown in the user stories above. IBM Multicloud Manager takes care of the needs in these user stories and places itself as the central location to manage Kubernetes clusters across multiple cloud providers and their workloads.

To get started learning and using MCM, checkout the [Quick Start](mcm-quickstart.md) and [MCM Applications](mcm-applications.md) chapters.