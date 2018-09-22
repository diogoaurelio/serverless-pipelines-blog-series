AWS Server-less data pipelines with Terraform
====================================
Code supporting Blog post series [AWS Server-less data pipelines with Terraform](https://datacenternotes.com/2018/09/01/aws-server-less-data-pipelines-with-terraform-part-1/).


# Setup

## Python setup

Though not a requirement, we recommend using Anaconda to manage python dependencies. Here are the steps that we will walk you though:
- Setup Anaconda. 
- Setup conda environment
- Setup local env

### Setup Anaconda
To download Anaconda package manager, go to: <i>https://www.continuum.io/downloads</i>.

After installing locally the conda environment, proceed to setup this project environment.


### Setup local conda environment

For dependency management we are using conda-requirements.txt and requirements.txt. 
Please "cd" into the current reposotory and build your conda environment based on those conda-requirements and requirements:
 
```bash
conda create -n analytics python=3.6
source activate analytics
conda install --file conda_requirements.txt
pip install -r pip_requirements.txt
```


To deactivate this specific virtual environment:
```bash
source deactivate
```

If you need to completely remove this conda env, you can use the following command:

```bash
conda env remove --name analytics
```

## Terraform setup

* [Install Terraform](https://www.terraform.io/)

```bash
brew install terraform
```


* In order to automatic format terraform code (and have it cleaner), we use pre-commit hook. To [install pre-commit](https://pre-commit.com/#install).
* Run [pre-commit install](https://pre-commit.com/#usage) to setup locally hook for terraform code cleanup.

```bash
pre-commit install
```


## Planning & applying changes

In order to automate and simplify the provisioning steps, we provide a Makefile, which can be used for:

- deploy whole Terraform setup by simply running "make apply";
- build and deploy individual Lambda function(s);

Before running any 'make' command, we recommend exporting the specific environment you want to use. For example:

```bash
export ENVIRONMENT=dev
```

In order to safely view the executions steps that will be executed, it is a best practice running a "terraform plan"
You can do so via the make file which we provide at the root level of this directory, simply by running the following command:

```bash
make plan
```

To apply Terraform changes, use:

```bash
make apply
```

# Authors/Contributors

See the list of [contributors](https://github.com/diogoaurelio/serverless-pipelines-blog-series/graphs/contributors) who participated in this project.
