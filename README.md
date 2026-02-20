 
About: Python 3.11 + GGUF MiniLM Manager Script

Script Name: Python 3.11 + GGUF MiniLM Manager (ALL-IN-ONE)
Platform: Raspberry Pi / Ubuntu 25.10
Purpose: Simplify the setup, installation, and management of Python 3.11 and local MiniLM models (GGUF format) for AI inference.

Features:

System-wide Python 3.11 Installation:

Downloads, compiles, and installs Python 3.11.10 from source.

Ensures pip and essential Python tools (setuptools, wheel) are upgraded.

Allows safe rollback to the original system Python.

GGUF MiniLM Model Management:

Downloads the quantized GGUF MiniLM model all-MiniLM-L6-v2-Q4_K_M.

Tests the model locally using the gf library to verify embeddings.

Provides YAML integration example for OpenClaw local memory search.

Model Validation:

Option to validate MiniLM embeddings directly from the terminal.

System Safety & Reporting:

Uses SSH-safe ✅ checkmarks and ❌ crosses for step success/failure reporting.

Generates a /tmp/setup_report.txt summarizing all steps.

Cleanup:

Removes temporary build files, Python source archives, and cleans apt cache.

System helpers are preserved to avoid breaking command-not-found or other essential utilities.

Recommendations:

Designed for Raspberry Pi 4 or similar low-memory ARM boards.

Uses local INT4 quantized GGUF model for efficient CPU inference.

Swap management is recommended for heavy compilation or AI workloads.

Usage:

Run the script via terminal:

sudo bash setup_minilm.sh

Choose from menu options [1–8] to install Python, manage models, validate embeddings, or clean up.

Target Users:

AI hobbyists, developers, and researchers running local inference on Raspberry Pi or Ubuntu ARM boards.

Anyone needing a simple, safe setup of Python + MiniLM GGUF models for local experiments.
