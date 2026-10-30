# BUILDTRACE

**Passeport numérique et réemploi des matériaux de construction**

MVP centré sur le **passeport numérique + QR**, la découverte et le contact vendeur.  
Monétisation uniquement par **abonnements professionnels**.  
Le paiement des matériaux reste **hors plateforme**.

---

## Stack

| Couche | Technologie |
|--------|-------------|
| Backend | NestJS + TypeScript + Prisma |
| Database | PostgreSQL (SQLite possible en local) |
| Mobile | Flutter + Riverpod + Dio + GoRouter |
| Auth | JWT + Refresh Token |
| Paiement | CinetPay (abonnements uniquement) |
| IA | OpenAI Vision (P2) |

---

## Structure

```
BUILDTRACE/
├── apps/mobile/           # Flutter
├── packages/api/          # NestJS
├── docker-compose.yml     # PostgreSQL
└── README.md
```

---

## Backend — modules

| Module | Endpoints principaux | Statut |
|--------|----------------------|--------|
| Auth | register, login, refresh | ✅ |
| Users | GET /users/me | ✅ |
| Materials | CRUD + publish + mine | ✅ |
| Buildings | CRUD + mine | ✅ |
| Subscriptions | plans, me, checkout | ✅ (CinetPay à brancher) |
| Health | GET /health | ✅ |

## Flutter — écrans

| Écran | Branché API |
|-------|-------------|
| Splash | — |
| Login / Register | ✅ |
| Home (liste matériaux) | ✅ |
| Ajouter matériau | ✅ |
| Détail + Publier | ✅ |
| Recherche | UI |
| Profil | UI |

---

## Démarrage local

### API
```bash
cd packages/api
npm install
npx prisma generate
npx prisma migrate dev --name init
npm run start:dev
# → http://localhost:3000/docs
```

### Mobile
```bash
cd apps/mobile
flutter pub get
flutter run
# Emulator Android : baseUrl = http://10.0.2.2:3000/api/v1
# Device physique : IP de ton PC
```

### Base de données
```bash
docker compose up -d   # PostgreSQL
```

---

## Règles produit (rappel)

1. Résultats IA = estimations jusqu'à validation utilisateur  
2. Pas de wallet interne au MVP  
3. Pas de paiement des matériaux sur la plateforme  
4. Clés API jamais dans le mobile  
5. Webhooks idempotents  
6. Paiement abonnement toujours vérifié côté serveur  

---

## Roadmap code

- [x] Auth + Users + Materials + Passports  
- [x] Buildings  
- [x] Subscriptions (structure)  
- [x] Flutter auth + matériaux  
- [ ] CinetPay réel + webhook  
- [ ] Upload photos + stockage S3  
- [ ] Analyse IA (OpenAI Vision)  
- [ ] Messagerie  
- [ ] Dashboard Admin (Next.js)  
