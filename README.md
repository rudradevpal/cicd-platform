# CI/CD Platform Setup
This Document guides to setup a CI/CD Platform on top of Cloud or Bare-metal Server.
> In my case I have used my Personal Computer with 8 core CPU and 16GB RAM. 

### Tools Used
- Virtualbox
- Kubernetes
- Jenkins,
- GitLab
- Docker Registry
- Docker Registry UI
- Slack

## Flow Diagram
![flow](docs/cicd-flow.jpg)

## Installation Steps
1. Setup NFS Server on your Host or Other VM/Server
	1. Create Directory to store NFS data
		```shell
		mkdir /srv/nfs/kubedata -p
		```
	2. Install NFS Client tool
		```shell
		apt-get -y install nfs-common
		```
	3. Install NFS Server
		```shell
		apt-get install nfs-kernel-server
		```
	4. Change ownership of the NFS Directory
		```shell
		chown nobody:nogroup /srv/nfs/kubedata
		```
	5. Change permission of NFS Directory
		```shell
		chmod 777 /srv/nfs/kubedata
		```
	6. Enable NFS Server
		```shell
		systemctl enable nfs-server
		```
	7. Restart NFS Server
		```shell
		systemctl restart nfs-server
		```
	8. Modify /etc/exports
		```shell
		...
		/srv/nfs/kubedata	*(rw,sync,no_subtree_check,no_root_squash,no_all_squash,insecure)
		```
	9. Check
		```shell
		exportfs -rav
		exportfs -v
		```
	
2. Install Kubernetes
	 Go to k8s Directory
	1. Install DDocker and Enable Docker
		```shell
		 ./install_docker.sh
		```
		**If you specify static nodeport to docker registry you can do step 7 after installation of docker**
	2. Install kubeletk, kubeadm and kubectl
		```shell
		./install_kubeadm.sh
		```
	3. Deoly kubernetes
		```shell
		./deploy_k8s.sh 
		```
	4. Install CNI as Calico
		```shell
		kubectl create -f calico.yaml
		```
	
3. Deploy NFS Client Provisioner on Kubernetes
	Go to nfs-client-provisioner Directory
	1. Get connection information for your NFS server.
	2. Change NFS_SERVER value to <YOUR_NFS_SERVER_IP> in deployment.yaml
	3. Change server to <YOUR_NFS_SERVER_IP> under volumes section in deployment.yaml
	4. Create Namespace for NFS
		```shell
		kubectl create namespace nfs
		```
	5. Create RBAC for NFS
		```shell
		kubectl create -f rbac.yaml -n nfs
		```
	6. Deploy NFS Client Provisioner
		```shell
		kubectl create -f deployment.yaml -n nfs
		```
	7. Create default Storage Class
		```shell
		kubectl create -f default-sc.yaml
		```

4. Deploy Kubernetes Dashboard
	1. Deploy oficial Dashboard
		```shell
		kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
		```
	2. Create Service Account for Dashboard
		```shell
		kubectl create serviceaccount cluster-admin-dashboard-sa -n kube-system
		```
	3. Give permission to that Service Account
		```shell
		kubectl create clusterrolebinding cluster-admin-dashboard-sa --clusterrole=cluster-admin --serviceaccount=kube-system:cluster-admin-dashboard-sa
		```
	4. Fetch Service Account Secret Name
		```shell
		kubectl get secret -n kube-system| grep cluster-admin-dashboard-sa
		```
		Output:
		```shell
		cluster-admin-dashboard-sa-token-htwv8           kubernetes.io/service-account-token   3      2m4s
		```
	5. Get Secret token
		```shell
		kubectl get secret | grep cluster-admin-dashboard-sa -n kube-system
		```
	6. Copy and Keep the token part
		Output:
		```shell
		Name:         cluster-admin-dashboard-sa-token-htwv8
		Namespace:    kube-system
		Labels:       <none>
		Annotations:  kubernetes.io/service-account.name: cluster-admin-dashboard-sa
					kubernetes.io/service-account.uid: e542b229-f1ca-4861-b91e-88ca2899a8a1
		
		Type:  kubernetes.io/service-account-token
		
		Data
		====
		ca.crt:     1025 bytes
		namespace:  11 bytes
		token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJjbHVzdGVyLWFkbWluLWRhc2hib2FyZC1zYS10b2tlbi1odHd2OCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJjbHVzdGVyLWFkbWluLWRhc2hib2FyZC1zYSIsImt16InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTpjbHVzdGVyLWFkbWluLWRhc2hib2FyZC1zYSJ9.D-KEAhZBR8iFwYy5BZBwzzC5Mg6fKvK92rjF1BqZeeMeSxZusPZaSlZQ2hRmbXEPBzBxFToe48yhAcxaW8U_Y2W05BPcBDGkaB053g2dwyLCHZm3rDUXDX9iphWMoMgxszDj1Xc056NVupDwsypK67M_gfaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6ImU1NDJiMjI5LWYxY2EtNDg2MS1iOTFlLTg4Y2EyODk5YThhMSIsInN1YiIEL41Qsceb14BvsjCCafbluoeTpPg-lhlNgETBinh9_2tOCUytYKURvfdWbt-ZzawmFOjHKERUn4vzeRSMJhTgYqcpNAh1Zh_QfIOw00i80HMpvnFfvYU5HhPGD5kWuSfuay1p4m-EkOxDvgawqSLWLILstY1cx3LHhCY2_juI3bTwd56uxM2B51ngVg
		```
5. Deploy Docker Registry
	Come to root Directory
	1. Create ```htpasswd``` with Username and Password.You can use [Online Tool](https://www.askapache.com/online-tools/htpasswd-generator/)
		* Username for logging in: <your_username>
		*	Password for the: <your_password>
		*	Realm or Popup Name: blank
		*    DigestDomain: blank
		*	Encryption Algorithm: bcrypt
		*	Authentication Scheme: both
		
		* **Generate**
		
		*Your htapasswd will be under ```bcrypt Algorithm``` section. Copy that and keep Safe.*
	2. Modify registry.yml and change value of ```htpasswd: |``` with the htapasswd you have generated.
	3. Create namespace for docker registry
		```shell
		kubectl create namespace registry
		```
	4. Deploy registry
		```shell
		kubectl create -f registry.yml
		```
	5. **Add this registry in kubernetes worker nodes and in slave**
	6. Modify ```/etc/docker/daemon.json``` and add ```"insecure-registries" : ["<docker_registry_node>:<nodeport>"]```
		Example:
		```shell
		{
			"exec-opts": ["native.cgroupdriver=systemd"],
			"log-driver": "json-file",
			"log-opts": {
				"max-size": "100m"
			},
			"storage-driver": "overlay2",
			"insecure-registries" : ["192.168.10.117:30172"]
		}
		```
    ## .
4.  Install Jenkins on Kubernetes
	 Deploy with jenkins.yml

5.  Install Gitlab on VM
	 Follow gitlab.txt

6.  Configure Slave with Jenkins
	 Install oracle jdk 9 and add slave to jenkins
	 Install dependencies in slave like kubectl, docker, jq, git etc.

7.  Deploy Docker Registry
	 deploy registry.yml before that change 'htpasswd'. Generate from
	 
	 Realm or Popup Name - blank
	 DigestDomain - blank
	 Encryption Algorithm - bcrypt
	 Authentication Scheme - both
	 
	 **Add this registry in kubernetes worker nodes and in slave
	 nano /etc/docker/daemon.json
		add "insecure-registries" : ["<docker_registry_node>:<nodeport>"]
			Example:
				{
					"exec-opts": ["native.cgroupdriver=systemd"],
					"log-driver": "json-file",
					"log-opts": {
						"max-size": "100m"
					},
					"storage-driver": "overlay2",
					"insecure-registries" : ["192.168.10.117:30172"]
				}
	systemctl daemon-reload
	systemctl restart docker
	
	If kubernetes is down  do "docker start $(docker ps -a -q -f status=exited)" on those nodes

8.  Deploy Registry UI
	 First create secret for docker registry
	 	kubectl create secret docker-registry registry-secret --docker-server=192.168.10.117:30172 --docker-username=''cicd' --docker-password='cicd@12345' -n kube-system
	 deploy registry-ui.yml
	 
9.  Create Slack App
	 Enable Incoming Webhooks
	 Note down Webhook URL
	
10. Create Slack Jenkins CI App
      Note down Intregretion Token
	  
11. Install Gitlab Hook and Slack Notification Plugin

12. In GitLab create admin Access token

13. Go to Jenkins > Manage Jenkins > Configure System
	  Under Gitlab 
		Connection name: gitlab-hook
		Gitlab host URL: http://192.168.10.116
		Credentials: GitLab token with admin and all permission
	  Under Slack
		Workspace: aivdsi
		Credential: Slack Intregretion Token
		Default channel / member id: #cicd

14. In Gitlab Admin Area > Settings > Network > Outbound requests > Check "Allow requests to the local network from hooks and services"

15. In Gitlab Admin Area > Settings > CI/CD > Continuous Integration and Deployment > Disable gitlab pipeline

16. Create Gitlab Repo and concurrent Jenkins Pipeline

17. In jenkins Pipeline > Configure > Build Triggers > Build when a change is pushed to GitLab. > Check
	  Note Down webhook URL
	  Check
		Accepted Merge Request Events
		Advance
			Enable [ci-skip]
			Ignore WIP Merge Requests		
			Set build description to build cause (eg. Merge request or Git Push )
			Allowed branches > Filter branches by regex
				Source Branch Regex: .*feature.*
				Target Branch Regex: .*release.*
		Uncheck others

18. In Pipeline put "slackSend (color: "#73B839", message: "demo pipeline successful")" to send notification

19. Go to Gitlab Repo > Settings > Integrations
	  URL: jenkins webhook URL
	  Merge request events: Check 
	  Uncheck others
	  and save
	  
20. Go to Gitlab Repo > Settings > Integrations > Slack notifications
	  Uncheck
		Pipeline
		Deployment
		Notify only default branch
	  Others will be checked
	  Username: blank
	  Webhook: slack webhook URL
	  Save
