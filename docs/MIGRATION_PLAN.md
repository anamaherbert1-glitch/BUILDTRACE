# Plan de migration BUILDTRACE → TypeScript + PLpgSQL + CSS

## Phase A — Fondations (faite)
- [x] Migrations SQL `001_init_schema.sql`
- [x] RLS `002_rls_policies.sql`
- [x] Types TypeScript (`src/types/database.ts`)
- [x] Services : auth, listings, messages, favorites
- [x] Client Supabase typé
- [x] Design system CSS (tokens, base, components, layouts)
- [x] Outillage Vite + `tsconfig`

## Phase B — Branchement UI (suivante)
- [ ] Auth (login / register) appelle `auth.service.ts`
- [ ] Accueil / marketplace via `listings.service.ts`
- [ ] Favoris via table `favorites` (plus localStorage)
- [ ] Messages via `messages.service.ts`
- [ ] Charger `css/*.css` depuis `index.html` (retirer CSS inline progressivement)

## Phase C — Nettoyage
- [ ] Supprimer le JS monolithe inline
- [ ] Écrans en modules TS dédiés
- [ ] Tests manuels auth / publish / chat
- [ ] Build Vercel sur `web/dist`

## Commandes

```bash
cd web
cp .env.example .env   # remplir URL + anon key
npm install
npm run dev            # http://localhost:5173

# SQL : appliquer dans Supabase SQL Editor
# supabase/migrations/001_init_schema.sql
# supabase/migrations/002_rls_policies.sql
```
