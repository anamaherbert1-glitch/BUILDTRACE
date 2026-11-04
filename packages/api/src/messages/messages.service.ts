import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SendMessageDto } from './dto/send-message.dto';

@Injectable()
export class MessagesService {
  constructor(private prisma: PrismaService) {}

  async send(senderId: string, dto: SendMessageDto) {
    if (senderId === dto.receiverId) {
      throw new BadRequestException('Impossible de s\'envoyer un message à soi-même');
    }

    const receiver = await this.prisma.user.findUnique({
      where: { id: dto.receiverId },
    });
    if (!receiver || receiver.status !== 'ACTIVE') {
      throw new NotFoundException('Destinataire introuvable');
    }

    if (dto.materialId) {
      const material = await this.prisma.material.findUnique({
        where: { id: dto.materialId },
      });
      if (!material) throw new NotFoundException('Matériau introuvable');
    }

    const message = await this.prisma.message.create({
      data: {
        senderId,
        receiverId: dto.receiverId,
        content: dto.content,
        materialId: dto.materialId,
      },
      include: {
        sender: { select: { id: true, firstName: true, lastName: true } },
        receiver: { select: { id: true, firstName: true, lastName: true } },
        material: { select: { id: true, title: true } },
      },
    });

    await this.prisma.event.create({
      data: {
        userId: senderId,
        type: 'message_sent',
        payload: {
          messageId: message.id,
          receiverId: dto.receiverId,
          materialId: dto.materialId,
        },
      },
    });

    return message;
  }

  /** Liste des conversations (dernier message par interlocuteur) */
  async getConversations(userId: string) {
    const messages = await this.prisma.message.findMany({
      where: {
        OR: [{ senderId: userId }, { receiverId: userId }],
      },
      include: {
        sender: { select: { id: true, firstName: true, lastName: true, avatarUrl: true } },
        receiver: { select: { id: true, firstName: true, lastName: true, avatarUrl: true } },
        material: { select: { id: true, title: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Grouper par interlocuteur
    const map = new Map<string, {
      partner: { id: string; firstName: string; lastName: string; avatarUrl?: string | null };
      lastMessage: (typeof messages)[0];
      unreadCount: number;
    }>();

    for (const msg of messages) {
      const partnerId = msg.senderId === userId ? msg.receiverId : msg.senderId;
      const partner = msg.senderId === userId ? msg.receiver : msg.sender;

      if (!map.has(partnerId)) {
        map.set(partnerId, {
          partner,
          lastMessage: msg,
          unreadCount: 0,
        });
      }

      if (msg.receiverId === userId && !msg.isRead) {
        const entry = map.get(partnerId)!;
        entry.unreadCount += 1;
      }
    }

    return Array.from(map.values());
  }

  /** Messages d'une conversation avec un partenaire */
  async getThread(userId: string, partnerId: string) {
    const messages = await this.prisma.message.findMany({
      where: {
        OR: [
          { senderId: userId, receiverId: partnerId },
          { senderId: partnerId, receiverId: userId },
        ],
      },
      include: {
        sender: { select: { id: true, firstName: true, lastName: true } },
        material: { select: { id: true, title: true } },
      },
      orderBy: { createdAt: 'asc' },
    });

    // Marquer comme lus les messages reçus
    await this.prisma.message.updateMany({
      where: {
        senderId: partnerId,
        receiverId: userId,
        isRead: false,
      },
      data: { isRead: true },
    });

    return messages;
  }

  async getUnreadCount(userId: string) {
    return this.prisma.message.count({
      where: { receiverId: userId, isRead: false },
    });
  }
}
