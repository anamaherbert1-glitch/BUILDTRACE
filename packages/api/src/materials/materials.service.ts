import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMaterialDto } from './dto/create-material.dto';
import { MaterialStatus } from '@prisma/client';

@Injectable()
export class MaterialsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateMaterialDto) {
    const material = await this.prisma.material.create({
      data: {
        ...dto,
        ownerId: userId,
        status: MaterialStatus.DRAFT,
      },
    });

    // Créer un passeport brouillon
    const passportCode = await this.generatePassportCode();
    await this.prisma.materialPassport.create({
      data: {
        materialId: material.id,
        passportCode,
        isPublic: false,
      },
    });

    await this.prisma.event.create({
      data: {
        userId,
        type: 'material_created',
        payload: { materialId: material.id },
      },
    });

    return this.findOne(material.id, userId);
  }

  async findAll(params: {
    status?: MaterialStatus;
    category?: string;
    city?: string;
    skip?: number;
    take?: number;
  }) {
    const { status = MaterialStatus.PUBLISHED, category, city, skip = 0, take = 20 } = params;

    return this.prisma.material.findMany({
      where: {
        status,
        ...(category && { category }),
        ...(city && { city: { contains: city, mode: 'insensitive' } }),
      },
      include: {
        passport: true,
        media: { take: 3 },
        owner: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
      orderBy: { publishedAt: 'desc' },
      skip,
      take,
    });
  }


  async findMine(userId: string) {
    return this.prisma.material.findMany({
      where: { ownerId: userId },
      include: {
        passport: true,
        media: { take: 1 },
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async findOne(id: string, userId?: string) {
    const material = await this.prisma.material.findUnique({
      where: { id },
      include: {
        passport: true,
        media: true,
        aiAnalyses: {
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
        owner: {
          select: { id: true, firstName: true, lastName: true, phone: true },
        },
        building: true,
      },
    });

    if (!material) throw new NotFoundException('Matériau non trouvé');

    // Si non publié, seul le propriétaire peut le voir
    if (
      material.status !== MaterialStatus.PUBLISHED &&
      material.ownerId !== userId
    ) {
      throw new ForbiddenException('Accès non autorisé');
    }

    return material;
  }

  async publish(id: string, userId: string) {
    const material = await this.prisma.material.findUnique({ where: { id } });
    if (!material) throw new NotFoundException('Matériau non trouvé');
    if (material.ownerId !== userId) throw new ForbiddenException();

    // TODO: Vérifier les limites du plan d'abonnement

    const updated = await this.prisma.material.update({
      where: { id },
      data: {
        status: MaterialStatus.PUBLISHED,
        publishedAt: new Date(),
      },
      include: { passport: true },
    });

    // Rendre le passeport public
    await this.prisma.materialPassport.update({
      where: { materialId: id },
      data: { isPublic: true },
    });

    await this.prisma.event.create({
      data: {
        userId,
        type: 'material_published',
        payload: { materialId: id },
      },
    });

    return updated;
  }

  private async generatePassportCode(): Promise<string> {
    const count = await this.prisma.materialPassport.count();
    const next = count + 1;
    return `BT-${String(next).padStart(6, '0')}`;
  }
}
