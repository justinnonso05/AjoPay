"use client";

import { AnimatedCheckmark } from "@/components/app/animated-checkmark";

/** Shared "action succeeded" confirmation — mirrors the mobile app's SuccessBottomSheet
 * (animated checkmark + title + subtitle + primary action) so every money-moving
 * action gets the same confirmation, not a silent redirect. */
export function SuccessModal({
  title,
  subtitle,
  primaryLabel = "Done",
  onPrimary,
}: {
  title: string;
  subtitle: string;
  primaryLabel?: string;
  onPrimary: () => void;
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-brand-dark/40 px-4 backdrop-blur-sm">
      <div className="w-full max-w-sm rounded-card bg-white p-8 text-center shadow-2xl">
        <div className="mx-auto flex justify-center">
          <AnimatedCheckmark size={64} />
        </div>
        <h3 className="mt-5 font-display text-lg font-bold text-brand-dark">{title}</h3>
        <p className="mt-2 text-sm leading-relaxed text-brand-dark/55">{subtitle}</p>
        <button
          type="button"
          onClick={onPrimary}
          className="mt-7 w-full rounded-full bg-brand py-3.5 text-sm font-bold text-brand-dark transition-transform hover:scale-[1.02] active:scale-95"
        >
          {primaryLabel}
        </button>
      </div>
    </div>
  );
}
