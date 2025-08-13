# Fichier: builds/ubuntu/variables.pkr.hcl

## Configuration AWS
variable "aws_region" {
  type        = string
  description = "Région AWS où déployer l'infrastructure"
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "Type d'instance EC2 pour le build Packer"
  default     = "t3.medium"
}

variable "root_volume_size" {
  type        = number
  description = "Taille du volume root (en GB)"
  default     = 25
}

# Configuration AMI
variable "ami_prefix" {
  type        = string
  description = "Préfixe pour le nom de l'AMI"
  default     = "rex-devsecops-k3s"
}

# variable "ami_owner" {
#   type        = string
#   description = "Propriétaire de l'AMI source (Canonical pour Ubuntu)"
#   default     = "099720109477"
# }

# Configuration utilisateur
variable "ssh_username" {
  type        = string
  description = "Nom d'utilisateur SSH pour la connexion"
  default     = "ubuntu"
}

variable "ssh_timeout" {
  type        = string
  description = "Timeout pour la connexion SSH"
  default     = "10m"
}

variable "ami_description" {
  type        = string
  description = "Description de l'AMI"
  default     = "Golden Image REX-DevSecOps avec configurations de base"
}

# Tags par défaut
variable "common_tags" {
  type        = map(string)
  description = "Tags communs à toutes les ressources"
  default = {
    Project     = "rex_devsecops_project"
    Environment = "dev"
    ManagedBy   = "Packer"
    Department  = "IT"
  }
}