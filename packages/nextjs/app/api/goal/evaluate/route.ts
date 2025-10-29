export const runtime = "nodejs";
export const dynamic = "force-dynamic";

import { prisma } from "@/lib/db";
import { judgeAnswers } from "@/lib/openai";
import { attestGoal } from "@/lib/eas";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  try {
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
        notes: `Q1: ${q1}\nA1: ${a1}\nQ2: ${q2}\nA2: ${a2}\nJudge: ${judge.result}${judge.reason ? " ("+judge.reason+")" : ""}`,
      },
    });

    return NextResponse.json({ ok: true, goal: updated }, { status: 200 });
  } catch (e: any) {
    return NextResponse.json({ error: String(e?.message || e) }, { status: 500 });
  }
}
