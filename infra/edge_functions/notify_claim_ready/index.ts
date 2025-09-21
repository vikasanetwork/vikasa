import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { serviceClient } from "../_shared/supabase_client.ts";

// Cron: every 15 minutes to notify users whose claim window is open
serve(async (_req: Request) => {
  try {
    const supabase = serviceClient();

    // Load interval
    const { data: cfgInterval } = await supabase
      .from("config").select("value").eq("key", "claim_interval_hours").single();
    const hours = Number(cfgInterval?.value?.value ?? 3);

    // Find users eligible: last claim older than interval OR no claims
    // For simplicity, select profiles and left join claims; production should use a SQL view
    const { data: users, error } = await supabase.rpc("eligible_claim_users", { p_hours: hours });
    if (error) {
      return new Response(JSON.stringify({ error: "rpc_failed", details: error.message }), { status: 500 });
    }

    // TODO: send FCM notifications via Firebase Admin from a secure environment
    // This is a placeholder; actual sending will be implemented later.

    return new Response(JSON.stringify({ ok: true, notified_count: users?.length ?? 0 }));
  } catch (e) {
    return new Response(JSON.stringify({ error: "server_error", details: String(e) }), { status: 500 });
  }
});
