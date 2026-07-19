"use client";

import { GripVertical, Shuffle, ListOrdered } from "lucide-react";
import { useState } from "react";
import { Modal } from "@/components/app/modal";
import type { GroupMember } from "@/lib/types";

export function StartGroupModal({
  members,
  onClose,
  onStart,
}: {
  members: GroupMember[];
  onClose: () => void;
  onStart: (options: { randomize: boolean; manualOrder?: string[] }) => Promise<void>;
}) {
  const [mode, setMode] = useState<"randomize" | "manual">("randomize");
  const [order, setOrder] = useState<GroupMember[]>(members);
  const [dragIndex, setDragIndex] = useState<number | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleDrop = (targetIndex: number) => {
    if (dragIndex === null || dragIndex === targetIndex) return;
    setOrder((prev) => {
      const next = prev.slice();
      const [moved] = next.splice(dragIndex, 1);
      next.splice(targetIndex, 0, moved);
      return next;
    });
    setDragIndex(null);
  };

  const move = (index: number, direction: -1 | 1) => {
    const target = index + direction;
    if (target < 0 || target >= order.length) return;
    setOrder((prev) => {
      const next = prev.slice();
      [next[index], next[target]] = [next[target], next[index]];
      return next;
    });
  };

  const handleStart = async () => {
    setIsSubmitting(true);
    setError(null);
    try {
      await onStart(
        mode === "randomize" ? { randomize: true } : { randomize: false, manualOrder: order.map((m) => m.user_id) },
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong. Please try again.");
      setIsSubmitting(false);
    }
  };

  return (
    <Modal title="Start Group" onClose={onClose}>
      <p className="text-sm text-brand-dark/55">
        This locks in the payout rotation order and begins the first contribution cycle. This cannot be undone.
      </p>

      <div className="mt-5 grid grid-cols-2 gap-2">
        <button
          type="button"
          onClick={() => setMode("randomize")}
          className={`flex flex-col items-center gap-1.5 rounded-2xl border-2 px-4 py-4 text-center transition-colors ${
            mode === "randomize" ? "border-brand-accent bg-brand-pale" : "border-brand-dark/10 bg-white"
          }`}
        >
          <Shuffle size={18} className="text-brand-accent" />
          <span className="text-xs font-bold text-brand-dark">Randomize Order</span>
        </button>
        <button
          type="button"
          onClick={() => setMode("manual")}
          className={`flex flex-col items-center gap-1.5 rounded-2xl border-2 px-4 py-4 text-center transition-colors ${
            mode === "manual" ? "border-brand-accent bg-brand-pale" : "border-brand-dark/10 bg-white"
          }`}
        >
          <ListOrdered size={18} className="text-brand-accent" />
          <span className="text-xs font-bold text-brand-dark">Manual Order</span>
        </button>
      </div>

      {mode === "manual" && (
        <div className="mt-5">
          <p className="mb-2 text-xs font-semibold text-brand-dark/50">Drag to set the payout order — first member gets paid first.</p>
          <div className="max-h-72 space-y-2 overflow-y-auto">
            {order.map((member, index) => (
              <div
                key={member.user_id}
                draggable
                onDragStart={() => setDragIndex(index)}
                onDragOver={(e) => e.preventDefault()}
                onDrop={() => handleDrop(index)}
                className={`flex items-center gap-3 rounded-xl border border-brand-dark/10 bg-white px-3 py-2.5 ${
                  dragIndex === index ? "opacity-40" : ""
                }`}
              >
                <span className="cursor-grab text-brand-dark/30 active:cursor-grabbing">
                  <GripVertical size={16} />
                </span>
                <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-brand-pale text-[11px] font-bold text-brand-accent">
                  {index + 1}
                </span>
                <span className="min-w-0 flex-1 truncate text-sm font-semibold text-brand-dark">
                  {`${member.first_name} ${member.last_name}`.trim() || `@${member.username}`}
                </span>
                <div className="flex shrink-0 flex-col gap-0.5">
                  <button
                    type="button"
                    onClick={() => move(index, -1)}
                    disabled={index === 0}
                    className="text-brand-dark/30 hover:text-brand-dark disabled:opacity-20"
                    aria-label="Move up"
                  >
                    ▲
                  </button>
                  <button
                    type="button"
                    onClick={() => move(index, 1)}
                    disabled={index === order.length - 1}
                    className="text-brand-dark/30 hover:text-brand-dark disabled:opacity-20"
                    aria-label="Move down"
                  >
                    ▼
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {error && <p className="mt-4 text-xs font-semibold text-red-500">{error}</p>}

      <button
        type="button"
        onClick={handleStart}
        disabled={isSubmitting || (mode === "manual" && order.length === 0)}
        className="mt-6 w-full rounded-full bg-brand py-3.5 text-sm font-bold text-brand-dark transition-transform hover:scale-[1.02] active:scale-95 disabled:opacity-60 disabled:hover:scale-100"
      >
        {isSubmitting ? "Starting…" : "Start Group"}
      </button>
    </Modal>
  );
}
