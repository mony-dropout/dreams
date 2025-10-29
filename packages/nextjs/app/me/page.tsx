"use client";

import { useEffect, useState, ReactNode } from "react";

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
  attestationTxUrl?: string | null;
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
  const [msg, setMsg] = useState<ReactNode | null>(null);
  const [answers, setAnswers] = useState<Record<string, { a1: string; a2: string }>>({});

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

  async function evaluateGoal(g: Goal) {
    setLoading(true);
    try {
      const a = answers[g.id] || { a1: '', a2: '' };
      const d = await fetchJSON('/api/goal/evaluate', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({ goalId: g.id, a1: a.a1, a2: a.a2 }),
      });
      await refresh();
      setMsg(
        <span>
          Evaluation complete.{' '}
          {d?.txUrl && (
            <a className="underline" href={d.txUrl} target="_blank" rel="noreferrer">View on explorer</a>
          )}
        </span>
      );
    } catch (e:any) {
      setMsg(`Evaluation failed: ${e.message}`);
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
                {g.status === "PENDING" && !g.questionsJson && (
                  <button className="btn" onClick={()=>getQuestions(g)} disabled={loading}>
                    {loading? "..." : "Take Quick-Check"}
                  </button>
                )}
              </div>
            </div>
            {g.status === 'PENDING' && g.questionsJson && (
              <div className="mt-4 space-y-3">
                <div className="text-sm font-medium">Quick-Check</div>
                <div className="space-y-2">
                  <div>
                    <div className="text-sm mb-1">Q1: {(g.questionsJson as any)?.questions?.[0] || ''}</div>
                    <textarea
                      className="textarea"
                      rows={3}
                      placeholder="Your answer"
                      value={(answers[g.id]?.a1) ?? ''}
                      onChange={e=>setAnswers(prev=>({ ...prev, [g.id]: { a1: e.target.value, a2: prev[g.id]?.a2 || '' } }))}
                    />
                  </div>
                  <div>
                    <div className="text-sm mb-1">Q2: {(g.questionsJson as any)?.questions?.[1] || ''}</div>
                    <textarea
                      className="textarea"
                      rows={3}
                      placeholder="Your answer"
                      value={(answers[g.id]?.a2) ?? ''}
                      onChange={e=>setAnswers(prev=>({ ...prev, [g.id]: { a1: prev[g.id]?.a1 || '', a2: e.target.value } }))}
                    />
                  </div>
                </div>
                <div>
                  <button className="btn btn-primary" onClick={()=>evaluateGoal(g)} disabled={loading}>
                    {loading ? 'Submitting...' : 'Submit Answers'}
                  </button>
                </div>
              </div>
            )}
            {g.status !== 'PENDING' && (
              <div className="mt-3 text-sm space-y-2">
                <div>Result: <b>{g.judgeResult}</b></div>
                {g.attestationTxUrl && (
                  <div>
                    <a className="underline" href={g.attestationTxUrl} target="_blank" rel="noreferrer">See blockchain proof</a>
                  </div>
                )}
                {g.notes && (
                  <pre className="p-3 bg-[var(--lavender-50)] rounded-xl whitespace-pre-wrap">{g.notes}</pre>
                )}
              </div>
            )}
          </div>
        ))}
      </section>
    </div>
  );
}
