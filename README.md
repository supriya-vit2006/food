# food – 2 separate apps + 1 server
student-app/ → Vercel project 1 (Root Directory: student-app) · owner-app/ → Vercel project 2 (Root Directory: owner-app) · server/ → Render (Root Directory: server) · DB → Supabase
SQL: run sql/setup.sql ONCE (it is the only SQL file). The last result shows each canteen's owner sign-up code.
Render env: SUPABASE_URL, SUPABASE_SERVICE_KEY, JWT_SECRET, PAY_PASSWORD, FRONTEND_URL (both Vercel URLs, comma separated, no trailing slash)
Put the Render URL in student-app/config.js AND owner-app/config.js. Fill the [PLACEHOLDERS] in privacy.html, terms.html, refund.html of both apps.
