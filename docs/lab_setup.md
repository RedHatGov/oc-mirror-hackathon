# Lets get our AWS Env setup with
* bastion 
* mirror-registry
* oc-mirror 
* disconnected ocp 

## Create the AWS account via demo

[AWS Blank Open Environment](https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-open.prod&utm_source=webapp&utm_medium=share-link)

> Practice / Enablement

> Purpose: Conduct internal training

> Auto-stop, Auto-destroy (1 week)

Keep this web page open for your aws credentials 

## Log into AWS

Copy the aws url and open it in a new browser window

In the search bar search for 

* ec2 (Open in new Tab)
* Route53 (Open in new Tab)

### Create your default VPC

[Default VPC](https://us-east-2.console.aws.amazon.com/vpc/home?region=us-east-2#CreateDefaultVpc:)

### Creation your bastion (registry node)

> Launch Instance

* name: bastion
* ami: red hat
* instance type: t2.large
* key: create new key pair (Download and save to your ssh dir)
* storage: 500 gib
> Launch Instance

### DNS entry for your bastion

> on your ec2 screen select your bastion. copy your pub IP from the details screen below. 

> on your route53 screen selct your "Hosted zone", sandboxXXX.opentlc.com, create record

* record name: bastion
* value: {Paste your ec2 IP}

> Create records

### Connect to your rhel ec2

> ssh -i ~/.ssh/keyname.pem ec2-user@ec2IP

### Setup your ec2

> sudo dnf install podman git -y

> sudo hostnamectl hostname bastion.sandboxXXX.opentlc.com

> git clone https://github.com/RedHatGov/oc-mirror-hackathon.git

> cd oc-mirror-hackathon && ./collect_ocp

* oc-mirror
* openshift-install *** (4.19.2) ***
* oc
* mirror-registry
* butane

> cd mirror-registry && ./mirror-registry install

While this is installing go back to your aws ec2 window
* click "Security Tab"
* click "Security Group" (launch-wizard-1ls)
* click "Edit Inbound rules"
* click "Add rule"
* add "Port range 8443, CIDR 0.0.0.0/0"
* click "Save rules"

*NOTE:* When mirror-registry install completes, save your credentials to a scratch pad

Trust your registry ssl 

> sudo cp ~/quay-install/quay-rootCA/rootCA.pem /etc/pki/ca-trust/source/anchors/

> sudo update-ca-trust

Load your pull-secret into your bastion node

[Pull-secret](https://console.redhat.com/openshift/downloads)

> mkdir ~/.config/containers

*NOTE:* Paste
> vi ~/.config/containers/auth.json 

Log into your registry and store your credentials 

> podman login https://bastion.sandbox213.opentlc.com:8443 --username init --password K2cu19A4LPYoprh8l7zVON0t365jwWfC --authfile ~/.config/containers/auth.json

Log into your registry in a new web browser tab if you would like

### Lets run your first oc-mirror of ocp 4.19.2 


