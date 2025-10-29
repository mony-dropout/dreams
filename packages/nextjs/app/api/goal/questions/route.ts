export const runtime = "nodejs";
export const dynamic = "force-dynamic";

import { prisma } from "@/lib/db";
import { genQuestions } from "@/lib/openai";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  try {
    const { goalId } = await req.json();
    if (!goalId) return NextResponse.json({ error: "goalId required" }, { status: 400 });

    const goal = await prisma.goal.findUnique({ where: { id: goalId } });
    if (!goal) return NextResponse.json({ error: "goal not found" }, { status: 404 });

    const questions = await genQuestions(goal.title, goal.scope);
    await prisma.goal.update({
      where: { id: goalId },
      data: { questionsJson: questions },
    });

    return NextResponse.json({ questions }, { status: 200 });
  } catch (e: any) {
    return NextResponse.json({ error: String(e?.message || e) }, { status: 500 });
  }
}