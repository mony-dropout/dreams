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
