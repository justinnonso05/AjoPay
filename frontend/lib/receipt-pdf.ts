import { jsPDF } from "jspdf";
import { formatAmount, formatShortDate } from "./format";
import type { TransactionReceipt } from "./types";

function friendlyType(type: string) {
  return type
    .replace(/_/g, " ")
    .split(" ")
    .map((w) => (w ? w[0].toUpperCase() + w.slice(1).toLowerCase() : w))
    .join(" ");
}

function isCreditType(type: string) {
  const t = type.toLowerCase().replace(/[_-]/g, "");
  const credit = ["deposit", "topup", "payout", "refund", "credit", "received", "reversal"];
  const debit = ["withdraw", "contribution", "debit", "payment"];
  if (debit.some((k) => t.includes(k))) return false;
  return credit.some((k) => t.includes(k));
}

/** Renders a transaction receipt as a one-page PDF and triggers a browser download — entirely client-side, no backend call. */
export function downloadReceiptPdf(receipt: TransactionReceipt) {
  const doc = new jsPDF({ unit: "pt", format: "a4" });
  const pageWidth = doc.internal.pageSize.getWidth();
  const marginX = 48;
  let y = 64;

  const brandDark = "#1D3108";
  const brandAccent = "#5BA72D";
  const muted = "#8A9182";

  doc.setFont("helvetica", "bold");
  doc.setFontSize(18);
  doc.setTextColor(brandDark);
  doc.text("AjoPay", marginX, y);

  doc.setFont("helvetica", "normal");
  doc.setFontSize(10);
  doc.setTextColor(muted);
  doc.text("Transaction Receipt", pageWidth - marginX, y, { align: "right" });

  y += 40;
  doc.setDrawColor(230, 230, 230);
  doc.line(marginX, y, pageWidth - marginX, y);
  y += 40;

  const credit = isCreditType(receipt.type);
  doc.setFont("helvetica", "bold");
  doc.setFontSize(26);
  doc.setTextColor(credit ? brandAccent : brandDark);
  const amountText = `${credit ? "+" : "-"}₦${formatAmount(Math.abs(receipt.amount))}`;
  doc.text(amountText, pageWidth / 2, y, { align: "center" });

  y += 22;
  doc.setFont("helvetica", "bold");
  doc.setFontSize(10);
  doc.setTextColor(brandAccent);
  doc.text(receipt.status.toUpperCase(), pageWidth / 2, y, { align: "center" });

  y += 44;

  const rows: [string, string][] = [
    ["Type", friendlyType(receipt.type)],
    ["Date", formatShortDate(receipt.date)],
  ];
  if (receipt.sender_name) rows.push(["From", receipt.sender_name]);
  if (receipt.recipient_name) rows.push(["To", receipt.recipient_name]);
  if (receipt.narration) rows.push(["Narration", receipt.narration]);
  if (receipt.reference) rows.push(["Reference", receipt.reference]);
  rows.push(["Transaction ID", receipt.transaction_id]);

  doc.setFontSize(11);
  for (const [label, value] of rows) {
    doc.setFont("helvetica", "normal");
    doc.setTextColor(muted);
    doc.text(label, marginX, y);

    doc.setFont("helvetica", "bold");
    doc.setTextColor(brandDark);
    const wrapped = doc.splitTextToSize(value, pageWidth - marginX * 2 - 140);
    doc.text(wrapped, pageWidth - marginX, y, { align: "right" });

    y += 20 * wrapped.length + 6;
    doc.setDrawColor(245, 245, 245);
    doc.line(marginX, y - 14, pageWidth - marginX, y - 14);
  }

  y += 20;
  doc.setFont("helvetica", "normal");
  doc.setFontSize(9);
  doc.setTextColor(muted);
  doc.text(`Generated ${new Date().toLocaleString("en-GB")} • AjoPay`, pageWidth / 2, y, { align: "center" });

  doc.save(`ajopay-receipt-${receipt.transaction_id.slice(0, 8)}.pdf`);
}
