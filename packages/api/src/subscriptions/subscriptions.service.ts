import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SubscriptionPlan } from '@prisma/client';

/** Plans BUILDTRACE — prix en XOF (FCFA) */
export const PLANS = {
  FREE: {
    plan: 'FREE' as SubscriptionPlan,
    name: 'Free',
    price: 0,
    currency: 'XOF',
    features: ['5 matériaux', 'Passeport basique', 'Recherche'],
  },
  STARTER: {
    plan: 'STARTER' as SubscriptionPlan,
    name: 'Starter',
    price: 5000,
    currency: 'XOF',
    features: ['30 matériaux', 'QR codes', 'Support email'],
  },
  PRO: {
    plan: 'PRO' as SubscriptionPlan,
    name: 'Pro',
    price: 15000,
    currency: 'XOF',
    features: ['Illimité', 'IA (50 analyses/mois)', 'Priorité support'],
  },
  BUSINESS: {
    plan: 'BUSINESS' as SubscriptionPlan,
    name: 'Business',
    price: 50000,
    currency: 'XOF',
    features: ['Multi-utilisateurs', 'IA illimitée', 'Dashboard entreprise'],
  },
};

@Injectable()
export class SubscriptionsService {
  constructor(private prisma: PrismaService) {}

  getPlans() {
    return Object.values(PLANS);
  }

  async getMySubscription(userId: string) {
    const sub = await this.prisma.subscription.findFirst({
      where: { userId, status: 'ACTIVE' },
      orderBy: { createdAt: 'desc' },
    });
    return sub ?? { plan: 'FREE', status: 'ACTIVE', price: 0 };
  }

  /**
   * Initie un checkout CinetPay (à compléter avec les clés réelles).
   * Pour l'instant : structure prête, pas d'appel PSP.
   */
  async createCheckout(userId: string, plan: SubscriptionPlan) {
    const planConfig = PLANS[plan];
    if (!planConfig || plan === 'FREE') {
      throw new NotFoundException('Plan invalide');
    }

    // TODO: Appeler CinetPay API pour créer la transaction
    // const transaction = await cinetpay.init({ amount: planConfig.price, ... })

    return {
      plan: planConfig.plan,
      amount: planConfig.price,
      currency: planConfig.currency,
      // paymentUrl: transaction.payment_url, // à brancher
      message:
        'Checkout CinetPay à brancher. Pour le MVP local, activez manuellement le plan via admin.',
    };
  }

  /** Appelé par le webhook CinetPay après paiement confirmé */
  async activateFromWebhook(userId: string, plan: SubscriptionPlan, providerRef: string) {
    // Idempotence : si déjà activé avec ce providerRef, ne rien faire
    const existing = await this.prisma.subscription.findFirst({
      where: { providerRef },
    });
    if (existing) return existing;

    // Désactiver l'ancien
    await this.prisma.subscription.updateMany({
      where: { userId, status: 'ACTIVE' },
      data: { status: 'CANCELED', canceledAt: new Date() },
    });

    const planConfig = PLANS[plan];
    const endsAt = new Date();
    endsAt.setMonth(endsAt.getMonth() + 1);

    const sub = await this.prisma.subscription.create({
      data: {
        userId,
        plan,
        status: 'ACTIVE',
        price: planConfig.price,
        currency: planConfig.currency,
        endsAt,
        paymentProvider: 'cinetpay',
        providerRef,
      },
    });

    await this.prisma.event.create({
      data: {
        userId,
        type: 'subscription_activated',
        payload: { plan, providerRef },
      },
    });

    await this.prisma.auditLog.create({
      data: {
        actorId: userId,
        action: 'subscription.activate',
        targetType: 'subscription',
        targetId: sub.id,
        metadata: { plan, providerRef },
      },
    });

    return sub;
  }
}
