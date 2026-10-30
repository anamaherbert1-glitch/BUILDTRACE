import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsNumber,
  IsEnum,
  MinLength,
  MaxLength,
  Min,
} from 'class-validator';
import { MaterialCondition } from '@prisma/client';

export class CreateMaterialDto {
  @ApiProperty({ example: 'Fenêtre aluminium double vitrage' })
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  title: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @ApiProperty({ example: 'fenetre' })
  @IsString()
  category: string;

  @ApiPropertyOptional({ example: 'aluminium' })
  @IsOptional()
  @IsString()
  materialType?: string;

  @ApiPropertyOptional({ example: '1.20 x 1.00 m' })
  @IsOptional()
  @IsString()
  dimensions?: string;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsNumber()
  @Min(0.01)
  quantity?: number;

  @ApiPropertyOptional({ example: 'unité' })
  @IsOptional()
  @IsString()
  unit?: string;

  @ApiPropertyOptional({ enum: MaterialCondition })
  @IsOptional()
  @IsEnum(MaterialCondition)
  condition?: MaterialCondition;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  longitude?: number;

  @ApiPropertyOptional({ example: 'Lomé' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  buildingId?: string;
}
