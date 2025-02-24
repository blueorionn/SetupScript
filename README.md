# Custom Cloud Images Repository

This repository contains pre-configured custom images for various cloud providers like **DigitalOcean, AWS, and others**. Each image is designed for a specific use case, such as security-hardened servers, developer environments, or lightweight minimal installations.

## 📌 Features

- **Custom Users**: Non-sudo `admin` user with SSH access.
- **Pre-installed Software**: Option to include common packages like `Docker`, `Nginx`, or `Python`.
- **Automated Image Creation**: Uses **Packer** for reproducibility.
- **Cloud Support**: Supports **DigitalOcean, AWS (EC2 AMI), and raw disk images**.
