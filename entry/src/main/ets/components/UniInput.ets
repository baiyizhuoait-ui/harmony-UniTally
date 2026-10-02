/**
 * UniInput - 通用输入框组件
 * 精确还原原版 React 应用的输入框样式
 * 支持 4 种 UI 风格动态切换：极简 / 新拟态 / 粗野主义 / 赛博朋克
 *
 * 各主题样式：
 * - 极简：8px圆角、白底、1px浅灰边框、无阴影
 * - 新拟态：24px圆角、深底、无边框、凹陷双层阴影
 * - 粗野主义：0圆角、白底、2px黑边框、硬偏移阴影
 * - 赛博朋克：12px圆角、深紫底、1px紫边框、双层发光阴影
 */
import { UIStyle, PrimaryTextColorMap, SecondaryTextColorMap, InputBackgroundMap, InputBorderMap, RadiusMap, MINIMALIST_RADIUS, MINIMALIST_BORDER, MINIMALIST_BACKGROUND, NEUMORPHISM_RADIUS, NEUMORPHISM_SHADOW_DARK, NEUMORPHISM_SHADOW_LIGHT, NEUMORPHISM_FOREGROUND, NEUMORPHISM_BACKGROUND, BRUTALISM_RADIUS, BRUTALISM_BORDER, BRUTALISM_BACKGROUND, CYBERPUNK_RADIUS, CYBERPUNK_BORDER, CYBERPUNK_FOREGROUND, CYBERPUNK_BACKGROUND } from '../constants/UIStyleConst'

@Component
export struct UniInput {
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist
  @Prop overrideStyle: string = ''
  @Link textValue: string
  @Prop placeholder: string = ''
  @Prop inputType: InputType = InputType.Normal
  @Prop isDisabled: boolean = false
  @Prop heightValue: number = 44
  @Prop marginValue: Length = 8

  private getEffectiveStyle(): string {
    return this.overrideStyle || this.currentStyle
  }

  build() {
    TextInput({
      placeholder: this.placeholder,
      text: this.textValue
    })
      .type(this.inputType)
      .placeholderColor(this.getPlaceholderColor())
      .placeholderFont({ size: 14 })
      .fontColor(this.getFontColor())
      .fontSize(15)
      .caretColor(this.getFontColor())
      .width('100%')
      .height(this.heightValue)
      .margin(this.marginValue)
      .padding({ left: 14, right: 14 })
      .enabled(!this.isDisabled)
      .opacity(this.isDisabled ? 0.5 : 1.0)
      .borderRadius(this.getBorderRadius())
      .backgroundColor(this.getBackgroundColor())
      .border(this.getBorder())
      .shadow(this.getFirstShadow())
      .shadow(this.getSecondShadow())
      .onChange((value: string) => {
        this.textValue = value
      })
  }

  // ==================== 圆角 ====================

  private getBorderRadius(): number {
    const style = this.getEffectiveStyle()
    if (style === UIStyle.Neumorphism) {
      return NEUMORPHISM_RADIUS
    } else if (style === UIStyle.Brutalism) {
      return BRUTALISM_RADIUS
    } else if (style === UIStyle.Cyberpunk) {
      return CYBERPUNK_RADIUS
    }
    return MINIMALIST_RADIUS
  }

  // ==================== 背景色 ====================

  private getBackgroundColor(): ResourceColor {
    return InputBackgroundMap.get(this.getEffectiveStyle()) || '#FFFFFF'
  }

  // ==================== 边框 ====================

  private getBorder(): BorderOptions {
    const style = this.getEffectiveStyle()
    if (style === UIStyle.Neumorphism) {
      // 新拟态：无边框
      return { width: 0, color: Color.Transparent }
    } else if (style === UIStyle.Brutalism) {
      // 粗野主义：2px 黑色边框（比卡片的 3px 略细）
      return { width: 2, color: BRUTALISM_BORDER, style: BorderStyle.Solid }
    } else if (style === UIStyle.Cyberpunk) {
      // 赛博朋克：1px 紫色边框
      return { width: 1, color: CYBERPUNK_BORDER, style: BorderStyle.Solid }
    }
    // 极简：1px 浅灰边框
    return { width: 1, color: MINIMALIST_BORDER, style: BorderStyle.Solid }
  }

  // ==================== 文字色 ====================

  private getFontColor(): ResourceColor {
    return PrimaryTextColorMap.get(this.getEffectiveStyle()) || '#1A1A1A'
  }

  private getPlaceholderColor(): ResourceColor {
    return SecondaryTextColorMap.get(this.getEffectiveStyle()) || '#737373'
  }

  // ==================== 阴影 ====================

  private getFirstShadow(): ShadowOptions {
    const style = this.getEffectiveStyle()
    if (style === UIStyle.Neumorphism) {
      // 凹陷效果：暗色右下阴影（与凸起的亮色右下相反）
      return { radius: 6, color: NEUMORPHISM_SHADOW_DARK, offsetX: 3, offsetY: 3 }
    } else if (style === UIStyle.Brutalism) {
      // 硬偏移阴影
      return { radius: 0, color: BRUTALISM_BORDER, offsetX: 3, offsetY: 3 }
    } else if (style === UIStyle.Cyberpunk) {
      // 内发光
      return { radius: 8, color: '#409333EA', offsetX: 0, offsetY: 0 }
    }
    // 极简：无阴影
    return { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 }
  }

  private getSecondShadow(): ShadowOptions {
    const style = this.getEffectiveStyle()
    if (style === UIStyle.Neumorphism) {
      // 凹陷效果：亮色左上阴影（与凸起的暗色左上相反）
      return { radius: 6, color: NEUMORPHISM_SHADOW_LIGHT, offsetX: -3, offsetY: -3 }
    } else if (style === UIStyle.Cyberpunk) {
      // 外发光
      return { radius: 15, color: '#209333EA', offsetX: 0, offsetY: 0 }
    }
    // 极简 / 粗野主义：无第二层阴影
    return { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 }
  }
}

// ==================== 预览 ====================

@Preview
@Component
struct UniInputPreview {
  @State minimalistText: string = ''
  @State neumorphismText: string = ''
  @State brutalismText: string = ''
  @State cyberpunkText: string = ''
  @State numberText: string = ''

  build() {
    Scroll() {
      Column({ space: 24 }) {
        Text('UniInput 四种主题风格预览')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })

        // ========== 极简风格 ==========
        Column({ space: 12 }) {
          Text('极简风格 (Minimalist)')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 4 })

          UniInput({
            overrideStyle: UIStyle.Minimalist,
            textValue: this.minimalistText,
            placeholder: '请输入内容...',
            inputType: InputType.Normal
          })
          UniInput({
            overrideStyle: UIStyle.Minimalist,
            textValue: this.numberText,
            placeholder: '输入金额...',
            inputType: InputType.NUMBER_DECIMAL
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(MINIMALIST_BACKGROUND)
        .borderRadius(8)

        // ========== 新拟态风格 ==========
        Column({ space: 12 }) {
          Text('新拟态风格 (Neumorphism)')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(NEUMORPHISM_FOREGROUND)
            .margin({ bottom: 4 })

          UniInput({
            overrideStyle: UIStyle.Neumorphism,
            textValue: this.neumorphismText,
            placeholder: '凹陷输入框...',
            inputType: InputType.Normal
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(NEUMORPHISM_BACKGROUND)
        .borderRadius(8)

        // ========== 粗野主义风格 ==========
        Column({ space: 12 }) {
          Text('粗野主义风格 (Brutalism)')
            .fontSize(15)
            .fontWeight(FontWeight.Bolder)
            .margin({ bottom: 4 })

          UniInput({
            overrideStyle: UIStyle.Brutalism,
            textValue: this.brutalismText,
            placeholder: '粗黑边框输入框...',
            inputType: InputType.Normal
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(BRUTALISM_BACKGROUND)
        .borderRadius(8)

        // ========== 赛博朋克风格 ==========
        Column({ space: 12 }) {
          Text('赛博朋克风格 (Cyberpunk)')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(CYBERPUNK_FOREGROUND)
            .margin({ bottom: 4 })

          UniInput({
            overrideStyle: UIStyle.Cyberpunk,
            textValue: this.cyberpunkText,
            placeholder: '霓虹输入框...',
            inputType: InputType.Normal
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(CYBERPUNK_BACKGROUND)
        .borderRadius(8)
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
