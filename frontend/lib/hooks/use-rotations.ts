"use client";

import { useCallback, useEffect, useState } from "react";
import { api, endpoints } from "@/lib/api";
import { authHeaders } from "@/lib/auth";
import type { GroupRotationEntry } from "@/lib/types";

/** Full ordered payout schedule for a group — who gets paid each cycle. */
export function useRotations(groupId: string) {
  const [rotations, setRotations] = useState<GroupRotationEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const refresh = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await api.get(endpoints.groupRotations(groupId), authHeaders());
      setRotations((res.data as GroupRotationEntry[]) ?? []);
    } catch {
      // Only meaningful once a group has started — an error here (e.g. still gathering) just means "nothing to show".
      setRotations([]);
    } finally {
      setIsLoading(false);
    }
  }, [groupId]);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- refresh() is async, setState happens post-await
    refresh();
  }, [refresh]);

  return { rotations, isLoading, refresh };
}
