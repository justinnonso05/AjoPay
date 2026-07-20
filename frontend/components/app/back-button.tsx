"use client";

import { ArrowLeft } from "lucide-react";
import { useRouter } from "next/navigation";

/** Goes back in browser history — the previous screen in this flow, not
 * always Home — with a Home fallback for a direct/bookmarked page load
 * where there's no history to go back to. */
export function BackButton({ fallbackHref = "/home" }: { fallbackHref?: string }) {
  const router = useRouter();

  const handleClick = () => {
    if (typeof window !== "undefined" && window.history.length > 1) {
      router.back();
    } else {
      router.push(fallbackHref);
    }
  };

  return (
    <button
      type="button"
      onClick={handleClick}
      aria-label="Go back"
      className="flex h-9 w-9 items-center justify-center rounded-full text-brand-dark/60 transition-colors hover:bg-soft-gray"
    >
      <ArrowLeft size={18} />
    </button>
  );
}
