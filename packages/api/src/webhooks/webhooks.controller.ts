import { Controller, Post, Body, Headers, Logger, BadRequestException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiExcludeEndpoint } from '@nestjs/swagger';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { SubscriptionPlan } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Webhooks serveur-à-serveur.
 * CinetPay appelle cet endpoint après un paiement.
 * Ne jamais exposer de logique sensible côté mobile.
 */
@ApiTags('Webhooks')
@Controller('webhooks')
export class WebhooksController {
  private readonly logger = new Logger(WebhooksController.name);

  constructor(
    private subscriptionsService: SubscriptionsService,
    private prisma: PrismaService,
  ) {}

  @Post('payment')
  @ApiOperation({ summary: 'Webhook CinetPay (abonnement)' })
  async paymentWebhook(
    @Body() body: any,
    @Headers('x-token') token?: string,
  ) {
    this.logger.log(`Webhook payment reçu: ${JSON.stringify(body)}`);

    // TODO: Vérifier la signature / token CinetPay
    // if (token !== process.env.CINETPAY_SECRET_KEY) throw new BadRequestException('Invalid token');

    // Adapter selon le format réel CinetPay
    const status = body?.status || body?.cpm_trans_status;
    const providerRef = body?.transaction_id || body?.cpm_trans_id || body?.payment_token;
    const metadata = body?.metadata || body?.custom || {};
    const userId = metadata.userId || body?.userId;
    const plan = (metadata.plan || body?.plan) as SubscriptionPlan;

    if (status !== 'ACCEPTED' && status !== 'SUCCESS' && status !== '00') {
      this.logger.warn(`Paiement non accepté: ${status}`);
      return { received: true, activated: false };
    }

    if (!userId || !plan || !providerRef) {
      this.logger.error('Webhook incomplet: userId/plan/providerRef manquants');
      throw new BadRequestException('Payload incomplet');
    }

    const sub = await this.subscriptionsService.activateFromWebhook(
      userId,
      plan,
      String(providerRef),
    );

    return { received: true, activated: true, subscriptionId: sub.id };
  }
}
