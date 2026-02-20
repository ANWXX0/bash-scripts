# bash-scripts
bash scripts
**py_manager.sh – Python 3.11 + MiniLM ONNX Manager for Raspberry Pi / Ubuntu**

`py_manager.sh` is an all-in-one interactive shell script that automates installing and managing **Python 3.11** and a **quantized MiniLM ONNX sentence-embedding model** on Raspberry Pi or Ubuntu 25.10 systems. Through a simple menu, it can compile and set Python 3.11 as the system default, roll back to the previous Python, install and quantize the `all-MiniLM-L6-v2` ONNX model, validate embeddings, and print ready-to-use **OpenClaw YAML integration** snippets. It also includes cleanup utilities and safety checks (backups, validation steps, and a summary report) designed to make setting up local embedding search on low-power devices repeatable and hassle-free.

**Key features:**
- Interactive menu for common tasks (install, rollback, model setup, validation, cleanup)
- Compiles and installs **Python 3.11** system-wide with necessary build dependencies
- Downloads, quantizes (INT8), and tests **MiniLM ONNX** for CPU/NEON-optimized embeddings
- Provides **OpenClaw memorySearch integration** config examples
- Includes model validation and system cleanup options
- Generates
