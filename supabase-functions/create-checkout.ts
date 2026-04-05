// Edge Function: create-checkout
// Colar no Supabase Dashboard > Edge Functions > New Function
// Nome: create-checkout

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const MP_ACCESS_TOKEN = Deno.env.get('MP_ACCESS_TOKEN')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const SITE_URL = Deno.env.get('SITE_URL') || 'https://gestfin.vercel.app'

const PLANOS: Record<string, { nome: string; preco: number; maxContratos: number }> = {
  basico:       { nome: 'Básico',        preco: 44.90,  maxContratos: 40 },
  profissional: { nome: 'Profissional',  preco: 89.90,  maxContratos: 100 },
  empresarial:  { nome: 'Empresarial',   preco: 159.90, maxContratos: 99999 },
}

serve(async (req) => {
  // CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const { plano, userId, userEmail } = await req.json()

    if (!plano || !PLANOS[plano]) {
      return new Response(JSON.stringify({ error: 'Plano inválido' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      })
    }

    const planData = PLANOS[plano]

    // Criar preferência no Mercado Pago
    const mpResponse = await fetch('https://api.mercadopago.com/checkout/preferences', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${MP_ACCESS_TOKEN}`,
      },
      body: JSON.stringify({
        items: [{
          title: `GestFin - Plano ${planData.nome}`,
          description: `Assinatura mensal do plano ${planData.nome} - até ${planData.maxContratos === 99999 ? 'ilimitados' : planData.maxContratos} contratos`,
          quantity: 1,
          currency_id: 'BRL',
          unit_price: planData.preco,
        }],
        payer: {
          email: userEmail || '',
        },
        back_urls: {
          success: `${SITE_URL}?status=approved&plano=${plano}`,
          failure: `${SITE_URL}?status=failure`,
          pending: `${SITE_URL}?status=pending`,
        },
        auto_return: 'approved',
        external_reference: JSON.stringify({ userId, plano }),
        notification_url: `${SUPABASE_URL}/functions/v1/webhook-mp`,
      }),
    })

    const mpData = await mpResponse.json()

    if (!mpResponse.ok) {
      console.error('MP error:', mpData)
      return new Response(JSON.stringify({ error: 'Erro ao criar checkout' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      })
    }

    // Registrar assinatura pendente
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    await supabase.from('assinaturas').insert({
      user_id: userId,
      plano: plano,
      status: 'pending',
      valor: planData.preco,
      mp_preference_id: mpData.id,
    })

    return new Response(JSON.stringify({ init_point: mpData.init_point }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })

  } catch (e) {
    console.error('Error:', e)
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })
  }
})
