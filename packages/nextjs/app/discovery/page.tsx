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
