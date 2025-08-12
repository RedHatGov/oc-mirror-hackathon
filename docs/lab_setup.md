# Lets get our AWS Env setup
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

> cd ~/oc-mirror-hackathon/oc-mirror-master/

> ./oc-mirror.sh

While this is running take some time to inspect the .cache .oc-mirror and other directories. The base v2 docs are below. We will spend quite a bit of time on these as we move forward. 

[oc-mirror docs](https://github.com/openshift/oc-mirror/blob/main/README.md)

### Lets mirror the tar into the mirror-registry, replace your $HOSTNAME in the .sh file

Again while this is running take some time to inspect the directories.

> ./oc-mirror-to-registry.sh

Once it complete inspect content/ also look at content/working-dir/cluster-resources

### Prep for your ocp install in your aws account 

> ssh-keygen
* take the defaults

> cat ~/.config/containers/auth.json
* Copy the first full section as below and remove all of the spaces, note you will need to ensure you close out the { }

```
{
	"auths": {
		"bastion.sandbox213.opentlc.com:8443": {
			"auth": "aW5pdDpLMmN1MTlBNExQWW9wcmg4bDd6Vk9OMHQzNjVqd1dmQw=="
		}
```

> openshift-install create install-config 
* SSH Public Key: id_ed25519.pub
* Platform: AWS
* AWS Access Key ID: "from demo.redhat.com"
* AWS Secret Access Key: "from demo.redhat.com"
* Region: us-east-1
* Base Domain: sandbox213.opentlc.com
* Cluster Name: ocp 
* Pull Secret: {"auths": {"bastion.sandbox213.opentlc.com:8443": {"auth": "aW5pdDpLMmN1MTlBNExQWW9wcmg4bDd6Vk9OMHQzNjVqd1dmQw=="}}}

## The content is mirrored and your install config is preped, lets deploy your cluster

Lets add the mirrors to your install and deploy your cluster. Review your oc-mirror-to-registry output. You should see 

```
[INFO]   : 📄 Generating IDMS file...
[INFO]   : content/working-dir/cluster-resources/idms-oc-mirror.yaml file created
[INFO]   : 📄 Generating ITMS file...
[INFO]   : content/working-dir/cluster-resources/itms-oc-mirror.yaml file created
```

The idms file is the file that contains the openshift relase and release-images mirrors that are needed for the install

cat ~/oc-mirror-hackathon/oc-mirror-master/content/working-dir/cluster-resources/idms-oc-mirror.yaml

> vi install-config.yaml

```
imageDigestSources:
  - mirrors:
    - bastion.sandbox648.opentlc.com:8443/openshift/release
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  - mirrors:
    - bastion.sandbox648.opentlc.com:8443/openshift/release-images
    source: quay.io/openshift-release-dev/ocp-release
```

We also need to make sure the cluster trusts the mirror-registry

> cat cat ~/quay-install/quay-rootCA/rootCA.pem

Insert the ca into the additional trust bundle 

```
additionalTrustBundle: |
  -----BEGIN CERTIFICATE-----
  MIIEAjCCAuqgAwIBAgIUVvy4iIEfVUkgyK5tnaPnemUxuwkwDQYJKoZIhvcNAQEL
  BQAweDELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAlZBMREwDwYDVQQHDAhOZXcgWW9y
  azENMAsGA1UECgwEUXVheTERMA8GA1UECwwIRGl2aXNpb24xJzAlBgNVBAMMHmJh
```

> cp install-config.yaml install-config.yaml.bk

> openshift-install create cluster --log-level debug

Copy your auth/kubeconfig into ~/.kube/config

> mkdir ~/.kube && cp auth/kubeconfig ~/.kube/config

> watch oc get co
