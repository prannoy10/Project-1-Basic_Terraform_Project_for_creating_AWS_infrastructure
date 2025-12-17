# 🚀 Terraform AWS Infrastructure Project

## 📌 Overview
This project demonstrates how to provision **AWS infrastructure using Terraform** following Infrastructure as Code (IaC) best practices.

It is designed to showcase:
- Declarative infrastructure
- Repeatable and version-controlled AWS provisioning
- Core Terraform workflow (init → plan → apply)

This project is suitable for beginners to intermediate DevOps engineers and reflects real-world cloud automation fundamentals.

---

## 🏗️ Architecture
The infrastructure typically includes:
- AWS Provider configuration
- EC2 instance provisioning
- Security Groups
- Key pair configuration

📐 **Flow:**
Terraform → AWS API → EC2 & Networking Resources

---

## 🧰 Tech Stack
- **Terraform**
- **AWS (EC2, VPC, Security Groups)**
- **Linux**
- **IAM (via AWS credentials)**

---

## 📂 Project Structure
```bash
.
├── main.tf          # Core infrastructure resources
├── variables.tf    # Input variables
├── outputs.tf      # Output values
├── provider.tf     # AWS provider configuration
└── terraform.tfvars # Variable values

⚙️ Prerequisites
- AWS Account
- IAM user with programmatic access
- Terraform installed
- AWS CLI configured

bash
Copy code
aws configure
terraform --version

🚀 Deployment Steps
bash
Copy code
git clone https://github.com/prannoy10/Project-1-Basic_Terraform_Project_for_creating_AWS_infrastructure.git
cd Project-1-Basic_Terraform_Project_for_creating_AWS_infrastructure

terraform init
terraform plan
terraform apply
To destroy resources:
terraform destroy

bash
Copy code
terraform destroy
