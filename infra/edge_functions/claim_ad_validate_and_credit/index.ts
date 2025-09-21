import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { serviceClient } from "../_shared/supabase_client.ts";

// Placeholder: validate ad receipt, ensure claim interval and lock amounts, then insert claim
serve(async (req: Request) => {
  try {
    const supabase = serviceClient();
    const body = await req.json().catch(() => ({}));
    const userId: string | undefined = body.user_id;
    const adReceiptId: string | undefined = body.ad_receipt_id;

    if (!userId || !adReceiptId) {
      return new Response(JSON.stringify({ error: "missing_fields" }), { status: 400 });
    }

    // Load config: claim interval and base reward
    const { data: cfgInterval } = await supabase
      .from("config").select("value").eq("key", "claim_interval_hours").single();
    const claimIntervalHours = Number(cfgInterval?.value?.value ?? 3);

    const { data: cfgReward } = await supabase
      .from("config").select("value").eq("key", "reward_base").single();
    const rewardBaseStr = cfgReward?.value?.value ?? "0.01000000"; // 8+ decimals string

    // Check last claim time
    const { data: lastClaim } = await supabase
      .from("claims")
      .select("claimed_at")
      .eq("user_id", userId)
      .order("claimed_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (lastClaim) {
      const nextAt = new Date(lastClaim.claimed_at);
      nextAt.setHours(nextAt.getHours() + claimIntervalHours);
      if (new Date() < nextAt) {
        return new Response(JSON.stringify({ error: "not_eligible_yet", next_at: nextAt.toISOString() }), { status: 429 });
      }
    }

    // TODO: Server-side ad receipt validation with AdMob/Google callback (MVP: accept)

    // Insert claim with 90-day lock
    const unlockAt = new Date();
    unlockAt.setDate(unlockAt.getDate() + 90);

    const { error: insertErr } = await supabase.from("claims").insert({
      user_id: userId,
      amount: rewardBaseStr,
      claimed_at: new Date().toISOString(),
      unlock_at: unlockAt.toISOString(),
      ad_receipt_id: adReceiptId,
      status: "locked",
    });

    if (insertErr) {
      return new Response(JSON.stringify({ error: "insert_failed", details: insertErr.message }), { status: 500 });
    }

    return new Response(JSON.stringify({ ok: true, unlock_at: unlockAt.toISOString(), amount: rewardBaseStr }), {
      headers: { "content-type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: "server_error", details: String(e) }), { status: 500 });
  }
});
