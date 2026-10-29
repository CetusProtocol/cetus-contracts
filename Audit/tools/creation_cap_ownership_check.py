#!/usr/bin/env python3
"""Signed PoolCreationCap controls against a local production CLMM publication.

Requires the AdminCap ownership probe first and a separately published ownership_coin
fixture. Exercises register/unregister of a real PROBE/SUI permission pair.
"""

import argparse
import hashlib
import json
import subprocess
from pathlib import Path
from urllib.parse import urlparse


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--sui", required=True)
    p.add_argument("--client-config", required=True)
    p.add_argument("--env", default="phase2")
    p.add_argument("--admin-evidence", type=Path, required=True)
    p.add_argument("--coin-publication", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    p.add_argument(
        "--initialize-factory",
        action="store_true",
        help="Initialize the factory on a fresh local publication",
    )
    a = p.parse_args()
    base = [a.sui, "client", "--client.config", a.client_config, "--client.env", a.env]

    def run(words):
        return subprocess.run(
            base + words + ["--json"], capture_output=True, text=True, timeout=120
        )

    def query(words):
        r = run(words)
        assert r.returncode == 0, r.stdout + r.stderr
        j = json.loads(r.stdout)
        if "effects" in j:
            assert j["effects"]["status"]["status"] == "success", j
        return j

    rpc = next(e["rpc"] for e in query(["envs"])[0] if e["alias"] == a.env)
    assert urlparse(rpc).hostname in ("localhost", "127.0.0.1", "::1"), "Localnet only"
    s = json.loads((a.admin_evidence / "summary.json").read_text())
    pub = json.loads((a.admin_evidence / "publication.json").read_text())
    coin_pub = json.loads(a.coin_publication.read_text())
    owner, other, pkg = s["owner"], s["other"], s["package"]

    def obj(suffix):
        return next(
            o["objectId"]
            for o in pub["objectChanges"]
            if o.get("objectType", "").endswith(suffix)
        )

    config, pools = obj("::config::GlobalConfig"), obj("::factory::Pools")
    coin_pkg = next(
        o["packageId"] for o in coin_pub["objectChanges"] if o["type"] == "published"
    )
    coin = coin_pkg + "::probe::PROBE"
    gas = {
        addr: query(["gas", addr])["gasCoins"][0]["gasCoinId"]
        for addr in (owner, other)
    }
    out = a.output
    out.mkdir(parents=True, exist_ok=False)

    def save(label, data):
        (out / (label + ".json")).write_text(json.dumps(data, indent=2) + "\n")

    def call(fun, args, sender, types=None):
        return [
            "call",
            "--package",
            pkg,
            "--module",
            fun.split("::")[0],
            "--function",
            fun.split("::")[1],
            "--args",
            *args,
            *(["--type-args", *types] if types else []),
            "--sender",
            sender,
            "--gas",
            gas[sender],
            "--gas-budget",
            "100000000",
        ]

    save(
        "grant-setup-role",
        query(
            call("config::set_roles", [s["capability"], config, owner, "127"], other)
        ),
    )
    if a.initialize_factory:
        save(
            "initialize-factory",
            query(call("factory::init_manager_and_whitelist", [config, pools], owner)),
        )
    cmd = [
        "ptb",
        "--move-call",
        pkg + "::factory::mint_pool_creation_cap_by_admin",
        "<" + coin + ">",
        "@" + config,
        "@" + pools,
        "--assign",
        "cap",
        "--transfer-objects",
        "[cap]",
        "@" + owner,
        "--sender",
        "@" + owner,
        "--gas-coin",
        "@" + gas[owner],
        "--gas-budget",
        "100000000",
    ]
    mint = query(cmd)
    save("mint", mint)
    cap = next(
        o["objectId"]
        for o in mint["objectChanges"]
        if o.get("objectType", "").endswith("::factory::PoolCreationCap")
    )

    def snapshot():
        return {
            name: query(["object", oid])
            for name, oid in [("cap", cap), ("pools", pools), ("config", config)]
        }

    results = []

    def attempt(label, sender, fun, success):
        before = snapshot()
        cmd = call(
            "factory::" + fun,
            [config, pools, "200", cap],
            sender,
            [coin, "0x2::sui::SUI"],
        )
        r = run(cmd)
        after = snapshot()
        record = dict(command=cmd, before=before, after=after, exit_code=r.returncode)
        if success:
            assert r.returncode == 0, r.stdout + r.stderr
            tx = json.loads(r.stdout)
            assert tx["effects"]["status"]["status"] == "success", tx
            event = "::factory::" + (
                "UnregisterPermissionPairEvent"
                if fun.startswith("unregister")
                else "RegisterPermissionPairEvent"
            )
            assert any(
                e["type"].endswith(event) and e["parsedJson"]["cap"] == cap
                for e in tx["events"]
            )
            assert int(after["pools"]["version"]) > int(before["pools"]["version"])
            record["transaction"] = tx
        else:
            rejection = r.stdout + r.stderr
            assert (
                r.returncode != 0
                and "Transaction was not signed by the correct sender" in rejection
            )
            assert cap in rejection and sender in rejection
            assert before == after
            record["rejection"] = rejection
        save(label, record)
        results.append(dict(case=label, expected_result_observed=True))

    attempt("owner-register-accepted", owner, "register_permission_pair", True)
    attempt("nonowner-unregister-rejected", other, "unregister_permission_pair", False)
    transfer = query(
        [
            "transfer",
            "--to",
            other,
            "--object-id",
            cap,
            "--sender",
            owner,
            "--gas",
            gas[owner],
            "--gas-budget",
            "100000000",
        ]
    )
    assert query(["object", cap])["owner"] == {"AddressOwner": other}
    save("transfer", transfer)
    attempt(
        "former-owner-unregister-rejected", owner, "unregister_permission_pair", False
    )
    attempt("new-owner-unregister-accepted", other, "unregister_permission_pair", True)
    attempt("new-owner-register-accepted", other, "register_permission_pair", True)
    save("coin-publication", coin_pub)
    summary = dict(
        chain=query(["chain-identifier"]),
        package=pkg,
        capability=cap,
        coin_type=coin,
        cases=results,
        limits="PoolCreationCap register/unregister ownership; funded pool creation is separate.",
        sha256={
            f.name: hashlib.sha256(f.read_bytes()).hexdigest()
            for f in out.glob("*.json")
        },
    )
    save("summary", summary)
    print("PoolCreationCap: five signed controls and transfer passed")


if __name__ == "__main__":
    main()
