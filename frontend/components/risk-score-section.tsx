"use client";

import { CheckCircle2, ShieldQuestion, Sparkles, Users } from "lucide-react";
import { motion, useInView } from "framer-motion";
import { useRef, useState, useEffect } from "react";
import { Reveal, StaggerGroup, StaggerItem } from "./reveal";

const BENEFITS = [
  {
    icon: Users,
    title: "Admins make better decisions",
    desc: "See a member's risk badge before approving them into a group, so chronic defaulters never jeopardize the cycle.",
  },
  {
    icon: ShieldQuestion,
    title: "Safer swaps and delegations",
    desc: "Before swapping a payout cycle with someone, check their score — never trade a guaranteed payout for a risky one.",
  },
  {
    icon: CheckCircle2,
    title: "Encourages good behavior",
    desc: "Because the score is visible to admins, members are incentivized to pay on time and protect their standing.",
  },
];

const FACTORS = [
  { label: "Punctuality", weight: 35, desc: "Paid before or on the deadline" },
  { label: "Consistency streak", weight: 25, desc: "Back-to-back on-time payments" },
  { label: "Completion rate", weight: 25, desc: "Cycles paid vs. cycles expected" },
  { label: "Tenure", weight: 10, desc: "Time spent active on the platform" },
  { label: "Relative standing", weight: 5, desc: "Baseline modifier" },
];

// Muted, brand-adjacent traffic-light tones instead of raw Tailwind
// defaults — this landing page never uses saturated semantic colors
// anywhere else, so low/medium/high risk are told apart with warmth and
// hue rather than a jump to a completely different, louder palette.
const TIERS = [
  { range: "70–100", label: "Low risk", sub: "Highly trustworthy", dot: "bg-brand-accent", text: "text-brand-accent", bg: "bg-brand-pale" },
  { range: "40–69", label: "Medium risk", sub: "Average", dot: "bg-[#B08B2E]", text: "text-[#8A6D1F]", bg: "bg-[#FBF3DE]" },
  { range: "0–39", label: "High risk", sub: "Frequent missed or late payments", dot: "bg-[#B0553F]", text: "text-[#8A4433]", bg: "bg-[#FBEAE5]" },
];

function ScoreCard() {
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });
  const [score, setScore] = useState(0);

  useEffect(() => {
    if (!inView) return;
    const start = performance.now();
    const duration = 1200;
    let raf: number;
    const tick = (now: number) => {
      const t = Math.min(1, (now - start) / duration);
      setScore(Math.round(78 * (1 - Math.pow(1 - t, 3))));
      if (t < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [inView]);

  return (
    <div ref={ref} className="rounded-card border border-brand-dark/5 bg-white p-8 shadow-sm">
      <p className="text-xs font-bold uppercase tracking-[0.2em] text-brand-accent">Sample member</p>
      <div className="mt-4 flex items-center gap-5">
        <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-full bg-brand-pale">
          <span className="font-display text-3xl font-extrabold text-brand-dark">{score}</span>
        </div>
        <div>
          <p className="font-display text-lg font-bold text-brand-dark">Chidi E.</p>
          <span className="mt-1 inline-flex items-center gap-1.5 rounded-full bg-brand-pale px-3 py-1 text-xs font-bold text-brand-accent">
            <span className="h-1.5 w-1.5 rounded-full bg-brand-accent" />
            Low risk
          </span>
        </div>
      </div>

      <div className="mt-7 space-y-4">
        {FACTORS.map((f) => (
          <div key={f.label}>
            <div className="flex items-center justify-between text-xs">
              <span className="font-bold text-brand-dark">{f.label}</span>
              <span className="font-semibold text-brand-dark/40">{f.weight}%</span>
            </div>
            <div className="mt-1.5 h-1.5 w-full overflow-hidden rounded-full bg-brand-dark/5">
              <motion.div
                className="h-full rounded-full bg-brand-accent"
                initial={{ width: 0 }}
                animate={inView ? { width: `${f.weight}%` } : { width: 0 }}
                transition={{ duration: 0.8, delay: 0.2, ease: [0.22, 1, 0.36, 1] }}
              />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export function RiskScoreSection() {
  return (
    <section className="bg-soft-gray py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-6">
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="mt-4 font-display text-3xl font-bold tracking-tight text-brand-dark sm:text-4xl">
            A credit score for community savings.
          </h2>
          <p className="mt-4 text-base leading-relaxed text-brand-dark/60">
            In traditional Ajo, the biggest point of failure is trust — one member who defaults or pays late ruins
            the schedule for everyone downstream. The risk score quantifies that trust using real payment history,
            so it never has to be a guess.
          </p>
        </Reveal>

        <StaggerGroup className="mt-14 grid gap-5 sm:grid-cols-3">
          {BENEFITS.map(({ icon: Icon, title, desc }) => (
            <StaggerItem key={title}>
              <div className="h-full rounded-card border border-brand-dark/5 bg-white p-6 shadow-sm">
                <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-brand-pale">
                  <Icon size={20} className="text-brand-accent" />
                </span>
                <h3 className="mt-4 font-display text-base font-bold text-brand-dark">{title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-brand-dark/55">{desc}</p>
              </div>
            </StaggerItem>
          ))}
        </StaggerGroup>

        <div className="mt-14 grid items-start gap-10 lg:grid-cols-2 lg:gap-14">
          <Reveal>
            <ScoreCard />
          </Reveal>

          <Reveal delay={0.1}>
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-brand-accent">Risk badges</p>
            <h3 className="mt-3 font-display text-2xl font-bold text-brand-dark">
              Every user starts neutral at 50, then earns their standing.
            </h3>
            <p className="mt-3 text-sm leading-relaxed text-brand-dark/60">
              New members start with a default score until they complete a few cycles. From there, the score is
              recalculated automatically every time they make a contribution.
            </p>

            <div className="mt-6 space-y-3">
              {TIERS.map((t) => (
                <div key={t.label} className={`flex items-center justify-between rounded-2xl ${t.bg} px-5 py-4`}>
                  <div className="flex items-center gap-3">
                    <span className={`h-2.5 w-2.5 rounded-full ${t.dot}`} />
                    <div>
                      <p className={`font-display text-sm font-bold ${t.text}`}>{t.label}</p>
                      <p className="text-xs text-brand-dark/50">{t.sub}</p>
                    </div>
                  </div>
                  <span className={`font-display text-sm font-bold ${t.text}`}>{t.range}</span>
                </div>
              ))}
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
