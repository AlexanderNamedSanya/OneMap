"""Build and verify a clean standalone addon ZIP without bundled libraries."""
from pathlib import Path
import hashlib
import re
import zipfile

root = Path(__file__).resolve().parents[1]
addon = root / "OneMap"
version = re.search(r"^## Version: (.+)$", (addon / "OneMap.txt").read_text(encoding="utf-8"), re.M)[1]
(addon / "LICENSE.txt").write_bytes((root / "LICENSE.txt").read_bytes())
(addon / "CHANGELOG.txt").write_bytes((root / "ESOUI-changelog.txt").read_bytes())
target = root / "dist" / f"OneMap-{version}.zip"
target.parent.mkdir(exist_ok=True)
paths = sorted(p for p in addon.rglob("*") if p.is_file())
assert all(p.suffix in {".lua", ".txt", ".dds", ".xml"} for p in paths)
with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
    for path in paths:
        archive.write(path, path.relative_to(root).as_posix())
with zipfile.ZipFile(target) as archive:
    assert archive.testzip() is None
    assert set(archive.namelist()) == {p.relative_to(root).as_posix() for p in paths}
    for path in paths:
        assert archive.read(path.relative_to(root).as_posix()) == path.read_bytes()
print(f"{target}: {len(paths)} files, {target.stat().st_size} bytes")
print(f"SHA256: {hashlib.sha256(target.read_bytes()).hexdigest()}")
