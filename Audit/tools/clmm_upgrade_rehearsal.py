#!/usr/bin/env python3
"""Run a signed, funded local upgrade rehearsal after preparing the historical fixture.

Protocol sources are read from this repository and copied only into the explicitly
prepared temporary package. Dependency publications must remain separate.
"""

import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path
from urllib.parse import urlparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--sui", required=True)
parser.add_argument("--client-config", required=True)
parser.add_argument("--env", default="phase2")
parser.add_argument("--old-publication", type=Path, required=True)
parser.add_argument("--admin-evidence", type=Path, required=True)
parser.add_argument("--funded-evidence", type=Path, required=True)
parser.add_argument("--coin-publication", type=Path, required=True)
parser.add_argument("--package-path", type=Path, required=True)
parser.add_argument("--pubfile", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
cli = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
work = cli.package_path.resolve()
assert Path("/tmp") in work.parents and work != Path("/tmp"), (
    "Prepared temporary package only"
)
assert (work / "rehearsal-inputs.json").is_file(), (
    "Use prepare_upgrade_fixture.py first"
)
prepared = json.loads((work / "rehearsal-inputs.json").read_text())
for name, digest in prepared["historical_source_sha256"].items():
    assert hashlib.sha256((work / name).read_bytes()).hexdigest() == digest, name
base = [
    cli.sui,
    "client",
    "--client.config",
    cli.client_config,
    "--client.env",
    cli.env,
]
checked = subprocess.run(
    base + ["envs", "--json"], capture_output=True, text=True, check=True
)
rpc = next(e["rpc"] for e in json.loads(checked.stdout)[0] if e["alias"] == cli.env)
assert urlparse(rpc).hostname in ("127.0.0.1", "localhost", "::1"), "Localnet only"

f = json.loads((cli.funded_evidence / "fee-setup/fixture.json").read_text())
s = json.loads((cli.admin_evidence / "summary.json").read_text())
pub = json.loads(cli.old_publication.read_text())
created = json.loads(
    (cli.funded_evidence / "funded-pool/create-funded-pool.json").read_text()
)
position = next(
    o["objectId"]
    for o in created["objectChanges"]
    if o.get("objectType", "").endswith("::position::Position")
)
b = base
out = cli.output
out.mkdir(parents=True, exist_ok=False)


def q(cmd):
    r = subprocess.run(
        b + cmd + ["--json"], capture_output=True, text=True, timeout=120
    )
    assert r.returncode == 0, r.stdout + r.stderr
    j = json.loads(r.stdout)
    if "effects" in j:
        assert j["effects"]["status"]["status"] == "success", j
    return j


def save(label, j):
    (out / (label + ".json")).write_text(json.dumps(j, indent=2))


def snap():
    return {
        k: q(["object", v])
        for k, v in [
            ("config", f["config"]),
            ("pool", f["pool"]),
            ("position", position),
        ]
    }


def call(label, fun, args, sender):
    cmd = [
        "call",
        "--package",
        f["pkg"],
        "--module",
        "config",
        "--function",
        fun,
        "--args",
        *args,
        "--sender",
        sender,
        "--gas",
        f["gas"][sender],
        "--gas-budget",
        "100000000",
    ]
    j = q(cmd)
    save(label, dict(command=cmd, transaction=j))


call(
    "set-v14-gate",
    "update_package_version",
    [s["capability"], f["config"], "14"],
    f["other"],
)
save("before-pause", snap())
call("pause-v14", "emergency_pause", [f["config"]], f["owner"])
save("paused-before-upgrade", snap())
f.update(
    position=position,
    admin=s["capability"],
    upgrade_cap=next(
        o["objectId"]
        for o in pub["objectChanges"]
        if o.get("objectType", "") == "0x2::package::UpgradeCap"
    ),
)
save("fixture", f)
print("v14 funded state paused and snapshotted")

# Upgrade changes only the isolated copy; compatibility checking stays enabled.
source = repo / "packages" / "cetus_clmm" / "sources"
inputs = {
    "historical": prepared,
    "current_commit": subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=repo, text=True
    ).strip(),
    "current_source_sha256": {
        str(p.relative_to(source)): hashlib.sha256(p.read_bytes()).hexdigest()
        for p in source.rglob("*.move")
    },
    "toolchain": subprocess.check_output([cli.sui, "--version"], text=True).strip(),
    "limits": "Local source-based rehearsal, separately published dependencies, normalized metadata and synthetic funded state; not exact historical mainnet bytecode/state.",
}
save("inputs", inputs)
shutil.rmtree(work / "sources")
shutil.copytree(source, work / "sources")
cmd = [
    "test-upgrade",
    str(work),
    "--pubfile-path",
    str(cli.pubfile),
    "--build-env",
    "mainnet",
    "--upgrade-capability",
    f["upgrade_cap"],
    "--gas-budget",
    "1000000000",
]
receipt = q(cmd)
save("upgrade-command", {"command": cmd})
save("upgrade", receipt)
out = cli.output
f = json.loads((out / "fixture.json").read_text())
pkg = f["pkg"]
owner = f["owner"]
other = f["other"]
coin = f["coin"]
config = f["config"]
pool = f["pool"]
position = f["position"]
admin = f["admin"]
gas = f["gas"]
receipt = json.loads((out / "upgrade.json").read_text())
assert receipt["effects"]["status"]["status"] == "success"
newpkg = next(
    o["packageId"] for o in receipt["objectChanges"] if o["type"] == "published"
)
b = base
types = "<" + coin + ",0x2::sui::SUI>"


def run(cmd):
    return subprocess.run(
        b + cmd + ["--json"], capture_output=True, text=True, timeout=120
    )


def q(cmd):
    r = run(cmd)
    assert r.returncode == 0, r.stdout + r.stderr
    j = json.loads(r.stdout)
    if "effects" in j:
        assert j["effects"]["status"]["status"] == "success", j
    return j


def save(label, j):
    (out / (label + ".json")).write_text(json.dumps(j, indent=2))


def snap():
    return {
        k: q(["object", v])
        for k, v in [("config", config), ("pool", pool), ("position", position)]
    }


def unchanged(before, after):
    for k in before:
        assert (
            before[k]["content"] == after[k]["content"]
            and before[k]["owner"] == after[k]["owner"]
        ), k


save("upgrade", receipt)
before = json.loads((out / "paused-before-upgrade.json").read_text())
after = snap()
unchanged(before, after)
save("paused-after-upgrade", after)


def cfg(fun, args, sender=owner, pkg=newpkg):
    return [
        "call",
        "--package",
        pkg,
        "--module",
        "config",
        "--function",
        fun,
        "--args",
        *args,
        "--sender",
        sender,
        "--gas",
        gas[sender],
        "--gas-budget",
        "100000000",
    ]


def collect(sender, package=newpkg):
    return [
        "ptb",
        "--move-call",
        package + "::pool::collect_fee",
        types,
        "@" + config,
        "@" + pool,
        "@" + position,
        "true",
        "--assign",
        "fees",
        "--move-call",
        "0x2::coin::from_balance",
        "<" + coin + ">",
        "fees.0",
        "--assign",
        "ca",
        "--move-call",
        "0x2::coin::from_balance",
        "<0x2::sui::SUI>",
        "fees.1",
        "--assign",
        "cb",
        "--transfer-objects",
        "[ca,cb]",
        "@" + sender,
        "--sender",
        "@" + sender,
        "--gas-coin",
        "@" + gas[sender],
        "--gas-budget",
        "100000000",
    ]


def reject(label, cmd, error):
    before = snap()
    r = run(cmd)
    after = snap()
    assert r.returncode != 0 and error in r.stdout + r.stderr, r.stdout + r.stderr
    assert "Transaction was not signed" in error or "::config::" in r.stdout + r.stderr
    unchanged(before, after)
    save(
        label,
        dict(command=cmd, before=before, after=after, rejection=r.stdout + r.stderr),
    )


def success(label, cmd):
    before = snap()
    j = q(cmd)
    after = snap()
    save(label, dict(command=cmd, before=before, after=after, transaction=j))
    return j, before, after


reject("new-package-paused-claim", collect(other), "code 10")
reject("future-unpause-rejected", cfg("emergency_unpause", [config, "16"]), "code 16")
success("unpause-v15", cfg("emergency_unpause", [config, "15"]))
assert q(["object", config])["content"]["package_version"] == "15"
reject("old-package-retired-claim", collect(other, pkg), "code 10")
reject(
    "position-foreign-holder-rejected",
    collect(owner),
    "Transaction was not signed by the correct sender",
)
j, before, after = success("retained-position-claim", collect(other))
e = next(
    e["parsedJson"]
    for e in j["events"]
    if e["type"].endswith("::pool::CollectFeeEvent")
)
assert int(e["amount_a"]) + int(e["amount_b"]) > 0
for side in ["a", "b"]:
    assert int(before["pool"]["content"]["coin_" + side]) - int(
        after["pool"]["content"]["coin_" + side]
    ) == int(e["amount_" + side])
j, _, _ = success("repeat-claim-zero", collect(other))
e = next(
    e["parsedJson"]
    for e in j["events"]
    if e["type"].endswith("::pool::CollectFeeEvent")
)
assert int(e["amount_a"]) + int(e["amount_b"]) == 0
success(
    "transfer-retained-position",
    [
        "transfer",
        "--to",
        owner,
        "--object-id",
        position,
        "--sender",
        other,
        "--gas",
        gas[other],
        "--gas-budget",
        "100000000",
    ],
)
assert q(["object", position])["owner"] == {"AddressOwner": owner}
reject(
    "position-former-holder-rejected",
    collect(other),
    "Transaction was not signed by the correct sender",
)
success("position-new-holder-claim", collect(owner))
liquidity = q(["object", position])["content"]["liquidity"]
cmd = [
    "ptb",
    "--move-call",
    newpkg + "::pool::remove_liquidity",
    types,
    "@" + config,
    "@" + pool,
    "@" + position,
    str(liquidity),
    "@0x6",
    "--assign",
    "funds",
    "--move-call",
    "0x2::coin::from_balance",
    "<" + coin + ">",
    "funds.0",
    "--assign",
    "ca",
    "--move-call",
    "0x2::coin::from_balance",
    "<0x2::sui::SUI>",
    "funds.1",
    "--assign",
    "cb",
    "--transfer-objects",
    "[ca,cb]",
    "@" + owner,
    "--sender",
    "@" + owner,
    "--gas-coin",
    "@" + gas[owner],
    "--gas-budget",
    "100000000",
]
j, before, after = success("retained-position-full-exit", cmd)
e = next(
    e["parsedJson"]
    for e in j["events"]
    if e["type"].endswith("::pool::RemoveLiquidityV2Event")
)
assert int(after["position"]["content"]["liquidity"]) == 0
for side in ["a", "b"]:
    assert int(e["amount_" + side]) > 0
    assert int(before["pool"]["content"]["coin_" + side]) - int(
        after["pool"]["content"]["coin_" + side]
    ) == int(e["amount_" + side])
reject(
    "gate-downgrade-rejected",
    cfg("update_package_version", [admin, config, "14"], other),
    "code 16",
)
success("pause-v15-for-old-recovery-check", cfg("emergency_pause", [config]))
reject(
    "old-recovery-cannot-restore-v14",
    cfg("emergency_unpause", [config, "14"], pkg=pkg),
    "code 16",
)
success("resume-v15-after-interruption", cfg("emergency_unpause", [config, "15"]))
reject("unpause-replay-rejected", cfg("emergency_unpause", [config, "15"]), "code 14")
f["upgraded_package"] = newpkg
save("fixture", f)
print(
    "CLMM v14 to v15: preserved funded state, retired old entry, claimed fees once, transferred position and exited; interruption recovery verified"
)

summary = {
    "chain": q(["chain-identifier"]),
    "scope": "Preserved funded state, pause/resume, retired old entry, nonduplicating claims, position ownership transfer, full principal exit and recovery replay/downgrade rejection",
    "sha256": {
        str(p.relative_to(out)): hashlib.sha256(p.read_bytes()).hexdigest()
        for p in out.rglob("*.json")
        if p.name != "summary.json"
    },
}
save("summary", summary)
