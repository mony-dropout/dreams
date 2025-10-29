#!/usr/bin/env bash
set -euo pipefail
NX="packages/nextjs"

echo ">> Add /api/user/ensure"
mkdir -p "$NX/app/api/user/ensure"
cat > "$NX/app/api/user/ensure/route.ts" <<'TS'
export const runtime = "nodejs";
export const dynamic = "force-dynamic";

import { prisma } from "@/lib/db";
import { NextResponse } from "next/server";

// POST { address, name? } -> upsert user
export async function POST(req: Request) {
  try {
    const { address, name } = await req.json();
    if (!address) return NextResponse.json({ error: "address required" }, { status: 400 });
    const addr = String(address).toLowerCase();

    const user = await prisma.user.upsert({
      where: { address: addr },
      update: { name: name ?? undefined },
      create: { address: addr, name: name ?? null },
    });

    return NextResponse.json({ user }, { status: 200 });
  } catch (e: any) {
    return NextResponse.json({ error: String(e?.message || e) }, { status: 500 });
  }
}
TS

echo ">> Update TopNav label (Sign in)"
cat > "$NX/components/TopNavClient.tsx" <<'TSX'
"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

function Tab({ href, label }: { href: string; label: string }) {
  const pathname = usePathname();
  const active = pathname === href;
  return (
    <Link href={href} className={`px-3 py-1 rounded-xl border ${active ? "bg-white" : "bg-[var(--lavender-100)]"} border-[var(--lavender-300)]`}>
      {label}
    </Link>
  );
}

export default function TopNavClient() {
  const router = useRouter();
  return (
    <header className="sticky top-0 bg-[var(--lavender-50)]/90 backdrop-blur z-30 border-b border-[var(--lavender-200)]">
      <div className="max-w-4xl mx-auto px-4 py-3 flex items-center justify-between">
        <Link href="/" className="font-bold">Proof-of-Day</Link>
        <nav className="flex gap-2">
          <Tab href="/me" label="My Profile" />
          <Tab href="/discovery" label="Discovery" />
          <Tab href="/social" label="Social" />
          <button className="btn" onClick={()=>router.push("/me")}>Sign in</button>
        </nav>
      </div>
    </header>
  );
}
TSX

echo ">> Patch /me to: dev sign-in, upsert user, robust fetch, localStorage persistence"
cat > "$NX/app/me/page.tsx" <<'TSX'
"use client";

import { useEffect, useState } from "react";

type Goal = {
  id: string;
  title: string;
  scope: string;
  deadline: string;
  status: "PENDING" | "PASSED" | "FAILED";
  questionsJson?: { questions: string[] } | null;
  answersJson?: { a1?: string; a2?: string } | null;
  judgeResult?: string | null;
  attestationUid?: string | null;
  notes?: string | null;
};

async function fetchJSON(input: RequestInfo | URL, init?: RequestInit) {
  const r = await fetch(input, init);
  const txt = await r.text();
  let data: any = {};
  if (txt) {
    try { data = JSON.parse(txt); } catch (e) {
      console.error("Invalid JSON:", txt);
      throw e;
    }
  }
  if (!r.ok) throw new Error(data?.error || `HTTP ${r.status}`);
  return data;
}

export default function MePage() {
  // Dev sign-in (address + optional name). We persist locally and ensure user in DB.
  const [address, setAddress] = useState("");
  const [name, setName] = useState("");
  const [goals, setGoals] = useState<Goal[]>([]);
  const [title, setTitle] = useState("");
  const [scope, setScope] = useState("");
  const [deadline, setDeadline] = useState("");
  const [loading, setLoading] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);

  useEffect(() => {
    const addr = localStorage.getItem("pod_addr") || "";
    const nm = localStorage.getItem("pod_name") || "";
    if (addr) setAddress(addr);
    if (nm) setName(nm);
  }, []);

  useEffect(() => {
    if (address) refresh();
  }, [address]);

  async function ensureAccount() {
    if (!address) { setMsg("Enter an address to sign in."); return; }
    try {
      const d = await fetchJSON("/api/user/ensure", {
        method: "POST",
        headers: { "Content-Type":"application/json" },
        body: JSON.stringify({ address, name: name || undefined }),
      });
      localStorage.setItem("pod_addr", address);
      if (name) localStorage.setItem("pod_name", name);
      setMsg("Signed in.");
      await refresh();
    } catch (e:any) {
      setMsg(`Sign-in failed: ${e.message}`);
    }
  }

  async function refresh() {
    try {
      const d = await fetchJSON(`/api/goal?address=${encodeURIComponent(address)}`);
      setGoals(d.goals ?? []);
    } catch (e:any) {
      setMsg(`Load failed: ${e.message}`);
    }
  }

  async function createGoal() {
    if (!address) { setMsg("Sign in first."); return; }
    try {
      // ensure account exists
      await ensureAccount();
      // create
      await fetchJSON('/api/goal', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({ address, title, scope, deadline }),
      });
      setTitle(""); setScope(""); setDeadline("");
      await refresh();
      setMsg("Goal created.");
    } catch (e:any) {
      setMsg(`Create failed: ${e.message}`);
    }
  }

  async function getQuestions(g: Goal) {
    setLoading(true);
    try {
      await fetchJSON('/api/goal/questions', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({ goalId: g.id }),
      });
      await refresh();
      setMsg("Questions generated.");
    } catch (e:any) {
      setMsg(`Question gen failed: ${e.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-6">
      {msg && <div className="card">{msg}</div>}

      <div className="card">
        <h2 className="text-xl font-semibold mb-3">Sign in (dev)</h2>
        <div className="grid md:grid-cols-3 gap-3">
          <input className="input" placeholder="0x..." value={address} onChange={e=>setAddress(e.target.value)} />
          <input className="input" placeholder="Name (optional)" value={name} onChange={e=>setName(e.target.value)} />
          <button className="btn btn-primary" onClick={ensureAccount}>Create / Sign in</button>
        </div>
      </div>

      <div className="card">
        <h2 className="text-xl font-semibold mb-3">Start a Goal</h2>
        <div className="grid md:grid-cols-3 gap-3">
          <input className="input" placeholder="Title" value={title} onChange={e=>setTitle(e.target.value)} />
          <input className="input" placeholder="Scope (what counts?)" value={scope} onChange={e=>setScope(e.target.value)} />
          <input className="input" type="datetime-local" value={deadline} onChange={e=>setDeadline(e.target.value)} />
        </div>
        <div className="mt-3">
          <button className="btn btn-primary" onClick={createGoal} disabled={loading}>Create Goal</button>
        </div>
      </div>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold">Your goals</h3>
        {goals.length === 0 && <div className="text-sm opacity-70">No goals yet.</div>}
        {goals.map(g=>(
          <div key={g.id} className="card">
            <div className="flex justify-between">
              <div>
                <div className="font-semibold">{g.title}</div>
                <div className="text-sm opacity-70">{g.scope}</div>
                <div className="text-sm mt-1">Status: <b>{g.status}</b></div>
                {g.attestationUid && <div className="text-xs mt-1">Attestation: <code>{g.attestationUid.slice(0,10)}...</code></div>}
              </div>
              <div className="flex gap-2">
                {g.status === "PENDING" && (
                  <button className="btn" onClick={()=>getQuestions(g)} disabled={loading}>
                    {loading? "..." : "Take Quick-Check"}
                  </button>
                )}
              </div>
            </div>
          </div>
        ))}
      </section>
    </div>
  );
}
TSX
