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
