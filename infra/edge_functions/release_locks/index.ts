import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { serviceClient } from "../_shared/supabase_client.ts";

// Cron: hourly, release claims whose unlock_at <= now()
serve(async (_req: Request) => {
  try {
    const supabase = serviceClient();

    const { error } = await supabase
      .from("claims")
      .update({ status: "unlocked" })
      .lte("unlock_at", new Date().toISOString())
      .eq("status", "locked");

    if (error) {
      return new Response(JSON.stringify({ error: "update_failed", details: error.message }), { status: 500 });
    }

    return new Response(JSON.stringify({ ok: true }));
  } catch (e) {
    return new Response(JSON.stringify({ error: "server_error", details: String(e) }), { status: 500 });
  }
});
