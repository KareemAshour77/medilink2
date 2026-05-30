"""
diagnose_brain.py
─────────────────
Run this once to reveal the layer names inside brain_tumor_cnn.pth.
The output tells us the exact architecture so server.py can be patched.

Usage:
    python diagnose_brain.py

Place this file in the same directory as brain_tumor_cnn.pth and server.py.
"""

import torch
import sys

MODEL_PATH = "brain_tumor_cnn.pth"

print(f"\nLoading: {MODEL_PATH}\n{'─' * 60}")

try:
    checkpoint = torch.load(MODEL_PATH, map_location="cpu", weights_only=False)
except Exception as e:
    # Fallback for older PyTorch versions
    checkpoint = torch.load(MODEL_PATH, map_location="cpu")

print(f"Type:    {type(checkpoint)}\n")

if not isinstance(checkpoint, dict):
    print("⚠️  Not a state dict — this is a full model object.")
    print(f"    Model class: {type(checkpoint).__name__}")
    sys.exit(0)

keys = list(checkpoint.keys())
shapes = {k: tuple(v.shape) if hasattr(v, 'shape') else v for k, v in checkpoint.items()}

print(f"Total keys: {len(keys)}\n")
print("All keys + tensor shapes:")
print("─" * 60)
for k in keys:
    print(f"  {k:<55} {shapes[k]}")

print("\n" + "─" * 60)
print("FIRST key :", keys[0])
print("LAST  key :", keys[-1])

# Try to guess the architecture family from key names
families = {
    "layer1": "ResNet",
    "features": "EfficientNet / VGG / DenseNet",
    "blocks":   "EfficientNet (timm)",
    "conv1":    "ResNet or custom CNN",
    "encoder":  "U-Net style encoder",
}
guesses = [label for prefix, label in families.items()
           if any(k.startswith(prefix) for k in keys)]

print("\nArchitecture hints:")
if guesses:
    for g in guesses:
        print(f"  → {g}")
else:
    print("  → No common prefix matched. Share the full key list above.")

print("\n✅  Copy everything above this line and share it.")