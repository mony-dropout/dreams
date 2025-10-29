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
            {g.attestationTxUrl && (
              <div className="text-xs mt-1">
                <a className="underline" href={g.attestationTxUrl} target="_blank" rel="noreferrer">See blockchain proof</a>
              </div>
            )}
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
