# Building the MCM CI/CD Docker Image

## Download CLIs
To download `cloudctl` CLI, use the instructions below:
* https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.2/manage_cluster/install_cli.html

To download `mcmctl` CLI, use the instructions below:
* https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/mcm/installing/install.html

**NOTE:** Make sure to rename the CLIs to `cloudctl` and `mcmctl`, respectively. Also, make sure that you put the CLIs in the `cookbook/docs/demos/docker` folder so that the CLIs get picked up when building the Docker image

## Building the Docker Image
Once you have the CLIs ready, build the Docker image using the commands below:
```bash
# First log into your Docker Registry
# Build the Docker image with the command below
docker build -t ${REGISTRY_LOCATION}/kube-helm-cloudctl-mcmctl:3.1.2 .

# Push image to Docker registry
docker push ${REGISTRY_LOCATION}/kube-helm-cloudctl-mcmctl:3.1.2
```