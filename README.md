# Random Forest-Based Intrusion Detection & Prevention System (IDPS)

## 📖 Overview
This project implements a **machine learning-based Intrusion Detection and Prevention System (IDPS)** for detecting and mitigating **Denial-of-Service (DoS) attacks** in corporate networks.  
It uses the **Random Forest algorithm** trained on the **CIC-DDoS2019 dataset**, optimized for accuracy and practical deployment in Kenyan enterprise environments.  
A **Graphical User Interface (GUI)** provides real-time traffic monitoring, alert management, and report generation.

## 🎯 Objectives
- Detect and classify malicious DoS traffic with high accuracy.
- Isolate and block suspicious traffic in real-time.
- Provide a usable **GUI dashboard** for administrators.
- Support explainability with feature importance and SHAP analysis.
- Deliver a modular, scalable solution aligned with enterprise security needs.

## 🏗️ System Features
- **Data Preprocessing:** Cleaning, scaling, and feature engineering pipeline.
- **Model Training:** Random Forest classifier with evaluation metrics (Accuracy, Precision, Recall, F1, AUC).
- **Testing & Evaluation:** CIC-DDoS2019 dataset split into training/test sets; evaluated for robustness.
- **GUI Module:** Built with PyQt5 for live monitoring, alerts, and system management.
- **Simulation Environment:** Tested using Ubuntu VM (server) + Kali Linux VM (attack simulation).
- **Reports & Logging:** Alerts, block rules, and system events logged for auditing.

## 📂 Repository Structure
Random-Forest-Based-IDPS/
│
├── config/ # Configuration files
├── data/ # Local data storage (ignored via .gitignore)
├── models/ # Trained ML models (ignored via .gitignore)
├── notebooks/ # Jupyter/Colab notebooks for experiments
├── reports/ # Generated evaluation reports & figures
├── requirements.txt # Python dependencies
├── eda_summary.md # Exploratory data analysis summary
├── README.md # Project documentation (this file)
└── .gitignore # Ignored files (datasets, models, logs)


---

## ⚙️ Tech Stack
- **Python** – Core development
- **scikit-learn** – Random Forest training & evaluation
- **pandas, numpy** – Data preprocessing
- **matplotlib, seaborn** – Visualization
- **PyQt5** – Graphical User Interface
- **SHAP** – Explainability
- **VirtualBox + Kali Linux** – Traffic simulation

---

## 🚀 Getting Started

### Prerequisites
- Python 3.10+
- Virtual environment (`venv`)
- Kaggle API (for dataset download)

### Installation
```bash
# Clone repository
git clone https://github.com/annKimani-ICS/Random-Forest-Based-IDPS.git
cd Random-Forest-Based-IDPS
```
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # (Linux/Mac)
.venv\Scripts\activate     # (Windows PowerShell)

# Install dependencies
pip install -r requirements.txt

#Running
Download and preprocess dataset (see notebooks/).
Train model (sprint2_model_training.ipynb).
Launch GUI for live traffic simulation and alert monitoring.

#📊 Results (First Iteration)
Accuracy: >99%
Macro-averaged AUC: ~1.0
Key Features: Packet size, flow duration, source port, etc.
Robust detection of DoS attack flows in simulated corporate network settings.

#📌 Roadmap
 Sprint 1 – Data Cleaning & Preprocessing
 Sprint 2 – Model Training & Evaluation
 Sprint 3 – GUI Development (PyQt5 Dashboard)
 Sprint 4 – Integration with VM Simulation (Ubuntu + Kali)
 Sprint 5 – Final Evaluation & Defense

#👩‍💻 Author
Kimani Ann Wangari
BSc Informatics and Computer Science, Strathmore University, Nairobi, Kenya
Supervisor: Mr. James Gikera

#📜 License
This project is for academic and research purposes only. Unauthorized use in production environments is not advised without further security hardening.

[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/F63P1L7A)
[![Open in Visual Studio Code](https://classroom.github.com/assets/open-in-vscode-2e0aaae1b6195c2367325f4f02e2d04e9abb55f0b24a779b69b11b9e10269abc.svg)](https://classroom.github.com/online_ide?assignment_repo_id=20100707&assignment_repo_type=AssignmentRepo)

Git cheatsheet: https://philomatics.com/git-cheatsheet-release
