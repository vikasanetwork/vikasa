import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { serviceClient } from "../_shared/supabase_client.ts";

// Cron: Saturday UTC, process withdrawals: burn fee and mark complete (MVP: no external payout)
serve(async (_req: Request) => {
  try {
    const supabase = serviceClient();

    // Load burn rate from config
    const { data: cfg } = await supabase.from("config").select("value").eq("key", "burn_rate").single();
    const burnRate = Number(cfg?.value?.value ?? "0.0001");

    // Fetch pending withdrawals
    const { data: pending, error: qErr } = await supabase
      .from("withdrawals")
      .select("id, user_id, gross_amount")
      .eq("status", "requested");

    if (qErr) return new Response(JSON.stringify({ error: qErr.message }), { status: 500 });

    for (const w of pending ?? []) {
      const gross = Number(w.gross_amount);
      const burn = gross * burnRate;
      const net = gross - burn;

      // Insert burn record and mark withdrawal as completed (MVP)
      const { error: uErr } = await supabase.from("withdrawals").update({
        burn_amount: burn.toFixed(8),
        net_amount: net.toFixed(8),
        processed_at: new Date().toISOString(),
        status: "complete",
        tx_ref: `OFFCHAIN-${w.id}`,
      }).eq("id", w.id);

      if (!uErr) {
        await supabase.from("burns").insert({ withdrawal_id: w.id, amount: burn.toFixed(8) });
      }
    }

    return new Response(JSON.stringify({ ok: true, processed: pending?.length ?? 0 }));
  } catch (e) {
    return new Response(JSON.stringify({ error: "server_error", details: String(e) }), { status: 500 });
  }
});
