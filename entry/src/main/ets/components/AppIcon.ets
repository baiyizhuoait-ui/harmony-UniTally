import { hasSystemSymbol, getSystemSymbol, getEmojiFallback } from '../utils/IconUtil'

/**
 * AppIcon - Unified icon component
 * Uses SymbolGlyph for system symbols, Text for emoji fallback
 */
@Component
export struct AppIcon {
  @Prop icon: string = '' // lucide icon name or emoji
  @Prop fontSize: number = 20
  @Prop fontColor: ResourceColor = ''
  @Prop fontWeight: FontWeight = FontWeight.Normal

  build() {
    if (this.isSystemSymbol()) {
      SymbolGlyph($r(getSystemSymbol(this.icon)))
        .fontSize(this.fontSize)
        .fontColor(this.fontColor ? [this.fontColor] : [Color.Black])
    } else {
      Text(this.getDisplayIcon())
        .fontSize(this.fontSize)
        .fontColor(this.fontColor ? this.fontColor : '#333333')
        .fontWeight(this.fontWeight)
        .textAlign(TextAlign.Center)
    }
  }

  private isSystemSymbol(): boolean {
    return hasSystemSymbol(this.icon)
  }

  private getDisplayIcon(): string {
    // If it's already an emoji (not a lucide name), return as-is
    if (this.isEmoji(this.icon)) {
      return this.icon
    }
    return getEmojiFallback(this.icon)
  }

  private isEmoji(str: string): boolean {
    // Simple check: if it contains non-ASCII characters or common emoji ranges
    for (let i = 0; i < str.length; i++) {
      const code = str.charCodeAt(i)
      if (code > 0x1F000 || (code >= 0x2600 && code <= 0x27BF) || (code >= 0x2000 && code <= 0x2BFF)) {
        return true
      }
    }
    return false
  }
}
