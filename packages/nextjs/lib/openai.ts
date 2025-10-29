import OpenAI from "openai";

export const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY!,
});

export async function genQuestions(goal: string, scope: string) {
  const sys = `You are "Proof-of-Day Quick-Check", a generator of TWO simple, concrete questions to verify someone likely completed a stated goal. 
Return strict JSON: {"questions":["Q1","Q2"]} with no extra text. Keep questions short and check real understanding.`;
  const user = JSON.stringify({ goal, scope });
  const r = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    temperature: 0.2,
    messages: [
      { role: "system", content: sys },
      { role: "user", content: user },
    ],
    response_format: { type: "json_object" },
  });
  const content = r.choices[0].message?.content ?? "{}";
  return JSON.parse(content);
}

export async function judgeAnswers(payload: {
  goal: string; scope: string; q1: string; q2: string; a1: string; a2: string;
}) {
  const sys = `You are "Proof-of-Day Judge". Decide PASS or FAIL based on whether answers plausibly show the goal was done.
Extremely lenient. Only FAIL if clearly bogus or unrelated. 
Return strict JSON: {"result":"PASS"} or {"result":"FAIL"} with optional {"reason":"..."} (short).`;
  const user = JSON.stringify(payload);
  const r = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    temperature: 0,
    messages: [
      { role: "system", content: sys },
      { role: "user", content: user },
    ],
    response_format: { type: "json_object" },
  });
  const content = r.choices[0].message?.content ?? "{}";
  return JSON.parse(content);
}
