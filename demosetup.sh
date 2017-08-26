# https://github.com/Microsoft/azure-docs/blob/master/articles/container-service/container-service-kubernetes-walkthrough.md

alias az="docker run --rm --volume ${HOME}:/root azuresdk/azure-cli-python az"
az login

RESOURCE_GROUP=RG-karkuber
LOCATION=southcentralus
DNS_PREFIX=karkuber
CLUSTER_NAME=karkuberklstr

az group create --name=$RESOURCE_GROUP --location=$LOCATION
az acs create --orchestrator-type=kubernetes --resource-group=$RESOURCE_GROUP --name=$CLUSTER_NAME --dns-prefix=$DNS_PREFIX --generate-ssh-keys
# az acs kubernetes get-credentials --resource-group=$RESOURCE_GROUP --name=$CLUSTER_NAME --file /root/.azure/kubeconfig
az acs kubernetes get-credentials --resource-group=$RESOURCE_GROUP --name=$CLUSTER_NAME

export KUBECONFIG=${HOME}/.azure/kubeconfig

kubectl get nodes
kubectl proxy &
K8S_PROXY_PID=$!

open http://localhost:8001/ui

kill ${K8S_PROXY_PID}

# https://www.youtube.com/watch?v=eMOzF_xAm7w
# https://github.com/everett-toews/croc-hunter

# Install Helm
# Mac: 
# brew install kubernetes-helm

# Bash:
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh


helm init
helm repo update

# Install Jenkins into the cluster
helm --namespace jenkins --name jenkins -f ./jenkins-values.yaml install stable/jenkins

watch kubectl get svc --namespace jenkins # wait for external ip
export JENKINS_IP=$(kubectl get svc jenkins-jenkins --namespace jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
export JENKINS_URL=http://${JENKINS_IP}:8080

kubectl get pods --namespace jenkins # wait for running
open ${JENKINS_URL}/login

printf $(kubectl get secret --namespace jenkins jenkins-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode) | pbcopy
# username: admin
# password: <paste>

# Credentials > Jenkins > Global credentials > Add Credentials
#   Username: etoews
#   Password: ***
#   ID: quay_creds
#   Description: https://quay.io/user/etoews

# Open Blue Ocean
# Create a new Pipeline
# Where do you store your code?
#   GitHub
# Connect to Github
#   Create an access key here
#     Token description: kubernetes-jenkins
#   Generate token > Copy Token > Paste back in Jenkins  
# Which organization does the repository belong to?
#   everett-toews
# Create a single Pipeline or discover all Pipelines?
#   New pipeline
# Choose a repository
#   croc-hunter
# Create Pipeline

kubectl get pods --namespace jenkins

# Classic Jenkins
# everett-toews (GitHub org)
# Configure
# Advanced
#   Build origin PRs (merged with base branch)
# Save

printf ${JENKINS_URL}/github-webhook/ | pbcopy

# https://github.com/everett-toews/croc-hunter/settings/hooks
# Add webhook
#   Payload URL: <paste>
# Which events would you like to trigger this webhook?
#   Send me everything.
# Add webhook

export CROC_IP=$(kubectl get svc croc-hunter-croc-hunter --namespace croc-hunter --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
export CROC_URL=http://${CROC_IP}

open ${CROC_URL}

git checkout dev
sed -i "" "s/game\.js/game2\.js/g" croc-hunter.go
git commit -am "Game 2"
git push

open ${JENKINS_URL}/blue/organizations/jenkins/everett-toews%2Fcroc-hunter/activity/

# dev branch builds

open https://github.com/everett-toews/croc-hunter

# PR from dev to master
# PR builds
# merge the PR
# master builds and deploys new version

helm delete jenkins --purge
az group delete --name=$RESOURCE_GROUP --yes --verbose
az acs delete --resource-group=$RESOURCE_GROUP --name=$CLUSTER_NAME --verbose