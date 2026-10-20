// Supabase Edge Function stub for Safety Rules Evaluation
// This mirrors the client-side Dart safety_rules_engine.dart for server-side enforcement (SR-11)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

interface SafetyProfile {
  pregnancy: boolean;
  hypertension: boolean;
  heartCondition: boolean;
  epilepsy: boolean;
  glaucoma: boolean;
  hernia: boolean;
  recentSurgery: boolean;
  menstruation: boolean;
  emptyStomachConfirmed: boolean;
}

function isPracticeAllowed(practice: string, profile: SafetyProfile, teacherCleared: boolean): boolean {
  const restrictivePractices = [
    'kapalbhati', 'bhastrika', 'antar_kumbhaka', 'bahya_kumbhaka',
    'uddiyana_kriya', 'maha_bandha', 'jalandhara', 'mula', 'bandhas'
  ];

  if (restrictivePractices.includes(practice)) {
    if (profile.pregnancy) return teacherCleared;
    if (profile.hypertension || profile.heartCondition || profile.epilepsy ||
        profile.glaucoma || profile.hernia || profile.recentSurgery) {
      return teacherCleared;
    }
  }

  if (profile.menstruation) {
    if (['kapalbhati', 'uddiyana_kriya', 'maha_bandha'].includes(practice)) {
      return false; // Suggested off during menstruation
    }
  }

  if (['uddiyana_kriya', 'maha_bandha'].includes(practice)) {
    if (!profile.emptyStomachConfirmed) return false;
  }

  return true;
}

serve(async (req) => {
  try {
    const { practice, profile, teacherCleared } = await req.json();
    const allowed = isPracticeAllowed(practice, profile, teacherCleared);
    return new Response(JSON.stringify({ allowed }), { headers: { "Content-Type": "application/json" } });
  } catch (err) {
    return new Response("Invalid Request", { status: 400 });
  }
})
