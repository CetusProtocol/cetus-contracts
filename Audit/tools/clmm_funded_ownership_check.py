#!/usr/bin/env python3
import json, subprocess
from pathlib import Path
import argparse
from urllib.parse import urlparse

parser = argparse.ArgumentParser(
    description="Funded CLMM capability ownership controls on a disposable local network. Run after the AdminCap and PoolCreationCap probes."
)
parser.add_argument("--sui", required=True)
parser.add_argument("--client-config", required=True)
parser.add_argument("--env", default="phase2")
parser.add_argument("--admin-evidence", type=Path, required=True)
parser.add_argument("--creation-evidence", type=Path, required=True)
parser.add_argument("--coin-publication", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=False)
s = json.loads((args.admin_evidence / "summary.json").read_text())
p = json.loads((args.admin_evidence / "publication.json").read_text())
c = json.loads((args.creation_evidence / "summary.json").read_text())
cp = json.loads(args.coin_publication.read_text())
b = [
    args.sui,
    "client",
    "--client.config",
    args.client_config,
    "--client.env",
    args.env,
]


def run(a):
    return subprocess.run(
        b + a + ["--json"], capture_output=True, text=True, timeout=120
    )


def q(a):
    r = run(a)
    assert r.returncode == 0, r.stdout + r.stderr
    j = json.loads(r.stdout)
    if "effects" in j:
        assert j["effects"]["status"]["status"] == "success", j
    return j


rpc = next(e["rpc"] for e in q(["envs"])[0] if e["alias"] == args.env)
assert urlparse(rpc).hostname in ("127.0.0.1", "localhost", "::1"), "Localnet only"
pkg = s["package"]
owner = s["owner"]
other = s["other"]
coin = c["coin_type"]
cap = c["capability"]
types = "<" + coin + ",0x2::sui::SUI>"


def obj(suffix):
    return next(
        o["objectId"]
        for o in p["objectChanges"]
        if o.get("objectType", "").endswith(suffix)
    )


config = obj("::config::GlobalConfig")
pools = obj("::factory::Pools")
partners = obj("::partner::Partners")
gas = {a: q(["gas", a])["gasCoins"][0]["gasCoinId"] for a in [owner, other]}
out = args.output / "funded-pool"
out.mkdir(exist_ok=True)


def save(label, j):
    (out / (label + ".json")).write_text(json.dumps(j, indent=2))
    return j


def ptb(label, cmd, sender):
    return save(
        label,
        q(
            [
                "ptb",
                *cmd,
                "--sender",
                "@" + sender,
                "--gas-coin",
                "@" + gas[sender],
                "--gas-budget",
                "100000000",
            ]
        ),
    )


probe_coin = next(
    o["objectId"]
    for o in cp["objectChanges"]
    if o.get("objectType", "") == "0x2::coin::Coin<" + coin + ">"
)
j = ptb(
    "fund-new-holder",
    [
        "--split-coins",
        "@" + probe_coin,
        "[1000000000]",
        "--assign",
        "fund",
        "--transfer-objects",
        "[fund.0]",
        "@" + other,
    ],
    owner,
)
fund = next(
    o["objectId"]
    for o in j["objectChanges"]
    if o["type"] == "created"
    and o.get("objectType", "") == "0x2::coin::Coin<" + coin + ">"
)
j = ptb(
    "create-funded-pool",
    [
        "--split-coins",
        "gas",
        "[1000000000]",
        "--assign",
        "sui",
        "--move-call",
        pkg + "::pool_creator::create_pool_v3_with_creation_cap",
        types,
        "@" + config,
        "@" + pools,
        "@" + cap,
        "200",
        "18446744073709551616",
        '"local ownership"',
        "4294967096",
        "200",
        "@" + fund,
        "sui.0",
        "true",
        "@0x6",
        "--assign",
        "created",
        "--transfer-objects",
        "[created.0,created.1,created.2]",
        "@" + other,
    ],
    other,
)
save(
    "fixture",
    dict(
        pkg=pkg,
        owner=owner,
        other=other,
        coin=coin,
        cap=cap,
        config=config,
        pools=pools,
        partners=partners,
        gas=gas,
        pool=next(
            o["objectId"]
            for o in j["objectChanges"]
            if o["type"] == "created" and "::pool::Pool<" in o.get("objectType", "")
        ),
    ),
)
print("funded pool created using transferred PoolCreationCap")

f = json.loads((out / "fixture.json").read_text())
pool = f["pool"]

out = args.output / "fee-setup"
out.mkdir(exist_ok=True)


def save(label, j):
    (out / (label + ".json")).write_text(json.dumps(j, indent=2))
    return j


def call(label, fun, args, sender=owner, types=[]):
    return save(
        label,
        q(
            [
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
        ),
    )


def ptb(label, cmd, sender=owner):
    return save(
        label,
        q(
            [
                "ptb",
                *cmd,
                "--sender",
                "@" + sender,
                "--gas-coin",
                "@" + gas[sender],
                "--gas-budget",
                "100000000",
            ]
        ),
    )


j = call(
    "mint-fee-cap",
    "pool::mint_protocol_fee_collect_cap",
    [s["capability"], owner],
    other,
)
fee_cap = next(
    o["objectId"]
    for o in j["objectChanges"]
    if o.get("objectType", "").endswith("::pool::ProtocolFeeCollectCap")
)
call(
    "authorize-fee-cap",
    "config::set_roles",
    [s["capability"], config, fee_cap, "4"],
    other,
)
j = call(
    "create-partner",
    "partner::create_partner",
    [
        config,
        partners,
        "ownership-" + coin.split("::")[0],
        "1000",
        "9999999900",
        "9999999999",
        owner,
        "0x6",
    ],
)
partner = next(
    o["objectId"]
    for o in j["objectChanges"]
    if o.get("objectType", "").endswith("::partner::Partner")
)
partner_cap = next(
    o["objectId"]
    for o in j["objectChanges"]
    if o.get("objectType", "").endswith("::partner::PartnerCap")
)
call(
    "activate-partner",
    "partner::update_time_range",
    [config, partner, "0", "9999999999", "0x6"],
)
probe_coin = next(
    o["objectId"]
    for o in cp["objectChanges"]
    if o.get("objectType", "") == "0x2::coin::Coin<" + coin + ">"
)
types = "<" + coin + ",0x2::sui::SUI>"
j = ptb(
    "fund-fees-through-swap",
    [
        "--move-call",
        pkg + "::pool::flash_swap_with_partner",
        types,
        "@" + config,
        "@" + pool,
        "@" + partner,
        "true",
        "true",
        "1000000",
        "4295048016",
        "@0x6",
        "--assign",
        "sw",
        "--move-call",
        pkg + "::pool::swap_pay_amount",
        types,
        "sw.2",
        "--assign",
        "pay",
        "--split-coins",
        "@" + probe_coin,
        "[pay]",
        "--assign",
        "payment",
        "--move-call",
        "0x2::coin::into_balance",
        "<" + coin + ">",
        "payment.0",
        "--assign",
        "ba",
        "--move-call",
        "0x2::balance::zero",
        "<0x2::sui::SUI>",
        "--assign",
        "bb",
        "--move-call",
        pkg + "::pool::repay_flash_swap_with_partner",
        types,
        "@" + config,
        "@" + pool,
        "@" + partner,
        "ba",
        "bb",
        "sw.2",
        "--move-call",
        "0x2::coin::from_balance",
        "<" + coin + ">",
        "sw.0",
        "--assign",
        "ca",
        "--move-call",
        "0x2::coin::from_balance",
        "<0x2::sui::SUI>",
        "sw.1",
        "--assign",
        "cb",
        "--transfer-objects",
        "[ca,cb]",
        "@" + owner,
    ],
)
f.update(
    fee_cap=fee_cap, partner=partner, partner_cap=partner_cap, probe_coin=probe_coin
)
save("fixture", f)
print("funded fee and partner fixture ready")

out = args.output / "controls"
out.mkdir()
types = "<" + coin + ",0x2::sui::SUI>"


def cmd_for(kind, who):
    if kind == "fee":
        cmd = [
            "--move-call",
            pkg + "::pool::collect_protocol_fee_with_cap",
            types,
            "@" + pool,
            "@" + config,
            "@" + fee_cap,
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
            "@" + who,
        ]
    else:
        cmd = [
            "--move-call",
            pkg + "::partner::claim_ref_fee",
            "<" + coin + ">",
            "@" + config,
            "@" + partner_cap,
            "@" + partner,
        ]
    return [
        "ptb",
        *cmd,
        "--sender",
        "@" + who,
        "--gas-coin",
        "@" + gas[who],
        "--gas-budget",
        "100000000",
    ]


def snap(cap):
    return {
        x: q(["object", oid])
        for x, oid in [
            ("cap", cap),
            ("pool", pool),
            ("partner", partner),
            ("config", config),
        ]
    }


def attempt(kind, label, who, success, positive=True):
    cap = fee_cap if kind == "fee" else partner_cap
    before = snap(cap)
    cmd = cmd_for(kind, who)
    r = run(cmd)
    after = snap(cap)
    record = dict(command=cmd, before=before, after=after, exit_code=r.returncode)
    if success:
        assert r.returncode == 0, r.stdout + r.stderr
        tx = json.loads(r.stdout)
        assert tx["effects"]["status"]["status"] == "success", tx
        events = [
            e["parsedJson"]
            for e in tx["events"]
            if "CollectProtocolFeeEvent" in e["type"] or "ClaimRefFeeEvent" in e["type"]
        ]
        assert events, tx
        values = [
            int(v)
            for e in events
            for k, v in e.items()
            if k in ["amount", "amount_a", "amount_b"]
        ]
        if positive:
            assert sum(values) > 0, events
        else:
            assert sum(values) == 0, events
        if kind == "fee":
            before_pool = before["pool"]["content"]
            after_pool = after["pool"]["content"]
            for balance_field, fee_field, event_field in zip(
                ["coin_a", "coin_b"],
                ["fee_protocol_coin_a", "fee_protocol_coin_b"],
                ["amount_a", "amount_b"],
            ):
                amount = int(events[0][event_field])
                assert int(before_pool[fee_field]) == amount
                assert int(after_pool[fee_field]) == 0
                assert (
                    int(before_pool[balance_field]) - int(after_pool[balance_field])
                    == amount
                )
        record["transaction"] = tx
    else:
        reject = r.stdout + r.stderr
        assert (
            r.returncode != 0
            and "Transaction was not signed by the correct sender" in reject
        )
        assert cap in reject and who in reject and before == after
        record["rejection"] = reject
    save(kind + "-" + label, record)


for kind in ["fee", "partner"]:
    cap = fee_cap if kind == "fee" else partner_cap
    attempt(kind, "nonowner-rejected", other, False)
    attempt(kind, "owner-accepted", owner, True)
    if kind == "fee":
        before = snap(cap)
        cmd = cmd_for(kind, owner)
        r = run(cmd)
        after = snap(cap)
        assert (
            r.returncode != 0
            and "collect_protocol_fee_internal" in r.stdout + r.stderr
            and "code 33" in r.stdout + r.stderr
        )
        assert before["pool"]["content"] == after["pool"]["content"]
        save(
            "fee-repeat-rejected",
            dict(
                command=cmd, before=before, after=after, rejection=r.stdout + r.stderr
            ),
        )
    tx = q(
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
    save(kind + "-transfer", tx)
    assert q(["object", cap])["owner"] == {"AddressOwner": other}
    attempt(kind, "former-owner-rejected", owner, False)
# Refill through the same funded production swap so the new holder must receive real value.
cmd = [
    "ptb",
    "--move-call",
    pkg + "::pool::flash_swap_with_partner",
    types,
    "@" + config,
    "@" + pool,
    "@" + partner,
    "true",
    "true",
    "1000000",
    "4295048016",
    "@0x6",
    "--assign",
    "sw",
    "--move-call",
    pkg + "::pool::swap_pay_amount",
    types,
    "sw.2",
    "--assign",
    "pay",
    "--split-coins",
    "@" + probe_coin,
    "[pay]",
    "--assign",
    "payment",
    "--move-call",
    "0x2::coin::into_balance",
    "<" + coin + ">",
    "payment.0",
    "--assign",
    "ba",
    "--move-call",
    "0x2::balance::zero",
    "<0x2::sui::SUI>",
    "--assign",
    "bb",
    "--move-call",
    pkg + "::pool::repay_flash_swap_with_partner",
    types,
    "@" + config,
    "@" + pool,
    "@" + partner,
    "ba",
    "bb",
    "sw.2",
    "--move-call",
    "0x2::coin::from_balance",
    "<" + coin + ">",
    "sw.0",
    "--assign",
    "ca",
    "--move-call",
    "0x2::coin::from_balance",
    "<0x2::sui::SUI>",
    "sw.1",
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
save("refill-fees", q(cmd))
for kind in ["fee", "partner"]:
    attempt(kind, "new-owner-accepted", other, True)
print("Both fee capabilities passed signed funded ownership lifecycle controls")

import hashlib

summary = {
    "chain": q(["chain-identifier"]),
    "package": pkg,
    "scope": "Funded PoolCreationCap creation; ProtocolFeeCollectCap and PartnerCap signed holder/foreign-holder/transfer/former-holder/new-holder controls",
    "sha256": {
        str(p.relative_to(args.output)): hashlib.sha256(p.read_bytes()).hexdigest()
        for p in args.output.rglob("*.json")
    },
}
(args.output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
