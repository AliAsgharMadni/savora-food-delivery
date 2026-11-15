# Savora Payment Backend - Render Deployment Guide

This backend handles secure Stripe `PaymentIntent` generation and webhook processing for the Savora Food Delivery app.

---

## 1. Quick Deploy to Render

### Option A: Using Blueprint (`render.yaml`)
1. Push this repository to GitHub or GitLab.
2. Log in to [Render Dashboard](https://dashboard.render.com).
3. Click **New +** -> **Blueprint**.
4. Connect this repository. Render will automatically detect [`render.yaml`](../render.yaml) and configure the `savora-payment-backend` service.
5. In the environment variables prompt, enter your actual Stripe and Supabase keys:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `STRIPE_SECRET_KEY`
   - `STRIPE_WEBHOOK_SECRET`
6. Click **Apply**.

---

### Option B: Manual Web Service Setup
1. In Render, select **New +** -> **Web Service**.
2. Connect your repository.
3. Configure settings:
   - **Name:** `savora-payment-backend`
   - **Root Directory:** `server`
   - **Environment:** `Node`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - **Health Check Path:** `/health`
4. Add Environment Variables under the **Environment** tab:
   ```env
   NODE_ENV=production
   PORT=10000
   ALLOWED_ORIGINS=*
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   STRIPE_SECRET_KEY=sk_live_... (or sk_test_...)
   STRIPE_WEBHOOK_SECRET=whsec_...
   ```
5. Click **Create Web Service**.

---

## 2. Setting Up the Stripe Webhook in Stripe Dashboard

1. Go to **[Stripe Dashboard > Developers > Webhooks](https://dashboard.stripe.com/webhooks)**.
2. Click **Add endpoint**.
3. Set **Endpoint URL** to:
   ```
   https://YOUR_RENDER_SERVICE_URL.onrender.com/api/webhook
   ```
4. Select Events to listen for:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
5. Click **Add endpoint**.
6. Reveal the **Signing secret** (`whsec_...`) and paste it into Render's `STRIPE_WEBHOOK_SECRET` variable.

---

## 3. Local Development & Testing

1. Install dependencies:
   ```bash
   cd server
   npm install
   ```
2. Start server in watch mode:
   ```bash
   npm run dev
   ```
3. Forward Stripe events locally using Stripe CLI:
   ```bash
   stripe listen --forward-to localhost:3000/api/webhook
   ```

