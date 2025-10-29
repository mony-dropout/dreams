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
