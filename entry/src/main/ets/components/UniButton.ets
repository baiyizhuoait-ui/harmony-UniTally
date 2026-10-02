/**
 * UniButton - 通用按钮组件
 * 精确还原原版 React 应用的按钮样式
 * 支持 4 种 UI 风格：极简 / 新拟态 / 粗野主义 / 赛博朋克
 * 支持 6 种变体和 4 种尺寸
 */
import {
  UIStyle, PrimaryTextColorMap, SecondaryTextColorMap,
  PrimaryColorMap, PrimaryForegroundMap, RadiusMap,
  MINIMALIST_PRIMARY, MINIMALIST_SECONDARY, MINIMALIST_BORDER,
  NEUMORPHISM_PRIMARY, NEUMORPHISM_SECONDARY, NEUMORPHISM_BACKGROUND, NEUMORPHISM_SHADOW_DARK, NEUMORPHISM_SHADOW_LIGHT,
  BRUTALISM_SECONDARY, BRUTALISM_ACCENT, BRUTALISM_FOREGROUND, BRUTALISM_BORDER,
  CYBERPUNK_SECONDARY, CYBERPUNK_DESTRUCTIVE, CYBERPUNK_CYBER_PRIMARY, CYBERPUNK_FOREGROUND, CYBERPUNK_BORDER
} from '../constants/UIStyleConst'

// ==================== 枚举定义 ====================

export enum ButtonVariant {
  Default = 'default',
  Destructive = 'destructive',
  Outline = 'outline',
  Secondary = 'secondary',
  Ghost = 'ghost',
  Link = 'link'
}

export enum ButtonSize {
  Default = 'default',
  SM = 'sm',
  LG = 'lg',
  Icon = 'icon'
}

// ==================== 默认插槽构建器 ====================

@Builder
function defaultButtonContent() {
}

// ==================== UniButton 组件 ====================

@Component
export struct UniButton {
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist
  @Prop overrideStyle: string = ''
  @Prop variant: string = ButtonVariant.Default
  @Prop buttonSize: string = ButtonSize.Default
  @BuilderParam content: () => void = defaultButtonContent
  onClickHandler: () => void = () => {
  }
  @Prop isDisabled: boolean = false
  @Prop widthValue: Length = ''
  @Prop marginValue: Margin | Length = 0

  private getActiveStyle(): string {
    return this.overrideStyle || this.currentStyle
  }

  // ==================== 尺寸计算 ====================

  private getHeight(): number {
    switch (this.buttonSize) {
      case ButtonSize.SM:
        return 36
      case ButtonSize.LG:
        return 44
      case ButtonSize.Icon:
        return 40
      default:
        return 40
    }
  }

  private getWidth(): Length {
    if (this.widthValue !== '') {
      return this.widthValue
    }
    if (this.buttonSize === ButtonSize.Icon) {
      return 40
    }
    return '100%'
  }

  private getPaddingH(): number {
    switch (this.buttonSize) {
      case ButtonSize.SM:
        return 12
      case ButtonSize.LG:
        return 32
      case ButtonSize.Icon:
        return 0
      default:
        return 16
    }
  }

  // ==================== 圆角 ====================

  private getBorderRadius(): number {
    if (this.variant === ButtonVariant.Link) {
      return 0
    }
    return RadiusMap.get(this.getActiveStyle()) ?? 8
  }

  // ==================== 背景色 ====================

  private getBackgroundColor(): ResourceColor {
    const s = this.getActiveStyle()
    const v = this.variant

    if (v === ButtonVariant.Ghost || v === ButtonVariant.Link) {
      return Color.Transparent
    }

    if (v === ButtonVariant.Outline) {
      if (s === UIStyle.Neumorphism) {
        return NEUMORPHISM_BACKGROUND
      }
      return Color.Transparent
    }

    if (v === ButtonVariant.Secondary) {
      switch (s) {
        case UIStyle.Minimalist:
          return MINIMALIST_SECONDARY
        case UIStyle.Neumorphism:
          return NEUMORPHISM_SECONDARY
        case UIStyle.Brutalism:
          return BRUTALISM_SECONDARY
        case UIStyle.Cyberpunk:
          return CYBERPUNK_SECONDARY
        default:
          return MINIMALIST_SECONDARY
      }
    }

    if (v === ButtonVariant.Destructive) {
      if (s === UIStyle.Cyberpunk) {
        return CYBERPUNK_DESTRUCTIVE
      }
      return '#EF4444'
    }

    // Default: primary background
    switch (s) {
      case UIStyle.Minimalist:
        return MINIMALIST_PRIMARY
      case UIStyle.Neumorphism:
        return NEUMORPHISM_PRIMARY
      case UIStyle.Brutalism:
        return BRUTALISM_ACCENT
      case UIStyle.Cyberpunk:
        return CYBERPUNK_CYBER_PRIMARY
      default:
        return MINIMALIST_PRIMARY
    }
  }

  // ==================== 文字颜色 ====================

  private getFontColor(): ResourceColor {
    const s = this.getActiveStyle()
    const v = this.variant

    if (v === ButtonVariant.Link) {
      return PrimaryColorMap.get(s) || '#3B82F6'
    }

    if (v === ButtonVariant.Ghost) {
      if (s === UIStyle.Cyberpunk) {
        return CYBERPUNK_CYBER_PRIMARY
      }
      return PrimaryTextColorMap.get(s) || '#1A1A1A'
    }

    if (v === ButtonVariant.Outline) {
      if (s === UIStyle.Cyberpunk) {
        return CYBERPUNK_FOREGROUND
      }
      if (s === UIStyle.Brutalism) {
        return BRUTALISM_FOREGROUND
      }
      return PrimaryTextColorMap.get(s) || '#1A1A1A'
    }

    if (v === ButtonVariant.Secondary) {
      return PrimaryTextColorMap.get(s) || '#1A1A1A'
    }

    if (v === ButtonVariant.Destructive) {
      return '#FFFFFF'
    }

    // Default: primary-foreground text
    switch (s) {
      case UIStyle.Minimalist:
        return '#FFFFFF'
      case UIStyle.Neumorphism:
        return '#FFFFFF'
      case UIStyle.Brutalism:
        return BRUTALISM_FOREGROUND
      case UIStyle.Cyberpunk:
        return '#FFFFFF'
      default:
        return '#FFFFFF'
    }
  }

  // ==================== 边框 ====================

  private getBorder(): BorderOptions {
    const s = this.getActiveStyle()
    const v = this.variant

    if (v === ButtonVariant.Ghost || v === ButtonVariant.Link) {
      return { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
    }

    if (v === ButtonVariant.Outline) {
      switch (s) {
        case UIStyle.Minimalist:
          return { width: 1, color: MINIMALIST_BORDER, style: BorderStyle.Solid }
        case UIStyle.Neumorphism:
          return { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
        case UIStyle.Brutalism:
          return { width: 3, color: BRUTALISM_BORDER, style: BorderStyle.Solid }
        case UIStyle.Cyberpunk:
          return { width: 1, color: CYBERPUNK_BORDER, style: BorderStyle.Solid }
        default:
          return { width: 1, color: MINIMALIST_BORDER, style: BorderStyle.Solid }
      }
    }

    // Default / Destructive / Secondary
    switch (s) {
      case UIStyle.Brutalism:
        return { width: 3, color: BRUTALISM_BORDER, style: BorderStyle.Solid }
      default:
        return { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
    }
  }

  // ==================== 阴影 ====================

  private getShadow1(): ShadowOptions {
    const s = this.getActiveStyle()
    const v = this.variant

    if (v === ButtonVariant.Ghost || v === ButtonVariant.Link) {
      return { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 }
    }

    switch (s) {
      case UIStyle.Neumorphism:
        return { radius: 16, color: NEUMORPHISM_SHADOW_DARK, offsetX: 8, offsetY: 8 }
      case UIStyle.Brutalism:
        return { radius: 0, color: '#0D0D0D', offsetX: 4, offsetY: 4 }
      case UIStyle.Cyberpunk:
        return this.getCyberpunkShadow()
      default:
        return { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 }
    }
  }

  private getShadow2(): ShadowOptions {
    const s = this.getActiveStyle()
    const v = this.variant

    if (s === UIStyle.Neumorphism && v !== ButtonVariant.Ghost && v !== ButtonVariant.Link) {
      return { radius: 16, color: NEUMORPHISM_SHADOW_LIGHT, offsetX: -8, offsetY: -8 }
    }
    return { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 }
  }

  private getCyberpunkShadow(): ShadowOptions {
    if (this.variant === ButtonVariant.Destructive) {
      return { radius: 12, color: '#60FF0066', offsetX: 0, offsetY: 0 }
    }
    if (this.variant === ButtonVariant.Outline || this.variant === ButtonVariant.Secondary) {
      return { radius: 8, color: '#309333EA', offsetX: 0, offsetY: 0 }
    }
    return { radius: 12, color: '#60CC00FF', offsetX: 0, offsetY: 0 }
  }

  // ==================== 构建 ====================

  build() {
    Column() {
      this.content()
    }
    .width(this.getWidth())
    .height(this.getHeight())
    .padding({ left: this.getPaddingH(), right: this.getPaddingH() })
    .margin(this.marginValue)
    .justifyContent(FlexAlign.Center)
    .borderRadius(this.getBorderRadius())
    .border(this.getBorder())
    .backgroundColor(this.getBackgroundColor())
    .shadow(this.getShadow1())
    .shadow(this.getShadow2())
    .enabled(!this.isDisabled)
    .opacity(this.isDisabled ? 0.5 : 1.0)
    .onClick(() => {
      if (!this.isDisabled) {
        this.onClickHandler()
      }
    })
  }
}

// ==================== 预览 ====================

@Preview
@Component
struct UniButtonPreview {
  build() {
    Scroll() {
      Column({ space: 24 }) {
        Text('UniButton 四种主题风格预览')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })

        // ========== 极简风格 ==========
        Column({ space: 10 }) {
          Text('极简风格 (Minimalist)')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 4 })

          UniButton({ overrideStyle: UIStyle.Minimalist, variant: ButtonVariant.Default, buttonSize: ButtonSize.Default }) {
            Text('Default')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
          }
          UniButton({ overrideStyle: UIStyle.Minimalist, variant: ButtonVariant.Destructive, buttonSize: ButtonSize.Default }) {
            Text('Destructive')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
          }
          UniButton({ overrideStyle: UIStyle.Minimalist, variant: ButtonVariant.Outline, buttonSize: ButtonSize.Default }) {
            Text('Outline')
              .fontSize(14)
              .fontColor('#1A1A1A')
              .fontWeight(FontWeight.Medium)
          }
          UniButton({ overrideStyle: UIStyle.Minimalist, variant: ButtonVariant.Secondary, buttonSize: ButtonSize.Default }) {
            Text('Secondary')
              .fontSize(14)
              .fontColor('#1A1A1A')
              .fontWeight(FontWeight.Medium)
          }
          UniButton({ overrideStyle: UIStyle.Minimalist, variant: ButtonVariant.Ghost, buttonSize: ButtonSize.Default }) {
            Text('Ghost')
              .fontSize(14)
              .fontColor('#1A1A1A')
              .fontWeight(FontWeight.Medium)
          }
          UniButton({ overrideStyle: UIStyle.Minimalist, variant: ButtonVariant.Link, buttonSize: ButtonSize.Default }) {
            Text('Link')
              .fontSize(14)
              .fontColor('#3B82F6')
              .fontWeight(FontWeight.Medium)
              .decoration({ type: TextDecorationType.Underline, color: '#3B82F6' })
          }

          Row({ space: 10 }) {
            UniButton({ overrideStyle: UIStyle.Minimalist, variant: ButtonVariant.Default, buttonSize: ButtonSize.SM, widthValue: '' }) {
              Text('SM')
                .fontSize(13)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium)
            }
            UniButton({ overrideStyle: UIStyle.Minimalist, variant: ButtonVariant.Default, buttonSize: ButtonSize.Default, widthValue: '' }) {
              Text('Default')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium)
            }
            UniButton({ overrideStyle: UIStyle.Minimalist, variant: ButtonVariant.Default, buttonSize: ButtonSize.LG, widthValue: '' }) {
              Text('LG')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium)
            }
            UniButton({ overrideStyle: UIStyle.Minimalist, variant: ButtonVariant.Default, buttonSize: ButtonSize.Icon, widthValue: '' }) {
              Text('✦')
                .fontSize(18)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F5F5F7')
        .borderRadius(8)

        // ========== 新拟态风格 ==========
        Column({ space: 10 }) {
          Text('新拟态风格 (Neumorphism)')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2D3748')
            .margin({ bottom: 4 })

          UniButton({ overrideStyle: UIStyle.Neumorphism, variant: ButtonVariant.Default, buttonSize: ButtonSize.Default }) {
            Text('Default')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          UniButton({ overrideStyle: UIStyle.Neumorphism, variant: ButtonVariant.Destructive, buttonSize: ButtonSize.Default }) {
            Text('Destructive')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          UniButton({ overrideStyle: UIStyle.Neumorphism, variant: ButtonVariant.Outline, buttonSize: ButtonSize.Default }) {
            Text('Outline')
              .fontSize(14)
              .fontColor('#2D3748')
              .fontWeight(FontWeight.Bold)
          }
          UniButton({ overrideStyle: UIStyle.Neumorphism, variant: ButtonVariant.Secondary, buttonSize: ButtonSize.Default }) {
            Text('Secondary')
              .fontSize(14)
              .fontColor('#2D3748')
              .fontWeight(FontWeight.Bold)
          }
          UniButton({ overrideStyle: UIStyle.Neumorphism, variant: ButtonVariant.Ghost, buttonSize: ButtonSize.Default }) {
            Text('Ghost')
              .fontSize(14)
              .fontColor('#2D3748')
              .fontWeight(FontWeight.Bold)
          }
          UniButton({ overrideStyle: UIStyle.Neumorphism, variant: ButtonVariant.Link, buttonSize: ButtonSize.Default }) {
            Text('Link')
              .fontSize(14)
              .fontColor('#3B82F6')
              .fontWeight(FontWeight.Bold)
              .decoration({ type: TextDecorationType.Underline, color: '#3B82F6' })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#DDE3ED')
        .borderRadius(8)

        // ========== 粗野主义风格 ==========
        Column({ space: 10 }) {
          Text('粗野主义风格 (Brutalism)')
            .fontSize(15)
            .fontWeight(FontWeight.Bolder)
            .fontColor('#0D0D0D')
            .margin({ bottom: 4 })

          UniButton({ overrideStyle: UIStyle.Brutalism, variant: ButtonVariant.Default, buttonSize: ButtonSize.Default }) {
            Text('DEFAULT')
              .fontSize(14)
              .fontColor('#0D0D0D')
              .fontWeight(FontWeight.Bolder)
          }
          UniButton({ overrideStyle: UIStyle.Brutalism, variant: ButtonVariant.Destructive, buttonSize: ButtonSize.Default }) {
            Text('DESTRUCTIVE')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bolder)
          }
          UniButton({ overrideStyle: UIStyle.Brutalism, variant: ButtonVariant.Outline, buttonSize: ButtonSize.Default }) {
            Text('OUTLINE')
              .fontSize(14)
              .fontColor('#0D0D0D')
              .fontWeight(FontWeight.Bolder)
          }
          UniButton({ overrideStyle: UIStyle.Brutalism, variant: ButtonVariant.Secondary, buttonSize: ButtonSize.Default }) {
            Text('SECONDARY')
              .fontSize(14)
              .fontColor('#0D0D0D')
              .fontWeight(FontWeight.Bolder)
          }
          UniButton({ overrideStyle: UIStyle.Brutalism, variant: ButtonVariant.Ghost, buttonSize: ButtonSize.Default }) {
            Text('GHOST')
              .fontSize(14)
              .fontColor('#0D0D0D')
              .fontWeight(FontWeight.Bolder)
          }
          UniButton({ overrideStyle: UIStyle.Brutalism, variant: ButtonVariant.Link, buttonSize: ButtonSize.Default }) {
            Text('LINK')
              .fontSize(14)
              .fontColor('#0D0D0D')
              .fontWeight(FontWeight.Bolder)
              .decoration({ type: TextDecorationType.Underline, color: '#0D0D0D' })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FAFAFA')
        .borderRadius(0)
        .border({ width: 3, color: '#0D0D0D', style: BorderStyle.Solid })

        // ========== 赛博朋克风格 ==========
        Column({ space: 10 }) {
          Text('赛博朋克风格 (Cyberpunk)')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#CC00FF')
            .margin({ bottom: 4 })

          UniButton({ overrideStyle: UIStyle.Cyberpunk, variant: ButtonVariant.Default, buttonSize: ButtonSize.Default }) {
            Text('Default')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          UniButton({ overrideStyle: UIStyle.Cyberpunk, variant: ButtonVariant.Destructive, buttonSize: ButtonSize.Default }) {
            Text('Destructive')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          UniButton({ overrideStyle: UIStyle.Cyberpunk, variant: ButtonVariant.Outline, buttonSize: ButtonSize.Default }) {
            Text('Outline')
              .fontSize(14)
              .fontColor('#F0E6FF')
              .fontWeight(FontWeight.Bold)
          }
          UniButton({ overrideStyle: UIStyle.Cyberpunk, variant: ButtonVariant.Secondary, buttonSize: ButtonSize.Default }) {
            Text('Secondary')
              .fontSize(14)
              .fontColor('#F0E6FF')
              .fontWeight(FontWeight.Bold)
          }
          UniButton({ overrideStyle: UIStyle.Cyberpunk, variant: ButtonVariant.Ghost, buttonSize: ButtonSize.Default }) {
            Text('Ghost')
              .fontSize(14)
              .fontColor('#CC00FF')
              .fontWeight(FontWeight.Bold)
          }
          UniButton({ overrideStyle: UIStyle.Cyberpunk, variant: ButtonVariant.Link, buttonSize: ButtonSize.Default }) {
            Text('Link')
              .fontSize(14)
              .fontColor('#CC00FF')
              .fontWeight(FontWeight.Bold)
              .decoration({ type: TextDecorationType.Underline, color: '#CC00FF' })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#0F0526')
        .borderRadius(12)
        .border({ width: 1, color: '#9333EA', style: BorderStyle.Solid })
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F0F0')
    .scrollBar(BarState.Auto)
  }
}
