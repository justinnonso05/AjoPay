"use client";

import { CheckCircle2, Download, Loader2 } from "lucide-react";
import { useState } from "react";

type DownloadButtonProps = {
  className?: string;
  label?: string;
  variant?: "primary" | "outline" | "hero";
  showIcon?: boolean;
  onClick?: () => void;
};

export function DownloadButton({
  className,
  label = "Download App",
  variant = "primary",
  showIcon = true,
  onClick,
}: DownloadButtonProps) {
  const [status, setStatus] = useState<"idle" | "downloading" | "started">("idle");

  const handleDownload = () => {
    if (status !== "idle") return;

    if (onClick) onClick();
    setStatus("downloading");

    // Programmatically trigger download of PayAjo.apk
    const link = document.createElement("a");
    link.href = "/downloads/PayAjo.apk";
    link.download = "PayAjo.apk";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    // Show started state after brief delay
    setTimeout(() => {
      setStatus("started");
    }, 500);

    // Reset back to idle after 3.5 seconds
    setTimeout(() => {
      setStatus("idle");
    }, 3500);
  };

  const getVariantStyles = () => {
    if (variant === "primary") {
      return "bg-brand text-brand-dark shadow-[0_4px_16px_rgba(172,236,135,0.35)] hover:scale-105";
    }
    if (variant === "hero") {
      return "border border-brand-dark/15 bg-white/80 text-brand-dark shadow-sm backdrop-blur hover:scale-105";
    }
    return "border border-white/20 text-white hover:bg-white/10";
  };

  return (
    <button
      type="button"
      onClick={handleDownload}
      disabled={status !== "idle"}
      className={`inline-flex items-center justify-center gap-2 rounded-full px-5 py-2.5 text-sm font-bold transition-all active:scale-95 disabled:cursor-wait disabled:opacity-90 ${getVariantStyles()} ${className ?? ""}`}
    >
      {status === "downloading" && <Loader2 size={16} className="animate-spin text-brand-dark" />}
      {status === "started" && <CheckCircle2 size={16} className="text-emerald-700" />}
      {status === "idle" && showIcon && <Download size={16} />}

      <span>
        {status === "downloading"
          ? "Starting Download…"
          : status === "started"
          ? "Download Started!"
          : label}
      </span>
    </button>
  );
}
