import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, MinLength, MaxLength } from 'class-validator';

export class SendMessageDto {
  @ApiProperty({ description: 'ID du destinataire' })
  @IsString()
  receiverId: string;

  @ApiProperty({ example: 'Bonjour, le matériau est-il toujours disponible ?' })
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  content: string;

  @ApiPropertyOptional({ description: 'ID du matériau concerné (optionnel)' })
  @IsOptional()
  @IsString()
  materialId?: string;
}
