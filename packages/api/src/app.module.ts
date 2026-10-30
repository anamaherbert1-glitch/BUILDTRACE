import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { MaterialsModule } from './materials/materials.module';
import { BuildingsModule } from './buildings/buildings.module';
import { SubscriptionsModule } from './subscriptions/subscriptions.module';
import { MessagesModule } from './messages/messages.module';
import { WebhooksModule } from './webhooks/webhooks.module';
import { MediaModule } from './media/media.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    MaterialsModule,
    BuildingsModule,
    SubscriptionsModule,
    MessagesModule,
    WebhooksModule,
    MediaModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
