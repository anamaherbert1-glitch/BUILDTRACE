import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MediaType } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';
import { randomUUID } from 'crypto';

@Injectable()
export class MediaService {
  private readonly uploadDir = path.join(process.cwd(), 'uploads');

  constructor(private prisma: PrismaService) {
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  async uploadForMaterial(
    userId: string,
    materialId: string,
    file: Express.Multer.File,
  ) {
    const material = await this.prisma.material.findUnique({
      where: { id: materialId },
    });
    if (!material) throw new NotFoundException('Matériau introuvable');
    if (material.ownerId !== userId) throw new ForbiddenException();

    if (!file) throw new BadRequestException('Fichier requis');

    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];
    if (!allowed.includes(file.mimetype)) {
      throw new BadRequestException('Format non supporté (JPEG, PNG, WebP)');
    }

    // Max 5 Mo
    if (file.size > 5 * 1024 * 1024) {
      throw new BadRequestException('Fichier trop volumineux (max 5 Mo)');
    }

    const ext = file.originalname.split('.').pop() || 'jpg';
    const key = `materials/${materialId}/${randomUUID()}.${ext}`;
    const fullPath = path.join(this.uploadDir, key);
    const dir = path.dirname(fullPath);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

    fs.writeFileSync(fullPath, file.buffer);

    // En local : URL relative. En prod : S3/R2
    const url = `/uploads/${key}`;

    const media = await this.prisma.media.create({
      data: {
        url,
        key,
        type: MediaType.IMAGE,
        mimeType: file.mimetype,
        size: file.size,
        materialId,
        uploadedBy: userId,
      },
    });

    await this.prisma.event.create({
      data: {
        userId,
        type: 'media_uploaded',
        payload: { mediaId: media.id, materialId },
      },
    });

    return media;
  }

  async listForMaterial(materialId: string) {
    return this.prisma.media.findMany({
      where: { materialId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async delete(userId: string, mediaId: string) {
    const media = await this.prisma.media.findUnique({
      where: { id: mediaId },
      include: { material: true },
    });
    if (!media) throw new NotFoundException('Média introuvable');
    if (media.material && media.material.ownerId !== userId) {
      throw new ForbiddenException();
    }

    if (media.key) {
      const fullPath = path.join(this.uploadDir, media.key);
      if (fs.existsSync(fullPath)) fs.unlinkSync(fullPath);
    }

    await this.prisma.media.delete({ where: { id: mediaId } });
    return { deleted: true };
  }
}
