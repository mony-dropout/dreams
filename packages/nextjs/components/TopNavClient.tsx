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
