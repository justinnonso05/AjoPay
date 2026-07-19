"use client";

import { useState } from "react";
import { Modal } from "@/components/app/modal";
import { PinConfirmModal } from "@/components/app/pin-confirm-modal";
import { api, ApiError, endpoints } from "@/lib/api";
import { authHeaders } from "@/lib/auth";
import type { GroupRotationEntry } from "@/lib/types";

/** Lets the current user delegate their own upcoming payout turn to another
 * member, or request to swap cycle positions with one. Initiate-only — the
 * backend has no endpoint yet to list pending requests, so there's no way
 * to build a respond/admin-approve screen. */
export function CycleActionModal({
  groupId,
  myEntry,
  otherEntries,
  isDelegate,
  onClose,
  onSent,
}: {
  groupId: string;
  myEntry: GroupRotationEntry;
  otherEntries: GroupRotationEntry[];
  isDelegate: boolean;
  onClose: () => void;
  onSent: () => void;
}) {
  const [selected, setSelected] = useState<GroupRotationEntry | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [showPin, setShowPin] = useState(false);

  const handleConfirm = async (pin: string) => {
    if (!selected) return;
    setError(null);
    try {
      if (isDelegate) {
        await api.post(
          endpoints.delegateCycle(groupId, myEntry.cycle_number),
          { to_member_id: selected.user_id, pin },
          authHeaders(),
        );
      } else {
        await api.post(
          endpoints.swapCycle(groupId),
          { target_member_id: selected.user_id, target_cycle_number: selected.cycle_number, pin },
          authHeaders(),
        );
      }
      onSent();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Something went wrong. Please try again.");
      setShowPin(false);
    }
  };

  if (showPin && selected) {
    return (
      <PinConfirmModal
        title={isDelegate ? "Confirm Delegation" : "Confirm Swap Request"}
        subtitle={
          isDelegate
            ? `Confirm with your PIN to give cycle ${myEntry.cycle_number}'s payout to ${fullName(selected)}.`
            : `Confirm with your PIN to request swapping your cycle ${myEntry.cycle_number} with ${fullName(selected)}'s cycle ${selected.cycle_number}.`
        }
        onConfirm={handleConfirm}
        onClose={() => setShowPin(false)}
      />
    );
  }

  return (
    <Modal title={isDelegate ? "Delegate My Payout" : "Request a Swap"} onClose={onClose}>
      <p className="text-sm text-brand-dark/55">
        {isDelegate
          ? `Give your cycle ${myEntry.cycle_number} payout turn to someone else in the group.`
          : `Ask to trade payout positions — your cycle ${myEntry.cycle_number} for theirs.`}
      </p>

      <div className="mt-4 max-h-72 divide-y divide-brand-dark/5 overflow-y-auto rounded-2xl border border-brand-dark/5">
        {otherEntries.length === 0 ? (
          <p className="p-4 text-xs text-brand-dark/40">No other members with an upcoming cycle to {isDelegate ? "delegate to" : "swap with"} yet.</p>
        ) : (
          otherEntries.map((entry) => {
            const isSelected = selected?.user_id === entry.user_id;
            return (
              <button
                key={entry.user_id}
                type="button"
                onClick={() => {
                  setSelected(entry);
                  setError(null);
                }}
                className="flex w-full items-center gap-3 p-3 text-left hover:bg-soft-gray"
              >
                <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-brand-pale text-xs font-bold text-brand-accent">
                  {entry.cycle_number}
                </span>
                <span className="flex-1 text-sm font-semibold text-brand-dark">{fullName(entry)}</span>
                <span
                  className={`h-4 w-4 shrink-0 rounded-full border-2 ${isSelected ? "border-brand-accent bg-brand-accent" : "border-brand-dark/20"}`}
                />
              </button>
            );
          })
        )}
      </div>

      {error && <p className="mt-3 text-xs font-semibold text-red-500">{error}</p>}

      <button
        type="button"
        disabled={!selected || otherEntries.length === 0}
        onClick={() => setShowPin(true)}
        className="mt-5 w-full rounded-full bg-brand py-3.5 text-sm font-bold text-brand-dark transition-transform hover:scale-[1.02] active:scale-95 disabled:opacity-40 disabled:hover:scale-100"
      >
        {isDelegate ? "Delegate" : "Request Swap"}
      </button>
    </Modal>
  );
}

function fullName(entry: GroupRotationEntry) {
  return `${entry.first_name} ${entry.last_name}`.trim() || `@${entry.username}`;
}
