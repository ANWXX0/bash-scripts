#!/bin/bash
# ===============================================
# Python 3.11 + ONNX MiniLM Manager (ALL-IN-ONE)
# Raspberry Pi / Ubuntu 25.10
# ===============================================

set -e

# ---------------------------
# Colors
# ---------------------------
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# ---------------------------
# Variables
# ---------------------------
PYTHON_VERSION=3.11.10
PYTHON_SRC_DIR=/usr/src/Python-$PYTHON_VERSION
MODEL_DIR=/opt/minilm
REPORT_FILE=/tmp/setup_report.txt

# Init report
echo "Setup report:" > $REPORT_FILE

# ---------------------------
# Reporting functions
# ---------------------------
report_success() { echo -e "${GREEN}✅ $1${RESET}"; echo "SUCCESS: $1" >> $REPORT_FILE; }
report_fail()    { echo -e "${RED}❌ $1${RESET}"; echo "FAIL: $1" >> $REPORT_FILE; }

run_step() {
    STEP_NAME="$1"
    COMMAND="$2"
    echo -e "${YELLOW}==> $STEP_NAME...${RESET}"
    if eval "$COMMAND"; then
        report_success "$STEP_NAME"
    else
        report_fail "$STEP_NAME"
    fi
}

# ---------------------------
# MENU
# ---------------------------
echo -e "${YELLOW}=====================================${RESET}"
echo -e "${YELLOW} Python + ONNX Manager${RESET}"
echo -e "${YELLOW}=====================================${RESET}"
echo "1) Install Python 3.11 (system-wide)"
echo "2) Rollback to system Python"
echo "3) Install MiniLM ONNX model + test (quantized)"
echo "4) Usage instructions"
echo "5) How to use the MiniLM model with OpenClaw"
echo "6) Validate if MiniLM model is working"
echo "7) Recommendation / suggestion"
echo "8) Clean up temporary files / apt cache"
echo
read -p "Choose option [1-8]: " CHOICE

# =========================================================
# OPTION 1: INSTALL PYTHON 3.11
# =========================================================
if [ "$CHOICE" = "1" ]; then
    run_step "Installing build dependencies" \
    "apt update -y 2>/dev/null || true && apt upgrade -y && apt install -y build-essential wget curl libffi-dev libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev xz-utils tk-dev liblzma-dev libgdbm-dev libnss3-dev libgdbm-compat-dev python3-distutils"

    run_step "Downloading Python $PYTHON_VERSION" \
    "cd /usr/src && wget -q -N https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz"

    run_step "Extracting Python source" \
    "cd /usr/src && tar xvf Python-$PYTHON_VERSION.tgz"

    run_step "Compiling Python (this takes time)" \
    "cd $PYTHON_SRC_DIR && ./configure --enable-optimizations --with-ensurepip=install && make -j4 && make altinstall"

    run_step "Backing up system python" \
    "cp /usr/bin/python3 /usr/bin/python3.bak 2>/dev/null || true"

    run_step "Switching system Python to 3.11" \
    "ln -sf /usr/local/bin/python3.11 /usr/bin/python3"

    run_step "Ensure pip for Python 3.11" \
    "python3 -m ensurepip --upgrade"

    run_step "Upgrade pip globally" \
    "python3 -m pip install --upgrade pip setuptools wheel"

    run_step "Verify Python version" \
    "python3 --version"

    echo -e "${GREEN}Python 3.11 is now system default${RESET}"

# =========================================================
# OPTION 2: ROLLBACK
# =========================================================
elif [ "$CHOICE" = "2" ]; then
    run_step "Restoring original python" \
    "ln -sf /usr/bin/python3.bak /usr/bin/python3 2>/dev/null || true"

    run_step "Verify rollback" \
    "python3 --version"

    echo -e "${GREEN}System Python restored${RESET}"

# =========================================================
# OPTION 3: INSTALL MODEL + TEST + QUANTIZE
# =========================================================
elif [ "$CHOICE" = "3" ]; then
    run_step "Installing Python packages globally (onnxruntime + onnxruntime-tools + tokenizers + numpy)" \
    "python3 -m pip install --upgrade pip && python3 -m pip install onnxruntime onnxruntime-tools tokenizers numpy"

    run_step "Creating model directory" \
    "mkdir -p $MODEL_DIR"

    run_step "Downloading MiniLM ONNX model" \
    "cd $MODEL_DIR && wget -q -N https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/onnx/model.onnx && wget -q -N https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/tokenizer.json && wget -q -N https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/config.json"

    echo -e "${YELLOW}==> Quantizing MiniLM ONNX model (INT8) for NEON CPU acceleration...${RESET}"

python3 <<END
from onnxruntime.quantization import quantize_dynamic, QuantType
import onnxruntime as ort
import numpy as np
from tokenizers import Tokenizer

MODEL_DIR = "$MODEL_DIR"
input_model = f"{MODEL_DIR}/model.onnx"
quant_model = f"{MODEL_DIR}/model_quant.onnx"

try:
    quantize_dynamic(input_model, quant_model, weight_type=QuantType.QInt8)
    print("✅ Quantized model saved at:", quant_model)
except Exception as e:
    print("❌ Quantization failed:", e)
    exit(1)

try:
    tokenizer = Tokenizer.from_file(f"{MODEL_DIR}/tokenizer.json")
    session = ort.InferenceSession(quant_model)

    encoded = tokenizer.encode("Hello from Raspberry Pi ?")
    input_ids = np.array([encoded.ids], dtype=np.int64)
    attention_mask = np.array([[1]*len(encoded.ids)], dtype=np.int64)
    token_type_ids = np.array([[0]*len(encoded.ids)], dtype=np.int64)

    outputs = session.run(None, {
        "input_ids": input_ids,
        "attention_mask": attention_mask,
        "token_type_ids": token_type_ids
    })

    print("✅ Quantized MiniLM embedding shape:", len(outputs[0][0]))
except Exception as e:
    print("❌ Quantized model test failed:", e)
    exit(1)
END

    if [ $? -eq 0 ]; then
        report_success "MiniLM ONNX quantized + test passed"
    else
        report_fail "MiniLM ONNX quantized test failed"
    fi

    echo -e "${GREEN}Quantized model ready at: $MODEL_DIR/model_quant.onnx${RESET}"
    echo -e "${YELLOW}OpenClaw YAML integration example:${RESET}"
    echo "agents:"
    echo "  defaults:"
    echo "    memorySearch:"
    echo "      provider: local"
    echo "      localModelPath: $MODEL_DIR/model_quant.onnx"
    echo "      tokenizerPath: $MODEL_DIR/tokenizer.json"

# =========================================================
# OPTION 4: USAGE INSTRUCTIONS
# =========================================================
elif [ "$CHOICE" = "4" ]; then
    echo -e "${YELLOW}Usage instructions:${RESET}"
    echo "1) Install Python 3.11 (system-wide)"
    echo "2) Rollback to previous system Python"
    echo "3) Install MiniLM ONNX model, quantize, and test"
    echo "4) Show this usage information"
    echo "5) How to integrate model with OpenClaw"
    echo "6) Validate the model manually"
    echo "7) Suggestions / recommendations"
    echo "8) Clean up temporary files / apt cache"

# =========================================================
# OPTION 5: OPENCLAW INTEGRATION
# =========================================================
elif [ "$CHOICE" = "5" ]; then
    echo -e "${YELLOW}OpenClaw memory search integration:${RESET}"
    echo "Update your OpenClaw YAML config as follows:"
    echo "agents:"
    echo "  defaults:"
    echo "    memorySearch:"
    echo "      provider: local"
    echo "      localModelPath: $MODEL_DIR/model_quant.onnx"
    echo "      tokenizerPath: $MODEL_DIR/tokenizer.json"

# =========================================================
# OPTION 6: VALIDATE MODEL
# =========================================================
elif [ "$CHOICE" = "6" ]; then
    echo -e "${YELLOW}Validating MiniLM ONNX model embeddings...${RESET}"
python3 <<END
from onnxruntime import InferenceSession
from tokenizers import Tokenizer
import numpy as np

MODEL_DIR = "$MODEL_DIR"
try:
    tokenizer = Tokenizer.from_file(f"{MODEL_DIR}/tokenizer.json")
    session = InferenceSession(f"{MODEL_DIR}/model_quant.onnx")
    encoded = tokenizer.encode("Validation test")
    input_ids = np.array([encoded.ids], dtype=np.int64)
    attention_mask = np.array([[1]*len(encoded.ids)], dtype=np.int64)
    token_type_ids = np.array([[0]*len(encoded.ids)], dtype=np.int64)
    outputs = session.run(None, {
        "input_ids": input_ids,
        "attention_mask": attention_mask,
        "token_type_ids": token_type_ids
    })
    print("✅ Model validation successful, embedding length:", len(outputs[0][0]))
except Exception as e:
    print("❌ Model validation failed:", e)
END

# =========================================================
# OPTION 7: RECOMMENDATION / SUGGESTION
# =========================================================
elif [ "$CHOICE" = "7" ]; then
    echo -e "${YELLOW}Recommendation / suggestion:${RESET}"
    echo "- On Raspberry Pi 4, install Python 3.11 system-wide for best compatibility."
    echo "- Avoid virtual environments unless isolating projects."
    echo "- Use quantized MiniLM ONNX model (INT8) for best CPU performance."
    echo "- Always backup your system Python before replacing."
    echo "- Test the model manually using option 6 before integrating with OpenClaw."
    echo "- Keep /opt/minilm for all local models; avoids permission issues."
    echo "- Use update-alternatives if you want multi-Python setup without removing system Python."

# =========================================================
# OPTION 8: CLEANUP TEMP FILES / CACHE
# =========================================================
elif [ "$CHOICE" = "8" ]; then
    echo -e "${YELLOW}Cleaning up temporary files and apt cache...${RESET}"
    run_step "Clean apt cache" "apt clean"
    run_step "Remove /usr/src Python tarballs" "rm -f /usr/src/Python-$PYTHON_VERSION.tgz"
    run_step "Remove extracted Python source folder" "rm -rf /usr/src/Python-$PYTHON_VERSION"
    echo -e "${GREEN}Cleanup completed. System helpers are preserved.${RESET}"

# =========================================================
# INVALID OPTION
# =========================================================
else
    echo -e "${RED}Invalid option${RESET}"
    exit 1
fi

# ---------------------------
# SUMMARY REPORT
# ---------------------------
echo
echo -e "${YELLOW}===== SUMMARY =====${RESET}"
cat $REPORT_FILE
echo -e "${YELLOW}===================${RESET}"
