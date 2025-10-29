#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
NX="$ROOT/packages/nextjs"

echo ">> Creating folders"
mkdir -p "$ROOT/scripts"
mkdir -p "$NX/app"
mkdir -p "$NX/app/me"
mkdir -p "$NX/app/discovery"
mkdir -p "$NX/app/social"
mkdir -p "$NX/app/u" && mkdir -p "$NX/app/u/[address]"
mkdir -p "$NX/app/api/goal"
mkdir -p "$NX/app/api/goal/questions"
mkdir -p "$NX/app/api/goal/evaluate"
mkdir -p "$NX/components"
mkdir -p "$NX/lib"
mkdir -p "$NX/styles"
mkdir -p "$NX/prisma"

echo ">> Writing env template"
cat > "$NX/.env.local" <<'ENV'
# --- Required ---
# Postgres (Neon or Vercel Postgres)
DATABASE_URL="postgresql://<user>:<password>@<host>/<db>?sslmode=require"

# OpenAI (for questions + evaluation)
OPENAI_API_KEY="sk-..."

# EAS / chain (Base Sepolia recommended for demo)
RPC_URL_BASE_SEPOLIA="https://sepolia.base.org"
PLATFORM_PRIVATE_KEY="0xYOUR_TEST_WALLET_PRIVATE_KEY"
EAS_CONTRACT_ADDRESS="0x4200000000000000000000000000000000000021" # example; set real one
EAS_SCHEMA_ID="0xSCHEMA_ID" # your schema id once created

# App
NEXT_PUBLIC_APP_NAME="Proof-of-Day"
ENV

echo ">> Writing Prisma schema"
cat > "$NX/prisma/schema.prisma" <<'PRISMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum GoalStatus {
  PENDING
  PASSED
  FAILED
}

model User {
  id        String  @id @default(uuid())
  address   String  @unique
  name      String?
  createdAt DateTime @default(now())
  goals     Goal[]
}

model Goal {
  id             String     @id @default(uuid())
  user           User       @relation(fields: [userId], references: [id])
  userId         String
  title          String
  scope          String
  deadline       DateTime
  status         GoalStatus @default(PENDING)
  questionsJson  Json?
  answersJson    Json?
  judgeResult    String?    // "PASS" | "FAIL" | message
  attestationUid String?
  notes          String?    // free-form user notes
  createdAt      DateTime   @default(now())
  updatedAt      DateTime   @updatedAt

  @@index([userId])
  @@index([status, deadline])
}
PRISMA

echo ">> Adding libs"
cat > "$NX/lib/db.ts" <<'TS'
import { PrismaClient } from '@prisma/client';

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient };

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: ['error', 'warn'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
TS

cat > "$NX/lib/openai.ts" <<'TS'
import OpenAI from "openai";

export const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY!,
});

export async function genQuestions(goal: string, scope: string) {
  const sys = `You are "Proof-of-Day Quick-Check", a generator of TWO simple, concrete questions to verify someone likely completed a stated goal. 
Return strict JSON: {"questions":["Q1","Q2"]} with no extra text. Keep questions short and check real understanding.`;
  const user = JSON.stringify({ goal, scope });
  const r = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    temperature: 0.2,
    messages: [
      { role: "system", content: sys },
      { role: "user", content: user },
    ],
    response_format: { type: "json_object" },
  });
  const content = r.choices[0].message?.content ?? "{}";
  return JSON.parse(content);
}

export async function judgeAnswers(payload: {
  goal: string; scope: string; q1: string; q2: string; a1: string; a2: string;
}) {
  const sys = `You are "Proof-of-Day Judge". Decide PASS or FAIL based on whether answers plausibly show the goal was done.
Extremely lenient. Only FAIL if clearly bogus or unrelated. 
Return strict JSON: {"result":"PASS"} or {"result":"FAIL"} with optional {"reason":"..."} (short).`;
  const user = JSON.stringify(payload);
  const r = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    temperature: 0,
    messages: [
      { role: "system", content: sys },
      { role: "user", content: user },
    ],
    response_format: { type: "json_object" },
  });
  const content = r.choices[0].message?.content ?? "{}";
  return JSON.parse(content);
}
TS

cat > "$NX/lib/eas.ts" <<'TS'
import { ethers } from "ethers";
// Using EAS SDK is ideal: import { EAS, SchemaEncoder } from "@ethereum-attestation-service/eas-sdk";
// But to keep this scaffold minimal and compile-safe without extra wiring,
// we'll expose a stub that pretends to attest if envs aren't present.

export async function attestGoal(params: {
  goalId: string;
  result: "PASS" | "FAIL";
}) {
  const rpc = process.env.RPC_URL_BASE_SEPOLIA;
  const pk = process.env.PLATFORM_PRIVATE_KEY;
  const contract = process.env.EAS_CONTRACT_ADDRESS;
  const schemaId = process.env.EAS_SCHEMA_ID;

  if (!rpc || !pk || !contract || !schemaId) {
    // Demo fallback
    return { uid: "0xDEMO_ATTESTATION_UID_NO_ENV_SET" };
  }

  // Minimal raw tx sketch (replace with EAS SDK in your next pass)
  const provider = new ethers.JsonRpcProvider(rpc);
  const wallet = new ethers.Wallet(pk, provider);

  // ... integrate EAS SDK properly here later.
  // return actual UID from EAS when wired.
  // For now, produce a deterministic fake-ish hash:
  const uid = ethers.keccak256(ethers.toUtf8Bytes(`${params.goalId}:${params.result}:${Date.now()}`));
  return { uid };
}
TS

echo ">> Writing global CSS + layouts + components"
cat > "$NX/app/globals.css" <<'CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Lavender theme */
:root {
  --lavender-50: #f6f5fb;
  --lavender-100: #ebe9f7;
  --lavender-200: #d7d3ef;
  --lavender-300: #beb6e3;
  --lavender-400: #a195d6;
  --lavender-500: #8b7dcb;
  --lavender-600: #7a6bc0;
  --lavender-700: #6958b6;
  --lavender-800: #5746a7;
  --lavender-900: #463a87;
}

body {
  background: var(--lavender-50);
  color: #171717;
}

.card {
  @apply rounded-2xl border bg-white shadow-sm p-5;
  border-color: var(--lavender-200);
}

.btn {
  @apply px-4 py-2 rounded-xl font-medium border;
  border-color: var(--lavender-300);
  background: var(--lavender-100);
}

.btn-primary {
  background: var(--lavender-700);
  color: white;
  border-color: var(--lavender-800);
}

.input, .textarea, .select {
  @apply w-full rounded-xl border px-3 py-2;
  border-color: var(--lavender-300);
  background: white;
}
CSS

cat > "$NX/app/layout.tsx" <<'TSX'
import "./globals.css";
import TopNavClient from "@/components/TopNavClient";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <TopNavClient />
        <main className="max-w-4xl mx-auto p-4">{children}</main>
      </body>
    </html>
  );
}
TSX

cat > "$NX/components/TopNavClient.tsx" <<'TSX'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";

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
  const [menuOpen] = useState(false);
  return (
    <header className="sticky top-0 bg-[var(--lavender-50)]/90 backdrop-blur z-30 border-b border-[var(--lavender-200)]">
      <div className="max-w-4xl mx-auto px-4 py-3 flex items-center justify-between">
        <Link href="/" className="font-bold">Proof-of-Day</Link>
        <nav className="flex gap-2">
          <Tab href="/me" label="My Profile" />
          <Tab href="/discovery" label="Discovery" />
          <Tab href="/social" label="Social" />
          <Link href="/me" className="btn">Sign in</Link>
        </nav>
      </div>
    </header>
  );
}
TSX

echo ">> Writing pages"

# Home (redirect suggestions)
cat > "$NX/app/page.tsx" <<'TSX'
import Link from "next/link";

export default function Home() {
  return (
    <div className="space-y-6">
      <div className="card">
        <h1 className="text-2xl font-bold mb-2">Welcome to Proof-of-Day</h1>
        <p>Track goals, answer a two-question quick-check, and (optionally) write an on-chain attestation.</p>
      </div>
      <div className="grid md:grid-cols-3 gap-4">
        <Link className="card" href="/me"><div className="font-semibold">My Profile</div><div>Create goals and manage your progress.</div></Link>
        <Link className="card" href="/discovery"><div className="font-semibold">Discovery</div><div>Find public profiles.</div></Link>
        <Link className="card" href="/social"><div className="font-semibold">Social Feed</div><div>Latest goals across users.</div></Link>
      </div>
    </div>
  );
}
TSX

# /me
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

export default function MePage() {
  // For now we let user type their address explicitly (replace with wallet connect later)
  const [address, setAddress] = useState("");
  const [goals, setGoals] = useState<Goal[]>([]);
  const [title, setTitle] = useState("");
  const [scope, setScope] = useState("");
  const [deadline, setDeadline] = useState("");

  // Q&A state
  const [active, setActive] = useState<Goal | null>(null);
  const [q1, setQ1] = useState(""); const [q2, setQ2] = useState("");
  const [a1, setA1] = useState(""); const [a2, setA2] = useState("");
  const [loading, setLoading] = useState(false);

  async function refresh() {
    if (!address) return;
    const r = await fetch(`/api/goal?address=${address}`);
    const d = await r.json();
    setGoals(d.goals ?? []);
  }

  useEffect(() => { refresh(); }, [address]);

  async function createGoal() {
    if (!address) return alert("Enter your address");
    const r = await fetch('/api/goal', {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({ address, title, scope, deadline }),
    });
    await r.json();
    setTitle(""); setScope(""); setDeadline("");
    await refresh();
  }

  async function getQuestions(g: Goal) {
    setLoading(true);
    const r = await fetch('/api/goal/questions', {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({ goalId: g.id }),
    });
    const d = await r.json(); setLoading(false);
    const qs = d.questions?.questions ?? [];
    setQ1(qs[0] || ""); setQ2(qs[1] || "");
    setA1(""); setA2("");
    setActive(g);
  }

  async function submitAnswers() {
    if (!active) return;
    setLoading(true);
    const r = await fetch('/api/goal/evaluate', {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({ goalId: active.id, a1, a2 }),
    });
    await r.json(); setLoading(false);
    setActive(null);
    await refresh();
  }

  return (
    <div className="space-y-6">
      <div className="card">
        <h2 className="text-xl font-semibold mb-3">Your Address</h2>
        <input className="input" placeholder="0x..." value={address} onChange={e=>setAddress(e.target.value)} />
      </div>

      <div className="card">
        <h2 className="text-xl font-semibold mb-3">Start a Goal</h2>
        <div className="grid md:grid-cols-3 gap-3">
          <input className="input" placeholder="Title" value={title} onChange={e=>setTitle(e.target.value)} />
          <input className="input" placeholder="Scope (what counts?)" value={scope} onChange={e=>setScope(e.target.value)} />
          <input className="input" type="datetime-local" value={deadline} onChange={e=>setDeadline(e.target.value)} />
        </div>
        <div className="mt-3">
          <button className="btn btn-primary" onClick={createGoal}>Create Goal</button>
        </div>
      </div>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold">Your goals</h3>
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

      {active && (
        <div className="card">
          <h3 className="font-semibold mb-2">Quick-Check</h3>
          <div className="space-y-3">
            <div><span className="font-medium">Q1:</span> {q1}</div>
            <textarea className="textarea" rows={3} value={a1} onChange={e=>setA1(e.target.value)} placeholder="Your answer to Q1" />
            <div><span className="font-medium">Q2:</span> {q2}</div>
            <textarea className="textarea" rows={3} value={a2} onChange={e=>setA2(e.target.value)} placeholder="Your answer to Q2" />
            <button className="btn btn-primary" onClick={submitAnswers} disabled={loading}>{loading? "Submitting..." : "Submit Answers"}</button>
          </div>
        </div>
      )}
    </div>
  );
}
TSX

# /u/[address] (public profile)
cat > "$NX/app/u/[address]/page.tsx" <<'TSX'
import { prisma } from "@/lib/db";

export default async function PublicProfile({ params }: { params: { address: string } }) {
  const address = params.address.toLowerCase();
  const user = await prisma.user.findUnique({
    where: { address },
    include: { goals: { orderBy: { createdAt: "desc" } } },
  });

  if (!user) {
    return <div className="card">No user found for <code>{address}</code>.</div>;
  }

  const total = user.goals.length;
  const passed = user.goals.filter(g=>g.status==="PASSED").length;
  const pct = total ? Math.round((passed/total)*100) : 0;

  // Simple streak calc
  let maxStreak = 0, cur = 0;
  for (const g of user.goals) {
    if (g.status==="PASSED") { cur++; maxStreak = Math.max(maxStreak, cur); }
    else cur = 0;
  }
  const currentStreak = cur;

  return (
    <div className="space-y-6">
      <div className="card">
        <div className="text-xl font-semibold">Public profile</div>
        <div className="opacity-70 text-sm">Address: <code>{user.address}</code></div>
        <div className="mt-2 text-sm">Passed: {passed}/{total} ({pct}%) • Max streak: {maxStreak} • Current streak: {currentStreak}</div>
      </div>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold">Goals</h3>
        {user.goals.map(g=>(
          <div key={g.id} className="card">
            <div className="font-semibold">{g.title}</div>
            <div className="text-sm opacity-70">{g.scope}</div>
            <div className="text-sm mt-1">Status: <b>{g.status}</b></div>
            {g.attestationUid && <div className="text-xs mt-1">Attestation: <code>{g.attestationUid.slice(0,10)}...</code></div>}
            {g.questionsJson && g.answersJson && (
              <details className="mt-2">
                <summary className="cursor-pointer">See notes</summary>
                <div className="mt-2 text-sm whitespace-pre-wrap">
                  Q1: {g.questionsJson?.questions?.[0] || ""}\n
                  A1: {(g.answersJson as any)?.a1 || ""}\n
                  Q2: {g.questionsJson?.questions?.[1] || ""}\n
                  A2: {(g.answersJson as any)?.a2 || ""}\n
                  Judge: {g.judgeResult || ""}
                </div>
              </details>
            )}
          </div>
        ))}
      </section>
    </div>
  );
}
TSX

# /discovery
cat > "$NX/app/discovery/page.tsx" <<'TSX'
"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

export default function Discovery() {
  const [q, setQ] = useState("");
  const [rows, setRows] = useState<any[]>([]);

  async function search() {
    const r = await fetch('/api/goal?discover='+encodeURIComponent(q));
    const d = await r.json();
    setRows(d.users || []);
  }

  useEffect(()=>{ search(); }, []);

  return (
    <div className="space-y-4">
      <div className="card">
        <div className="font-semibold mb-2">Search users</div>
        <div className="flex gap-2">
          <input className="input" placeholder="address (0x...) or name contains" value={q} onChange={e=>setQ(e.target.value)} />
          <button className="btn btn-primary" onClick={search}>Search</button>
        </div>
      </div>
      <div className="space-y-2">
        {rows.map(u=>(
          <div key={u.address} className="card flex items-center justify-between">
            <div>
              <div className="font-semibold">{u.name || "(no name)"}</div>
              <div className="text-sm opacity-70"><code>{u.address}</code></div>
            </div>
            <Link className="btn" href={`/u/${u.address}`}>Open</Link>
          </div>
        ))}
      </div>
    </div>
  );
}
TSX

# /social
cat > "$NX/app/social/page.tsx" <<'TSX'
import { prisma } from "@/lib/db";
import Link from "next/link";

export default async function Social() {
  const goals = await prisma.goal.findMany({
    orderBy: { createdAt: "desc" },
    take: 50,
    include: { user: true },
  });

  return (
    <div className="space-y-4">
      {goals.map(g=>(
        <div key={g.id} className="card">
          <div className="flex items-center justify-between">
            <div>
              <div className="font-semibold">{g.title} <span className="text-xs opacity-70">({g.status})</span></div>
              <div className="text-sm opacity-70">{g.scope}</div>
              <div className="text-xs mt-1">By <Link className="underline" href={`/u/${g.user.address}`}>{g.user.address.slice(0,8)}…</Link></div>
            </div>
            {g.attestationUid && <div className="text-xs">Attn: <code>{g.attestationUid.slice(0,10)}...</code></div>}
          </div>
        </div>
      ))}
    </div>
  );
}
TSX

echo ">> API routes"

# GET /api/goal?address=0x.. -> list; POST /api/goal -> create
# GET /api/goal?discover=xxx -> discovery
cat > "$NX/app/api/goal/route.ts" <<'TS'
import { prisma } from "@/lib/db";
import { NextResponse } from "next/server";

// Query:
// - ?address=0x... => list goals for that address (creates user if not exists on POST via /me UI)
// - ?discover=term => list users by partial match
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const address = searchParams.get("address");
  const discover = searchParams.get("discover");

  if (address) {
    const user = await prisma.user.findUnique({
      where: { address: address.toLowerCase() },
      include: { goals: { orderBy: { createdAt: "desc" } } },
    });
    return NextResponse.json({ goals: user?.goals ?? [] });
  }

  if (discover !== null) {
    const term = discover.trim().toLowerCase();
    const users = await prisma.user.findMany({
      where: term ? {
        OR: [
          { address: { contains: term } },
          { name: { contains: term } },
        ]
      } : {},
      orderBy: { createdAt: "desc" },
      take: 50,
      select: { address: true, name: true },
    });
    return NextResponse.json({ users });
  }

  return NextResponse.json({ ok: true });
}

export async function POST(req: Request) {
  const body = await req.json();
  const { address, title, scope, deadline } = body;
  if (!address || !title || !scope || !deadline) {
    return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  }
  const addr = String(address).toLowerCase();
  const user = await prisma.user.upsert({
    where: { address: addr },
    update: {},
    create: { address: addr },
  });

  const goal = await prisma.goal.create({
    data: {
      userId: user.id,
      title,
      scope,
      deadline: new Date(deadline),
      status: "PENDING",
    }
  });

  return NextResponse.json({ goal });
}
TS

# POST /api/goal/questions -> {goalId}
cat > "$NX/app/api/goal/questions/route.ts" <<'TS'
import { prisma } from "@/lib/db";
import { genQuestions } from "@/lib/openai";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  const { goalId } = await req.json();
  if (!goalId) return NextResponse.json({ error: "goalId required" }, { status: 400 });

  const goal = await prisma.goal.findUnique({ where: { id: goalId } });
  if (!goal) return NextResponse.json({ error: "goal not found" }, { status: 404 });

  const questions = await genQuestions(goal.title, goal.scope);
  await prisma.goal.update({
    where: { id: goalId },
    data: { questionsJson: questions },
  });

  return NextResponse.json({ questions });
}
TS

# POST /api/goal/evaluate -> {goalId, a1, a2}
cat > "$NX/app/api/goal/evaluate/route.ts" <<'TS'
import { prisma } from "@/lib/db";
import { judgeAnswers } from "@/lib/openai";
import { attestGoal } from "@/lib/eas";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  const { goalId, a1, a2 } = await req.json();
  if (!goalId) return NextResponse.json({ error: "goalId required" }, { status: 400 });

  const goal = await prisma.goal.findUnique({ where: { id: goalId }, include: { user: true } });
  if (!goal) return NextResponse.json({ error: "goal not found" }, { status: 404 });
  if (!goal.questionsJson) return NextResponse.json({ error: "questions not generated yet" }, { status: 400 });

  const q1 = (goal.questionsJson as any)?.questions?.[0] || "";
  const q2 = (goal.questionsJson as any)?.questions?.[1] || "";

  const judge = await judgeAnswers({
    goal: goal.title,
    scope: goal.scope,
    q1, q2,
    a1: a1 ?? "",
    a2: a2 ?? "",
  });

  const result = (String(judge.result || "").toUpperCase() === "PASS") ? "PASS" : "FAIL";

  let attn: string | null = null;
  if (result === "PASS") {
    const r = await attestGoal({ goalId, result: "PASS" });
    attn = r.uid;
  }

  const updated = await prisma.goal.update({
    where: { id: goalId },
    data: {
      answersJson: { a1, a2 },
      judgeResult: judge.result ?? result,
      status: result === "PASS" ? "PASSED" : "FAILED",
      attestationUid: attn || undefined,
      // store notes inline
      notes: `Q1: ${q1}\nA1: ${a1}\nQ2: ${q2}\nA2: ${a2}\nJudge: ${judge.result}${judge.reason ? " ("+judge.reason+")" : ""}`,
    },
  });

  return NextResponse.json({ ok: true, goal: updated });
}
TS

echo ">> Done."
