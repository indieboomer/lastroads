"""Read-only RGBA/contract audit; asset assembly is performed by Godot, not Python."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets/old-masters"


def inspect(path):
    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A")
    visible = alpha.point(lambda value: 255 if value >= 77 else 0)
    return {
        "file": str(path.relative_to(ROOT)),
        "size": list(image.size),
        "alpha_extrema": list(alpha.getextrema()),
        "transparent_pixels": alpha.histogram()[0],
        "visible_bounds": list(visible.getbbox() or (0, 0, 0, 0)),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def main():
    results = []
    for contract in json.loads((ART / "source-contracts.json").read_text(encoding="utf-8")):
        source = ROOT / contract["source"]
        assert hashlib.sha256(source.read_bytes()).hexdigest() == contract["sha256"], source
        target = inspect(ART / ("npc-" + contract["id"] + ".png"))
        assert target["size"] == contract["active_frame"][2:], target
        assert target["transparent_pixels"] > 1000, target
        target["original_preserved"] = True
        target["target_baseline"] = contract["baseline"]
        target["actual_visible_baseline"] = target["visible_bounds"][3] - 1
        assert abs(target["actual_visible_baseline"] - contract["baseline"]) <= 2, target
        results.append(target)
    for name in ["nera", "lucan", "ysabet", "garran", "corvin", "anselm"]:
        record = inspect(ART / ("npc-" + name + ".png"))
        assert record["transparent_pixels"] > 1000
        results.append(record)
    for name in ["mara-lamplight", "lucan-lamplight", "traveller-portraits", "hospice-patients"]:
        results.append(inspect(ART / (name + ".png")))
    # Pure red high-alpha fringe, rather than natural copper hair colour.
    for version, path in [("old", ROOT / "assets/revision/npc-ilya-v4.png"), ("new", ART / "npc-ilya.png")]:
        image = Image.open(path).convert("RGBA")
        count = sum(a >= 77 and r > 220 and g < 35 and b < 70 for r, g, b, a in image.get_flattened_data())
        results.append({"ilya_fringe_version": version, "pure_red_visible_pixels": count})
    (ART / "alpha-audit.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
    print("ART AUDIT PASS: eight original hashes preserved, exact frame canvases, stable visible baselines, fourteen real-alpha NPCs, creator/memory/patient assets")


if __name__ == "__main__":
    main()
