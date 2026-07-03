#!/usr/bin/env python3
"""Export YOLOv8-nano to a CoreML package for SpatialNav.

Usage:
    python3 -m venv .venv && source .venv/bin/activate
    pip install ultralytics
    python3 scripts/convert_yolo_to_coreml.py

Then move the produced `yolov8n.mlpackage` into
`SpatialNav/Resources/MLModels/` — the Xcode target picks it up
automatically (file-system synchronized group) and compiles it into
the app bundle, which enables object detection at the next build.

`nms=True` bakes non-maximum suppression into the model so Vision
returns ready-to-use VNRecognizedObjectObservation results, which is
what YOLODetectionService expects. `half=True` halves the weight size
(FP16) with no practical accuracy loss on the Neural Engine.
"""

from pathlib import Path

from ultralytics import YOLO


def main() -> None:
    model = YOLO("yolov8n.pt")  # downloads on first run
    exported = model.export(format="coreml", nms=True, imgsz=640, half=True)
    print(f"\nExported: {exported}")
    destination = Path("SpatialNav/Resources/MLModels")
    print(f"Move it to: {destination}/yolov8n.mlpackage")


if __name__ == "__main__":
    main()
