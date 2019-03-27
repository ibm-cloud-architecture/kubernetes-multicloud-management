# Day 2 - Cloud Operation
**Author:** Rafal Szypulka (rafal.szypulka@pl.ibm.com)

# Introduction

You have just configured your MCM (Multi-Cloud Manager), contenarized some applications and deployed them across multiple clusters.  All is good.  You then handed it to the customer's Business As Usual (BAU) or Operation team, but they might asked "How do we ensure that everything is running as they suppose to be?".  The traditional Operation processes and/or tools might not be suitable for the Cloud environment.

The purpose of this cookbook is to assist you in recommending the customer with operating IBM MCM, ie. the `day 2` aspects of the Journey. We can describe the journey as follow:

    Day 0: Requirements and design of the platforms
    Day 1: Platform installation and initial configuration to a working state
    Day 2: Platform is installed and ready to begin providing services
    Day 3 onwards: Maturation and the customization of services and functionality

Once MCM is deployed, the Operation team becomes a Cloud “Vendor” to their lines of business. As a Cloud Vendor, you they must manage the Cloud and its Services.

The following are some of the Operational Aspects of MCM Day2:

- [Monitoring](#monitoring)
- [Application Monitoring](#application-monitoring)
  - [Prometheus](#prometheus)
    - [Build to Manage](#build-to-manage)
    - [Exporter](#exporter)
  - [Application Performance Manager](#application-performance-manager)
- [Visualization](#visualisation)
  - [WeaveScope](#weavescope)
  - [Grafana](#grafana)
  - [Agile Service Manager](#agile-service-manager)
- [Logging](#logging)
  - [ELK](#elk)
  - [Log Analytics](#log-analytics)
- [Alerting](#alerting)
  - [Prometheus Alert](#prometheus-alert)
  - [Netcool Operation Insight](#netcool-operation-insight)
- [Notification and Collaboration](#notification-and-collaboration)
    - [ChatOps](#chatops)

Beyond day 2, there are few key areas that you might want to consider, these includes:
- [Incident and Problem Management](#incident-and-problem-management)

This chapter ends with [Related Links](#related-links).

#### Recipes, Further Education, or the professional?
As this is a cookbook, we will be describing recipes throughout this chapter.  The recipes will describe how to configure some tools.  As in cooking, you do not become a chef just by knowing a few recipes;  You need to learn more and deeper, so to complement the recipes, this chapter will provide you with links to where you might be able to learn more. As in real life, you (or your customer) might not need to cook at all, you might pay some professional to cook it for you.  So links to related SODA (Service Offering Directory Applications) offering will be provided as well. If you have the budget, choose from the SODA menu, and let the professional do it for you.

> We will highlight the recipes, further education, or the professional service links by displaying them like this.

#### CSMO
In IBM there is a special team that is dedicated in developing concepts and assets for this day 2 stuff.  The team is called Cloud Service Management and Operation (CSMO).  The team has created a [CSMO field guide](https://www.ibm.com/cloud/garage/content/culture/csmo-field-guide/) targeted for executives. There is even a customer facing [Video on Reinvent your operations for the cloud](https://www.youtube.com/watch?v=ZnGzUHmcZRo&feature=youtu.be) created to introduce the CSMO way of thinking.  You can also find the [Reference Architecture](https://www.ibm.com/cloud/garage/architectures/serviceManagementArchitecture) on Service management for IT and cloud services.

# Monitoring
When MCM is deployed, the Open Source monitoring tool, Prometheus, and visualization software Grafana, are installed. This combination provides immediate monitoring of the MCM deployment infrastructure components. The Grafana Dashboards that are supplied provide various views of the time-series data collected by Prometheus.

For MCM, Phometheus is configured in a federated structure.  There is a Federated Prometheus server that get data from the local Prometheus server in each cluster. Please click this [Federated Prometheus](./Ch8/FederatedPrometheus.md) link if you want to know more about it.

Here is the first simple recipe, how to configure more grafana dashboard using the out of the box MCM tools.

> [Recipe-8-1-1](./Ch8/Re-8-1-1-MoreGrafana.md) : How to configure more grafana dahsboard.

# Application Monitoring
During customer interactions done as part of `Cloud Readiness` on the topic of monitoring, one thing comes out: the customer care more about the health of their Application that they run on the cloud rather than the health of infrastructure itself.  When they want to know about the health of their cloud infrastructure, it is to ensure that the application has enough resources to perform its function.

In some of the conversation with the customer of Cloud hosted application they even mentioned that they did not want to actively monitor the cloud infrastructure, as the Cloud Provider had already provided a certain Service Level Agreement (SLA).  They realised though, while they can depend on the Cloud Provider to guarantee the health of the infrastructure, they need help in ensuring the health of the Application that run on the infrastructure.  When the application is having problems, they might need a tool to verify the performance of the infrastructure.

## Federated Prometheus
MCM comes with federated prometheus and grafana pre-configured.  MCM comes with out of the box dashboard that shows the health of MCM and the basic metrics of he application deployed across the cluster.

This section describes MCM [Federated Prometheus](https://github.ibm.com/rafal-szypulka/mcm-monitoring/blob/master/Multi%20Cloud%20Manager%20-%20monitoring.md) in more detail.

Once the initial deployment of MCM is completed, one of the thing that the customer will want is a dashboard that is application/service centric, with metrics that is important for that application. Rather than Infrastructure at the highest level summary of their dashboard they will want their Service to be at the high level dashboard, with the ability to drill down to components that support or made up that Service.

To implement this Service or Application centric dashboard, a few things need to be done:
1. The application itself need to expose their metric.  ie. the concepts of build to manage.
2. This metric need to be collected, processed and displayed.  We can either extends or create a new instance of the Grafana or Prometheus that is already available.
3. As part of the processing of the metrics, we need to build some modelling or topology that describe the relationship between the component that made up an application or service.  This can either be manually build or extracted from the provisioning component of MCM.

Let us illustrate this by a use case where we need to monitor an application.
We can either use the platform-provided monitoring tools, or we can create a package of our own Prometheus and Grafana containers.  For this use case let us build our own Prometheus and Grafana containers.

### Build to manage.
Prometheus collects metrics from monitored systems by "scraping" metrics on the  HTTP endpoints of these systems.  In Prometheus terms, we call the things that Prometheus monitors are called Targets. The Prometheus server scrapes targets at a defined interval and store them in a time-series database. The targets to be scraped and the time-interval for scraping metrics is defined in the `prometheus.yml` configuration file.

![](./Ch8/images/prometheus_target.png)

Most likely the existing application does expose the metrics this way. We need to modify the application to expose the metrics. In CSMO this concept is called `Build to Manage`. Prometheus provides client-libraries in a number of languages.

The following recipe shows how to add Prometheus client to expose metrics off your application so it can be monitored by Prometheus.

> [Recipe-8-2-1](./Ch8/Re-8-2-1-Prometheus_Instrumentation.md) : Prometheus Instrumentation.

Information on build to manage can be found further in part of the CSMO education material found here:

> [Education CSMO Foundations](https://www.onlinedigitallearning.com/course/view.php?id=3522)

If your customer needs professional service there are some service offering available here:

> [SODA Build to Manage - Strategy Design Workshop](https://soda.w3ibm.mybluemix.net/show/836)

### Exporter
If the application can not be modified then another way of getting the data is use something called `Exporters`. An Exporter is a piece of software that gets existing metrics from a third-party system and export them to the metric format that the Prometheus server can understand.

![](./Ch8/images/prometheus_exporter.png)

One common exporter is collectd exporter.  More information on collectd exporter can be found on this [Collectd Exporter](https://github.com/prometheus/collectd_exporter) github page.

## Application Performance Manager

# Visualization

One of the feature of MCM is Multi-cluster Operations and Visibility. MCM uses WeaveScope to create dashboards and topology views.  As you deployed the application through MCM, the topology is build for you.  You can extend the visualisation through further configuration of Weave Scope, or Grafana or other tools such as the Agile Service Manager (ASM) a component of NOI.

## weavescope



## Grafana

The following is a recipe of creating a grafana dashboard from several sources including New Relic Monitoring tool.

> [Recipe Creating Grafana Dashboard](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/blob/master/doc/Dashboarding/Grafana/README.md)


## Agile Service Manager

Netcool Agile Service Manager (ASM) is a component of Netcool Operation Insight that allows the visualisation and some control of dynamic infrastructure and services.  Agile Service Manager is available as both on-premise and as a helm chart in MCM Catalog.

This [ASM](./Ch8/asm_detail.md) describes ASM and MCM in more detail.

The following recipe provides instruction on Configuring ASM Kubernetes Observer.

> [Recipe: Configuring ASM's Kubernetes Observer and WeaveScope](https://www.ibm.com/support/knowledgecenter/en/SS9LQB_1.1.3/LoadingData/t_asm_loadingviakubernetes.html)

# Logging

Application and systems logs can help you understand what is happening inside your MCM cluster. The logs are particularly useful for debugging problems and monitoring cluster activity. The easiest and most embraced logging method for containerized applications is to write to the standard output and standard error streams.

However, the native functionality provided by a container engine or runtime is usually not enough for a complete logging solution. For example, if a container crashes, a pod is evicted, or a node dies, usually you will still want to access your application’s logs. As such, logs should have a separate storage location, and lifecycle that is independent of nodes, pods, or containers. This concept is called cluster-level-logging. Cluster-level logging requires a separate backend to store, analyze, and query logs.

## ELK

The following [ELK](./Ch8/Monitoring.md) subchapter describes the logging solution making use of Elasticsearch, Logstash and Kibana.  While the Logging solution is available out of the box, they are not configured to be used out of the box.

The following recipes shows how you can configure your ELK.

## Log Analytics

# Alerting

Time series graph will be useful as a dashboard to monitor critical metrics.  For operation purpose, When you have monitor only a small number of services or infrastructure, it might be ok to manage them just by using the Monitoring tools.  When the monitoring target grow in size and complexity, it will be too difficult to monitor just using time series visualisation.  A better approach is to create thresholds and to let the system let you know on threshold violation, either through notification or alerting.  This is better know as *Management by Exception*.

For a small to medium Enterprise it might be enough to setup a notification system on exception.  In a large enterprise or in a service provider, the common practice is to use an Alert Management System.

Even with Alerts, it is possible to have too many alerts.  A key SRE (Site Reliability Engineer) concepts for day 3 and beyond is *Actionable Alerts*.  Alerts should be deduplicated, consolidated, correlated, to manageable quantities; more importantly alerts should drive correction action. To achieve that you will need an Alert Management System to perform Root Cause Analysis (RCA).  RCA is an exercise that might be beyond day 2 Operation.

Prometheus provides Alerting capability, and we will be looking at configuring this capability.  For day 2 operation, if you want to want to do more than just simple alerting solution, then IBM has a well established Alerting solution - Netcool Operation Insight (NOI).

## Prometheus Alert

You can configure Prometheus for alerting and notification by using the Prometheus' Alertmanager.  Key to this process is to create and manage your alerting rules.

> [Recipe: How to generate SNMP traps from Prometheus alerts](https://github.com/ibm-cloud-architecture/CSMO-ICP/tree/master/prometheus/alertmanager_to_snmp)

## Netcool Operation Insight

OMNIbus, the alert manager in Netcool Operation Insight, has out of the box supports to receives alerts from MCM.  OMNIbus can collect MCM logs from Logstash or alerts from prometheus or both. To do this you need to configure OMNIbus's Message Bus Probes.

A containerised version of the Probe for Message Bus is also available  in the form of helm packages: one for Logstash and one for Prometheus.

The following 4 recipes show how to configure Message Bus Probe, Logstash and Prometheus.

> [Recipe: Configuring Message Bus Probe to receive alerts from Prometheus](https://www.ibm.com/support/knowledgecenter/en/SSSHTQ/omnibus/probes/message_bus/wip/reference/messbuspr_ibm_cloud_private_config_probe_prometheus.html)

> [Recipe: Modifying Prometheus Alert Manager and Alert Rules](https://www.ibm.com/support/knowledgecenter/en/SSSHTQ/omnibus/probes/message_bus/wip/reference/messbuspr_ibm_cloud_private_config_icp_prometheus.html)

> [Recipe: Configuring Message Bus Probe to receive alerts from Logstash](https://www.ibm.com/support/knowledgecenter/en/SSSHTQ/omnibus/probes/message_bus/wip/reference/messbuspr_ibm_cloud_private_config_probe_logstash.html)

> [Recipe: Modifying Logstash configuration](https://www.ibm.com/support/knowledgecenter/en/SSSHTQ/omnibus/probes/message_bus/wip/reference/messbuspr_ibm_cloud_private_config_icp_logstash.html)

The probe rules require OMNIbus event grouping triggers to be installed.  In the standard OMNIbus installation, the Event Grouping triggers are not installed by default. If you are configuring your own message probe, the following recipe shows how to enable the Event Grouping triggers.

> [Recipe: Enabling Scope Base Event Grouping in OMNIbus](
https://www.ibm.com/support/knowledgecenter/en/SSSHTQ_8.1.0/com.ibm.netcool_OMNIbus.doc_8.1.0/omnibus/wip/install/task/omn_con_ext_installingscopebasedegrp.html)

# Notification and Collaboration
[Building the incident management toolchain](https://www.ibm.com/cloud/garage/architectures/incidentManagementDomain/overview) describes the thought in developing the toolchain  to manage operation.  Notification and Collaboration tools are important to expedite resolution of Operational issues.

## ChatOps

ChatOps is an operational paradigm where work that
is already happening in the background today is brought into a
common chatroom.  It unifies the communication about what work should get done with actual history of the work being done.

> [Recipe: Lab Exercise on Slack and Netcool Impact](https://www.ibm.com/support/knowledgecenter/en/SSSHTQ/omnibus/probes/message_bus/wip/reference/messbuspr_ibm_cloud_private_config_icp_logstash.html) This lab exercise will lead you through, step by step in integrating Netcool Impact and Slack.  You will need a NOI VM / Container.

> [Education ChatOps Foundations]() Currently being created will update the link once it is available.

> [SODA ChatOps - Transformation through Collaboration & MVP](https://soda.w3ibm.mybluemix.net/show/827)

> [SODA ChatOps/Collaboration - Coach - Consultancy](https://soda.w3ibm.mybluemix.net/show/832)


# Incident and Problem Management

Incident and Problem management are some of the operational aspects that you can deploy after you have implemented these day 2 Operation aspects. These are describes in [IBM Architecture Centre for Incident and Problem Management](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo)

> [Cookbook: Incident Management Tools Implementation  Guide](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/blob/master/doc/Incident_Management_Implementation.md)


# Related Links

- [The 5 principles of cloud service management and operations](https://www.ibm.com/cloud/garage/architectures/serviceManagementArchitecture/microservices-five-principles)
