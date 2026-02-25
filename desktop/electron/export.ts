import fs from 'fs/promises'
import { Document, Paragraph, TextRun, Packer } from 'docx'
import type { Note } from '../src/types'

export async function exportNote(
  note: Note,
  format: 'md' | 'txt' | 'docx',
  filePath: string
): Promise<void> {
  switch (format) {
    case 'md':
      await fs.writeFile(filePath, `# ${note.title}\n\n${note.content}`, 'utf-8')
      break

    case 'txt':
      await fs.writeFile(filePath, `${note.title}\n\n${note.content}`, 'utf-8')
      break

    case 'docx':
      const doc = new Document({
        sections: [{
          properties: {},
          children: [
            new Paragraph({
              children: [new TextRun({ text: note.title, bold: true, size: 32 })],
            }),
            new Paragraph({ text: '' }),
            ...note.content.split('\n').map(line =>
              new Paragraph({ children: [new TextRun(line)] })
            ),
          ],
        }],
      })
      const buffer = await Packer.toBuffer(doc)
      await fs.writeFile(filePath, buffer)
      break

    default:
      throw new Error(`Unsupported format: ${format}`)
  }
}
