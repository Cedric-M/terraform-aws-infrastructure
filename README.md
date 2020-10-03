# terraform-aws-infrastructure

AWS infrastructure made using Terraform

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

An AWS account is mandatory, as we're gonna deploy this infrastructure on... AWS :)  If you already have one you can [Sign In](https://console.aws.amazon.com/console/home), otherwise you still can [create a new AWS account](https://portal.aws.amazon.com/billing/signup#/start)

### Installing Terraform on Ubuntu

Please run the commands below to get and install [Terraform](https://www.terraform.io/downloads.html) on Ubuntu

```
sudo apt-get install unzip
wget https://releases.hashicorp.com/terraform/0.13.3/terraform_0.13.3_linux_amd64.zip
unzip terraform_0.13.3_linux_amd64.zip
sudo mv terraform /usr/local/bin/
ls /usr/local/bin/
```


Check if Terraform is now successfully installed by running:

```
terraform --version
# should return:
# Terraform v0.13.3
```


## Deployment

This part is gonna focus on how to deploy the project on a live system.
Once Terraform is successfully installed and you have access to your AWS account, let's clone the repository and deploy the project :


```
git clone https://github.com/Cedric-M/terraform-aws-infrastructure.git
```

Once you cloned the git repository, you need to create an AWS Access Key:

>Get the keys from console.aws.amazon.com/iam > security credentials > Access Keys

Add then add them to the `terraform.tfvars` file as follow:



```
aws_access_key = "XXXXXXXXXXXXXXXXXXXX"
aws_secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

### Launching procedure

Once your keys are setup, all you have to do is to use the following commands:

```
terraform init                        #Initialize a Terraform working directory
terraform apply                       #Builds or changes infrastructure

#Tips, to avoid writing manually "yes" each time you run terraform apply, use:

terraform apply --auto-approve 
```


### Shutdown procedure

In order to shut down the infrastructure we made, (also, not to use too much resource of your AWS Free Tier), you can run the following command once you're done:

```
terraform destroy --auto-approve      #Destroy Terraform-managed infrastructure
```


### Supervision procedure

```
terraform state list                  #Advanced state management: show all running instances  
                                      #(make sure you ran terraform apply before)
terraform state show <ressource_name> # Show details about a specific ressource

```


## Built With

* [Terraform](https://www.terraform.io/) - Open-source infrastructure as code software tool created by [HashiCorp](https://www.hashicorp.com/).
* [AWS](https://aws.amazon.com/) - Amazon Web Services cloud computing 

## Versioning

We use [GitHub](https://github.com/Cedric-M/terraform-aws-infrastructure) for versioning.

## Authors

* **Cedric-M** - *DevOps/CloudOps Engineer*


## License
[MIT](https://choosealicense.com/licenses/mit/)