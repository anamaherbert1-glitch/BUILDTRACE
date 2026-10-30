import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBuildingDto } from './dto/create-building.dto';

@Injectable()
export class BuildingsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateBuildingDto) {
    const building = await this.prisma.building.create({
      data: {
        ...dto,
        ownerId: userId,
      },
    });

    await this.prisma.event.create({
      data: {
        userId,
        type: 'building_created',
        payload: { buildingId: building.id },
      },
    });

    return building;
  }

  async findMyBuildings(userId: string) {
    return this.prisma.building.findMany({
      where: { ownerId: userId },
      include: {
        _count: { select: { materials: true } },
        media: { take: 1 },
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async findOne(id: string, userId?: string) {
    const building = await this.prisma.building.findUnique({
      where: { id },
      include: {
        materials: {
          where: userId
            ? { OR: [{ status: 'PUBLISHED' }, { ownerId: userId }] }
            : { status: 'PUBLISHED' },
          take: 50,
        },
        media: true,
        owner: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });

    if (!building) throw new NotFoundException('Bâtiment non trouvé');
    return building;
  }

  async update(id: string, userId: string, dto: Partial<CreateBuildingDto>) {
    const building = await this.prisma.building.findUnique({ where: { id } });
    if (!building) throw new NotFoundException('Bâtiment non trouvé');
    if (building.ownerId !== userId) throw new ForbiddenException();

    return this.prisma.building.update({
      where: { id },
      data: dto,
    });
  }
}
