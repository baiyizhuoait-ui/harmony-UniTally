/**
 * CategoryIcon - 通用分类图标组件
 * 带颜色背景圆形容器 + emoji 图标
 * 用于 TransactionHall、ExpenseCalendar、DataDashboard 等页面
 */
import { UIStyle } from '../constants/UIStyleConst'

@Component
export struct CategoryIcon {
  @Prop icon: string = ''
  @Prop color: string = '#3B82F6'
  @Prop iconSize: number = 20
  @Prop containerSize: number = 40
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist

  build() {
    Stack() {
      Text(this.icon)
        .fontSize(this.iconSize)
        .textAlign(TextAlign.Center)
    }
    .width(this.containerSize)
    .height(this.containerSize)
    .borderRadius(this.getRadius())
    .backgroundColor(this.getBackgroundColor())
    .alignContent(Alignment.Center)
  }

  private getRadius(): number {
    switch (this.currentStyle) {
      case UIStyle.Brutalism:
        return 0
      case UIStyle.Neumorphism:
        return this.containerSize / 2
      case UIStyle.Cyberpunk:
        return 10
      case UIStyle.Minimalist:
      default:
        return 12
    }
  }

  private getBackgroundColor(): ResourceColor {
    // 12.5% opacity of category color
    return this.colorWithAlpha(this.color, 0.125)
  }

  private colorWithAlpha(hex: string, alpha: number): string {
    if (hex.length >= 7) {
      const r = parseInt(hex.substring(1, 3), 16)
      const g = parseInt(hex.substring(3, 5), 16)
      const b = parseInt(hex.substring(5, 7), 16)
      const a = Math.round(alpha * 255)
      return `#${a.toString(16).padStart(2, '0').toUpperCase()}${r.toString(16).padStart(2, '0').toUpperCase()}${g.toString(16).padStart(2, '0').toUpperCase()}${b.toString(16).padStart(2, '0').toUpperCase()}`
    }
    return hex
  }
}

@Preview
@Component
struct CategoryIconPreview {
  build() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        CategoryIcon({ icon: '🍔', color: '#EF4444', iconSize: 20, containerSize: 40 })
        CategoryIcon({ icon: '🚗', color: '#3B82F6', iconSize: 20, containerSize: 40 })
        CategoryIcon({ icon: '🎮', color: '#8B5CF6', iconSize: 20, containerSize: 40 })
        CategoryIcon({ icon: '💰', color: '#22C55E', iconSize: 20, containerSize: 40 })
      }

      Row({ space: 12 }) {
        CategoryIcon({ icon: '🍔', color: '#EF4444', iconSize: 28, containerSize: 56 })
        CategoryIcon({ icon: '🚗', color: '#3B82F6', iconSize: 28, containerSize: 56 })
        CategoryIcon({ icon: '🎮', color: '#8B5CF6', iconSize: 28, containerSize: 56 })
      }
    }
    .padding(24)
  }
}
