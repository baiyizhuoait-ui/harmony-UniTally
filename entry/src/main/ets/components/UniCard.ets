/**
 * UniCard 组件集 - 多主题风格卡片容器
 * 精确还原原版 React 应用的 4 种卡片样式
 * 极简 / 新拟态 / 粗野主义 / 赛博朋克
 *
 * 组件结构：
 * - UniCard: 主容器，监听全局主题样式
 * - UniCardHeader: 头部容器（flex column + space-y + padding）
 * - UniCardTitle: 标题组件（text-2xl font-semibold）
 * - UniCardDescription: 描述组件（text-sm text-muted）
 * - UniCardContent: 内容容器（padding pt-0）
 * - UniCardFooter: 底部容器（flex row items-center pt-0）
 */
import { UIStyle, PageBackgroundMap, PrimaryTextColorMap, SecondaryTextColorMap, CardBackgroundMap, CardBorderMap, RadiusMap, MINIMALIST_BORDER, MINIMALIST_RADIUS, NEUMORPHISM_RADIUS, NEUMORPHISM_SHADOW_DARK, NEUMORPHISM_SHADOW_LIGHT, BRUTALISM_RADIUS, BRUTALISM_BORDER, BRUTALISM_BORDER_WIDTH, BRUTALISM_SHADOW_OFFSET, CYBERPUNK_RADIUS, CYBERPUNK_BORDER, CYBERPUNK_CYBER_PRIMARY, CYBERPUNK_CYBER_SECONDARY } from '../constants/UIStyleConst'

// ==================== 默认插槽构建器 ====================

@Builder
function defaultContent() {
}

// ==================== UniCard 主容器组件 ====================

/**
 * UniCard 主容器
 * 监听全局 UI 风格，动态切换视觉效果
 * 使用 @BuilderParam 实现插槽机制
 */
@Component
export struct UniCard {
  // 监听全局 UI 风格
  @StorageProp('currentStyle') storageStyle: string = UIStyle.Minimalist

  // 可选：强制覆盖样式（用于预览）
  @Prop overrideStyle: string = ''

  // 插槽：卡片内容
  @BuilderParam content: () => void = defaultContent

  // 可选：卡片整体内边距
  @Prop paddingValue: Length = 20

  // 可选：卡片整体外边距
  @Prop marginValue: Margin | Length = 0

  // 计算当前样式
  private getCurrentStyle(): string {
    return this.overrideStyle || this.storageStyle
  }

  build() {
    if (this.getCurrentStyle() === UIStyle.Cyberpunk) {
      this.CyberpunkCard()
    } else if (this.getCurrentStyle() === UIStyle.Neumorphism) {
      this.NeumorphismCard()
    } else if (this.getCurrentStyle() === UIStyle.Brutalism) {
      this.BrutalismCard()
    } else {
      this.MinimalistCard()
    }
  }

  // ==================== 极简风格 ====================
  // 原版: borderRadius 0.5rem(8px), bg #FFF, border 1px solid #E5E5E5, shadow-sm
  @Builder
  MinimalistCard() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.paddingValue)
    .margin(this.marginValue)
    .borderRadius(MINIMALIST_RADIUS)
    .backgroundColor('#D9FFFFFF')
    .backgroundBlurStyle(BlurStyle.Thin)
    .border({ width: 1, color: MINIMALIST_BORDER, style: BorderStyle.Solid })
    .shadow({
      radius: 2,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 1
    })
    .alignItems(HorizontalAlign.Start)
  }

  // ==================== 新拟态风格 ====================
  // 原版: borderRadius 1.5rem(24px), bg 同背景色, 无边框
  // 双层阴影: 8px 8px 16px dark(#B8C4D6), -8px -8px 16px light(#FFFFFF)
  @Builder
  NeumorphismCard() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.paddingValue)
    .margin(this.marginValue)
    .borderRadius(NEUMORPHISM_RADIUS)
    .backgroundColor('#D9DDE3ED')
    .backgroundBlurStyle(BlurStyle.Thin)
    .border({ width: 0, color: Color.Transparent })
    // 暗色阴影（右下偏移）
    .shadow({
      radius: 16,
      color: NEUMORPHISM_SHADOW_DARK,
      offsetX: 8,
      offsetY: 8
    })
    // 亮色阴影（左上偏移）
    .shadow({
      radius: 16,
      color: NEUMORPHISM_SHADOW_LIGHT,
      offsetX: -8,
      offsetY: -8
    })
    .alignItems(HorizontalAlign.Start)
  }

  // ==================== 粗野主义风格 ====================
  // 原版: borderRadius 0, bg #FFD700(黄色卡片), border 3px solid #0D0D0D
  // 硬阴影: 4px 4px 0px 0px black（无模糊）
  @Builder
  BrutalismCard() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.paddingValue)
    .margin(this.marginValue)
    .borderRadius(BRUTALISM_RADIUS)
    .backgroundColor(CardBackgroundMap.get(this.getCurrentStyle()))
    .border({
      width: BRUTALISM_BORDER_WIDTH,
      color: BRUTALISM_BORDER,
      style: BorderStyle.Solid
    })
    .shadow({
      radius: 0,
      color: BRUTALISM_BORDER,
      offsetX: BRUTALISM_SHADOW_OFFSET,
      offsetY: BRUTALISM_SHADOW_OFFSET
    })
    .alignItems(HorizontalAlign.Start)
  }

  // ==================== 赛博朋克风格 ====================
  // 原版: borderRadius 0.75rem(12px), bg #1A0A3A(深色卡片)
  // Stack 布局: 外层渐变边框容器 + 内层内容容器
  // border 1px solid #9333EA, 霓虹发光双层阴影
  @Builder
  CyberpunkCard() {
    Stack() {
      // 外层：渐变边框容器
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            [CYBERPUNK_CYBER_PRIMARY, 0],
            [CYBERPUNK_CYBER_SECONDARY, 0.5],
            [CYBERPUNK_CYBER_PRIMARY, 1]
          ]
        })
        .borderRadius(CYBERPUNK_RADIUS)

      // 内层：内容容器
      Column() {
        this.content()
      }
      .width('100%')
      .padding(this.paddingValue)
      .backgroundColor('#B31A0A3A')
      .backgroundBlurStyle(BlurStyle.Thin)
      .borderRadius(CYBERPUNK_RADIUS - 2)
      .border({ width: 1, color: CYBERPUNK_BORDER, style: BorderStyle.Solid })
      .margin(2)
      // 主霓虹发光
      .shadow({
        radius: 15,
        color: '#40CC00FF',
        offsetX: 0,
        offsetY: 0
      })
      // 次级发光
      .shadow({
        radius: 30,
        color: '#2000FFCC',
        offsetX: 0,
        offsetY: 0
      })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .margin(this.marginValue)
  }
}

// ==================== UniCardHeader 头部容器 ====================

/**
 * UniCardHeader 头部容器
 * flex column + space-y + padding
 */
@Component
export struct UniCardHeader {
  // 插槽
  @BuilderParam content: () => void = defaultContent

  build() {
    Column({ space: 8 }) {
      this.content()
    }
    .width('100%')
    .padding({ left: 0, right: 0, top: 0, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }
}

// ==================== UniCardTitle 标题组件 ====================

/**
 * UniCardTitle 标题组件
 * text-2xl font-semibold，自动适配主题文字颜色
 */
@Component
export struct UniCardTitle {
  @StorageProp('currentStyle') storageStyle: string = UIStyle.Minimalist
  @Prop overrideStyle: string = ''
  @Prop title: string = ''

  private getCurrentStyle(): string {
    return this.overrideStyle || this.storageStyle
  }

  build() {
    Text(this.title)
      .fontSize(20)
      .fontWeight(FontWeight.Bolder)
      .fontColor(PrimaryTextColorMap.get(this.getCurrentStyle()) || '#1A1A1A')
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }
}

// ==================== UniCardDescription 描述组件 ====================

/**
 * UniCardDescription 描述组件
 * text-sm text-muted，自动适配主题次要文字颜色
 */
@Component
export struct UniCardDescription {
  @StorageProp('currentStyle') storageStyle: string = UIStyle.Minimalist
  @Prop overrideStyle: string = ''
  @Prop description: string = ''

  private getCurrentStyle(): string {
    return this.overrideStyle || this.storageStyle
  }

  build() {
    Text(this.description)
      .fontSize(14)
      .fontColor(SecondaryTextColorMap.get(this.getCurrentStyle()) || '#737373')
      .maxLines(3)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .margin({ top: 4 })
  }
}

// ==================== UniCardContent 内容容器 ====================

/**
 * UniCardContent 内容容器
 * padding with pt-0
 */
@Component
export struct UniCardContent {
  @BuilderParam content: () => void = defaultContent

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding({ left: 0, right: 0, top: 0, bottom: 0 })
    .alignItems(HorizontalAlign.Start)
  }
}

// ==================== UniCardFooter 底部容器 ====================

/**
 * UniCardFooter 底部容器
 * flex row items-center with pt-0
 */
@Component
export struct UniCardFooter {
  @BuilderParam content: () => void = defaultContent

  build() {
    Row() {
      this.content()
    }
    .width('100%')
    .padding({ top: 0 })
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Start)
  }
}

// ==================== 预览 ====================

/**
 * UniCardPreview 预览组件
 * 四种主题风格卡片并排展示
 */
@Preview
@Component
struct UniCardPreview {
  build() {
    Scroll() {
      Column({ space: 24 }) {
        Text('UniCard 四种主题风格预览')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })

        // ========== 极简风格 ==========
        Column() {
          Text('极简风格 (Minimalist)')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 12 })

          UniCard({ overrideStyle: UIStyle.Minimalist }) {
            UniCardHeader() {
              UniCardTitle({ overrideStyle: UIStyle.Minimalist, title: '极简卡片标题' })
              UniCardDescription({ overrideStyle: UIStyle.Minimalist, description: '圆角8px，1px浅色边框，极弱阴影' })
            }
            UniCardContent() {
              Text('这是卡片内容区域')
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(UIStyle.Minimalist))
            }
            UniCardFooter() {
              Text('底部操作区')
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(UIStyle.Minimalist))
            }
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(PageBackgroundMap.get(UIStyle.Minimalist))
        .borderRadius(8)

        // ========== 新拟态风格 ==========
        Column() {
          Text('新拟态风格 (Neumorphism)')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 12 })

          UniCard({ overrideStyle: UIStyle.Neumorphism }) {
            UniCardHeader() {
              UniCardTitle({ overrideStyle: UIStyle.Neumorphism, title: '新拟态卡片标题' })
              UniCardDescription({ overrideStyle: UIStyle.Neumorphism, description: '双层阴影凸起效果，8px偏移16px模糊' })
            }
            UniCardContent() {
              Text('这是卡片内容区域')
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(UIStyle.Neumorphism))
            }
            UniCardFooter() {
              Text('底部操作区')
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(UIStyle.Neumorphism))
            }
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(PageBackgroundMap.get(UIStyle.Neumorphism))
        .borderRadius(8)

        // ========== 粗野主义风格 ==========
        Column() {
          Text('粗野主义风格 (Brutalism)')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 12 })

          UniCard({ overrideStyle: UIStyle.Brutalism }) {
            UniCardHeader() {
              UniCardTitle({ overrideStyle: UIStyle.Brutalism, title: '粗野主义卡片标题' })
              UniCardDescription({ overrideStyle: UIStyle.Brutalism, description: '无圆角，黄色卡片，3px黑色粗边框，硬偏移阴影' })
            }
            UniCardContent() {
              Text('这是卡片内容区域')
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(UIStyle.Brutalism))
            }
            UniCardFooter() {
              Text('底部操作区')
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(UIStyle.Brutalism))
            }
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(PageBackgroundMap.get(UIStyle.Brutalism))
        .borderRadius(8)

        // ========== 赛博朋克风格 ==========
        Column() {
          Text('赛博朋克风格 (Cyberpunk)')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(CYBERPUNK_CYBER_SECONDARY)
            .margin({ bottom: 12 })

          UniCard({ overrideStyle: UIStyle.Cyberpunk }) {
            UniCardHeader() {
              UniCardTitle({ overrideStyle: UIStyle.Cyberpunk, title: '赛博朋克卡片标题' })
              UniCardDescription({ overrideStyle: UIStyle.Cyberpunk, description: '深色卡片，渐变边框，双层霓虹发光阴影' })
            }
            UniCardContent() {
              Text('这是卡片内容区域')
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(UIStyle.Cyberpunk))
            }
            UniCardFooter() {
              Text('底部操作区')
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(UIStyle.Cyberpunk))
            }
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(PageBackgroundMap.get(UIStyle.Cyberpunk))
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
