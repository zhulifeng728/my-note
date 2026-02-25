import { nativeImage } from 'electron'
import sharp from 'sharp'

const MAX_WIDTH = 1920
const MAX_HEIGHT = 1920
const JPEG_QUALITY = 80
const MAX_SIZE_MB = 10

export interface CompressImageOptions {
  maxWidth?: number
  maxHeight?: number
  quality?: number
}

/**
 * 压缩图片并返回 Base64
 * @param buffer 图片 Buffer
 * @param options 压缩选项
 * @returns Base64 字符串 (data:image/jpeg;base64,...)
 */
export async function compressImage(
  buffer: Buffer,
  options: CompressImageOptions = {}
): Promise<string> {
  const maxWidth = options.maxWidth || MAX_WIDTH
  const maxHeight = options.maxHeight || MAX_HEIGHT
  const quality = options.quality || JPEG_QUALITY

  // 检查文件大小
  const sizeMB = buffer.length / (1024 * 1024)
  if (sizeMB > MAX_SIZE_MB) {
    throw new Error(`图片过大（${sizeMB.toFixed(2)}MB），最大支持 ${MAX_SIZE_MB}MB`)
  }

  try {
    // 使用 sharp 处理图片
    const image = sharp(buffer)
    const metadata = await image.metadata()

    if (!metadata.width || !metadata.height) {
      throw new Error('无法读取图片尺寸')
    }

    // 计算缩放比例
    let width = metadata.width
    let height = metadata.height

    if (width > maxWidth || height > maxHeight) {
      const widthRatio = maxWidth / width
      const heightRatio = maxHeight / height
      const ratio = Math.min(widthRatio, heightRatio)

      width = Math.round(width * ratio)
      height = Math.round(height * ratio)
    }

    // 压缩图片
    let compressed = image.resize(width, height, {
      fit: 'inside',
      withoutEnlargement: true,
    })

    // 转换为 JPEG（除非有透明度）
    if (metadata.hasAlpha) {
      compressed = compressed.png({ quality })
    } else {
      compressed = compressed.jpeg({ quality })
    }

    const compressedBuffer = await compressed.toBuffer()

    // 如果压缩后反而更大，使用原图
    const finalBuffer = compressedBuffer.length < buffer.length ? compressedBuffer : buffer

    // 转换为 Base64
    const base64 = finalBuffer.toString('base64')
    const mimeType = metadata.hasAlpha ? 'image/png' : 'image/jpeg'

    return `data:${mimeType};base64,${base64}`
  } catch (error) {
    console.error('[Image] Compression failed:', error)
    throw new Error('图片压缩失败')
  }
}

/**
 * 从文件路径压缩图片
 */
export async function compressImageFromPath(
  filePath: string,
  options?: CompressImageOptions
): Promise<string> {
  const fs = require('fs')
  const buffer = fs.readFileSync(filePath)
  return compressImage(buffer, options)
}

/**
 * 从 Data URL 压缩图片
 */
export async function compressImageFromDataURL(
  dataURL: string,
  options?: CompressImageOptions
): Promise<string> {
  // 提取 base64 部分
  const base64 = dataURL.split(',')[1]
  if (!base64) {
    throw new Error('Invalid data URL')
  }

  const buffer = Buffer.from(base64, 'base64')
  return compressImage(buffer, options)
}
