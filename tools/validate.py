"""Validate Lua 5.1, manifest, source-backed symbols and route behavior."""
from pathlib import Path
import argparse
import re
import struct
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--source", required=True, type=Path)
parser.add_argument("--lupa-path", type=Path)
args = parser.parse_args()
if args.lupa_path:
    sys.path.insert(0, str(args.lupa_path))
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
compile_lua = lua.eval("function(s,n) local f,e=loadstring(s,n); assert(f,e) end")
manifest = (root / "OneMap/OneMap.txt").read_text(encoding="utf-8")
files = [line.strip() for line in manifest.splitlines() if line.strip() and not line.startswith("##")]
assert "## Author: oneDOK" in manifest
assert "## DependsOn: LibAddonMenu-2.0>=43" in manifest
assert "## APIVersion: 101051" in manifest
texts = []
for name in files:
    path = root / "OneMap" / name
    text = path.read_bytes().decode("utf-8")
    assert not text.startswith("\ufeff"), path
    compile_lua(text, str(path))
    texts.append(text)
assert set(files) == {p.name for p in (root / "OneMap").glob("*.lua")}
all_code = "\n".join(texts)

# Only owning native sources are consulted; no other addon's implementation.
source_paths = [args.source / "ESOUIDocumentation.txt"]
source_paths += list((args.source / "esoui/ingame/map").rglob("*.lua"))
source_paths += [args.source / path for path in (
    "esoui/libraries/utility/zo_hook.lua",
    "esoui/libraries/zo_templates/scrolltemplates.lua",
    "esoui/publicallingames/currency/currency.lua",
    "esoui/libraries/zo_dialog/zo_dialog.lua",
    "esoui/lang/en_client.lua",
)]
native = "\n".join(p.read_text(encoding="utf-8-sig") for p in source_paths if p.exists())
local_functions = set(re.findall(r"local function (\w+)", all_code))
function_calls = set(re.findall(r"(?<![\w.:])([A-Z]\w+)\s*\(", all_code)) - local_functions
constants = set(re.findall(r"\b(?:QUEST|MOUSE|CT|DT|TEXT|MAP|POI|ZONE|INSTANCE|CURRENCY|PLAYER|SCENE|EVENT|LFG|UI|SI)_[A-Z0-9_]+\b", all_code))
constants -= {"SI_ONEMAP_DUNGEONS", "SI_ONEMAP_TRIALS"}
# The client-provided string-ID helper is absent from the text UI/API export.
native_symbols = (function_calls | constants) - {"ZO_CreateStringId"}
missing = sorted(name for name in native_symbols if not re.search(r"\b" + name + r"\b", native))
assert not missing, f"Symbols missing from native API/source: {missing}"

texture = (root / "OneMap/art/wave.dds").read_bytes()
assert texture[:4] == b"DDS " and len(texture) == 128 + 128 * 128 * 4
assert struct.unpack_from("<II", texture, 12) == (128, 128)
print(f"Lua 5.1 syntax: {len(files)} files; {len(native_symbols)} native symbols verified")

lua.globals().ADDON_ROOT = str(root / "OneMap").replace("\\", "/")
lua.globals().SOURCE_ROOT = str(args.source).replace("\\", "/")
lua.execute((root / "tests/behavior.lua").read_text(encoding="utf-8"))

scroll = LuaRuntime(unpack_returned_tuples=True)
scroll.globals().ADDON_ROOT = str(root / "OneMap").replace("\\", "/")
scroll.globals().SOURCE_ROOT = str(args.source).replace("\\", "/")
scroll.execute((root / "tests/scroll.lua").read_text(encoding="utf-8"))

map_input = LuaRuntime(unpack_returned_tuples=True)
map_input.globals().ADDON_ROOT = str(root / "OneMap").replace("\\", "/")
map_input.globals().SOURCE_ROOT = str(args.source).replace("\\", "/")
map_input.execute((root / "tests/map_input.lua").read_text(encoding="utf-8"))

# Both interface languages must have exactly the same keys and placeholders.
strings = LuaRuntime(unpack_returned_tuples=True)
strings.execute("OneMap = {}; function GetCVar() return 'en' end; function ZO_CreateStringId() end")
strings.execute((root / "OneMap/Core.lua").read_text(encoding="utf-8"))
strings.execute((root / "OneMap/Strings.lua").read_text(encoding="utf-8"))
en = dict(strings.globals().OneMap.strings)
strings.execute("function GetCVar() return 'ru' end")
strings.execute((root / "OneMap/Strings.lua").read_text(encoding="utf-8"))
ru = dict(strings.globals().OneMap.strings)
assert en.keys() == ru.keys()
for key in en:
    assert en[key] and ru[key]
    assert re.findall(r"%[sd]", en[key]) == re.findall(r"%[sd]", ru[key]), key
print(f"Localization: {len(en)} keys in English and Russian; DDS and manifest passed")
