# Architecture BUILDTRACE (refonte professionnelle)

## Stack cible

| Couche | Technologie |
|--------|-------------|
| Frontend web | TypeScript + Vite + CSS modulaire |
| Backend data | Supabase (PostgreSQL) |
| SQL | PLpgSQL (migrations + triggers + RLS) |
| Styles | CSS (tokens, base, components, layouts) |

## Structure

```
BUILDTRACE/
├── web/
│   ├── css/           # Design system
│   ├── src/
│   │   ├── config.ts
│   │   ├── main.ts
│   │   ├── lib/       # supabase client
│   │   ├── types/     # modèles TS
│   │   └── services/  # auth, listings, messages, favorites
│   ├── index.html     # UI (migration progressive)
│   ├── package.json
│   └── vite.config.ts
├── supabase/
│   └── migrations/    # 001 schema + 002 RLS
└── docs/
```

## Migration

1. **Fait** : schéma PLpgSQL, RLS, services TS, design tokens CSS, Vite.
2. **En cours** : brancher l'UI écran par écran sur les services TS.
3. **Ensuite** : retirer le JS inline de `index.html`, découper les écrans.

## Règles

- Jamais de `service_role` dans le frontend.
- Toute donnée sensible protégée par RLS.
- Pas de wallet / paiement matériaux (modèle abonnements).
