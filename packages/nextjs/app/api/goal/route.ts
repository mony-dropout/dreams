export const runtime = "nodejs";
export const dynamic = "force-dynamic";

import { prisma } from "@/lib/db";
import { NextResponse } from "next/server";

export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const address = searchParams.get("address");
    const discover = searchParams.get("discover");

    if (address) {
      const user = await prisma.user.findUnique({
        where: { address: address.toLowerCase() },
        include: { goals: { orderBy: { createdAt: "desc" } } },
      });
      return NextResponse.json({ goals: user?.goals ?? [] }, { status: 200 });
    }

    if (discover !== null) {
      const term = (discover || "").trim().toLowerCase();
      const users = await prisma.user.findMany({
        where: term
          ? { OR: [{ address: { contains: term } }, { name: { contains: term } }] }
          : {},
        orderBy: { createdAt: "desc" },
        take: 50,
        select: { address: true, name: true },
      });
      return NextResponse.json({ users }, { status: 200 });
    }

    return NextResponse.json({ ok: true }, { status: 200 });
  } catch (e: any) {
    return NextResponse.json({ error: String(e?.message || e) }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
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
      },
    });

    return NextResponse.json({ goal }, { status: 200 });
  } catch (e: any) {
    return NextResponse.json({ error: String(e?.message || e) }, { status: 500 });
  }
}