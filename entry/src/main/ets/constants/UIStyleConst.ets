/**
 * UI 风格常量定义
 * 精确还原原版 React 应用的 CSS 变量系统
 * HSL 值已转换为 HEX 以适配 ArkUI
 *
 * 原版 4 种风格：
 * - default (极简): radius 0.5rem, 无阴影, 1px 浅色边框
 * - neumorphism (新拟态): radius 1.5rem, 双层凸起/内凹阴影
 * - brutalism (粗野主义): radius 0px, 3px 黑色粗边框, 4px 硬偏移阴影
 * - cyberpunk (赛博朋克): radius 0.75rem, 霓虹渐变边框, 发光阴影
 */

// ==================== 风格枚举 ====================
export enum UIStyle {
  Minimalist = 'default',
  Neumorphism = 'neumorphism',
  Brutalism = 'brutalism',
  Cyberpunk = 'cyberpunk'
}

// ==================== 极简风格 (default) ====================
// 原版 CSS: --radius: 0.5rem, 无阴影, border: 1px solid hsl(0 0% 90%)
export const MINIMALIST_BACKGROUND: string = '#FFFFFF'       // hsl(0 0% 100%)
export const MINIMALIST_SURFACE: string = '#FAFAFA'          // hsl(0 0% 98%)
export const MINIMALIST_FOREGROUND: string = '#1A1A1A'       // hsl(0 0% 10%)
export const MINIMALIST_MUTED_FOREGROUND: string = '#737373' // hsl(0 0% 45%)
export const MINIMALIST_BORDER: string = '#E5E5E5'           // hsl(0 0% 90%)
export const MINIMALIST_INPUT: string = '#E5E5E5'            // hsl(0 0% 90%)
export const MINIMALIST_CARD: string = '#FFFFFF'             // hsl(0 0% 100%)
export const MINIMALIST_PRIMARY: string = '#3B82F6'          // hsl(221 83% 53%)
export const MINIMALIST_PRIMARY_FOREGROUND: string = '#FFFFFF'
export const MINIMALIST_SECONDARY: string = '#F5F5F5'        // hsl(0 0% 96%)
export const MINIMALIST_ACCENT: string = '#3B82F6'
export const MINIMALIST_DESTRUCTIVE: string = '#EF4444'      // hsl(0 84% 60%)
export const MINIMALIST_INCOME: string = '#22C55E'            // hsl(142 71% 45%)
export const MINIMALIST_EXPENSE: string = '#EF4444'           // hsl(0 84% 60%)
export const MINIMALIST_RADIUS: number = 8                    // 0.5rem ≈ 8px

// ==================== 新拟态风格 (neumorphism) ====================
// 原版 CSS: --radius: 1.5rem, 双层阴影 8px 8px 16px dark, -8px -8px 16px light
export const NEUMORPHISM_BACKGROUND: string = '#DDE3ED'       // hsl(220 15% 92%)
export const NEUMORPHISM_SURFACE: string = '#DDE3ED'
export const NEUMORPHISM_FOREGROUND: string = '#2D3748'       // hsl(220 20% 20%)
export const NEUMORPHISM_MUTED_FOREGROUND: string = '#8A9AB5' // hsl(220 15% 55%)
export const NEUMORPHISM_BORDER: string = '#C8D0DC'           // hsl(220 12% 85%)
export const NEUMORPHISM_INPUT: string = '#D1D9E6'            // hsl(220 15% 88%)
export const NEUMORPHISM_CARD: string = '#DDE3ED'
export const NEUMORPHISM_PRIMARY: string = '#3B82F6'
export const NEUMORPHISM_PRIMARY_FOREGROUND: string = '#FFFFFF'
export const NEUMORPHISM_SECONDARY: string = '#DDE3ED'
export const NEUMORPHISM_ACCENT: string = '#3B82F6'
export const NEUMORPHISM_DESTRUCTIVE: string = '#EF4444'
export const NEUMORPHISM_INCOME: string = '#22C55E'
export const NEUMORPHISM_EXPENSE: string = '#EF4444'
export const NEUMORPHISM_RADIUS: number = 24                   // 1.5rem ≈ 24px
// 新拟态专用阴影色
export const NEUMORPHISM_SHADOW_LIGHT: string = '#FFFFFF'      // hsl(0 0% 100%)
export const NEUMORPHISM_SHADOW_DARK: string = '#B8C4D6'      // hsl(223 10% 80%)

// ==================== 粗野主义风格 (brutalism) ====================
// 原版 CSS: --radius: 0px, border: 3px solid black, shadow: 4px 4px 0px 0px black
export const BRUTALISM_BACKGROUND: string = '#FAFAFA'       // hsl(0 0% 98%)
export const BRUTALISM_SURFACE: string = '#E6E6E6'          // hsl(0 0% 90%)
export const BRUTALISM_FOREGROUND: string = '#0D0D0D'       // hsl(0 0% 5%)
export const BRUTALISM_MUTED_FOREGROUND: string = '#4D4D4D' // hsl(0 0% 30%)
export const BRUTALISM_BORDER: string = '#0D0D0D'           // hsl(0 0% 5%)
export const BRUTALISM_INPUT: string = '#FFFFFF'
export const BRUTALISM_CARD: string = '#FFD700'             // hsl(50 100% 50%) 黄色卡片!
export const BRUTALISM_PRIMARY: string = '#0D0D0D'
export const BRUTALISM_PRIMARY_FOREGROUND: string = '#FFFFFF'
export const BRUTALISM_SECONDARY: string = '#E6E6E6'
export const BRUTALISM_ACCENT: string = '#FFD700'            // brutal-accent: hsl(45 100% 50%)
export const BRUTALISM_DESTRUCTIVE: string = '#EF4444'
export const BRUTALISM_INCOME: string = '#22C55E'
export const BRUTALISM_EXPENSE: string = '#EF4444'
export const BRUTALISM_RADIUS: number = 0                    // 强制 0 圆角
// 粗野主义专用
export const BRUTALISM_BORDER_WIDTH: number = 3               // 3px 粗边框
export const BRUTALISM_SHADOW_OFFSET: number = 4              // 4px 硬偏移阴影
export const BRUTALISM_SHADOW_OFFSET_LG: number = 6           // 6px 大号偏移

// ==================== 赛博朋克风格 (cyberpunk) ====================
// 原版 CSS: --radius: 0.75rem, 霓虹渐变边框, 发光阴影, 流动动画
export const CYBERPUNK_BACKGROUND: string = '#0F0526'       // hsl(260 50% 6%)
export const CYBERPUNK_SURFACE: string = '#1A0A3A'          // hsl(260 40% 10%)
export const CYBERPUNK_FOREGROUND: string = '#F0E6FF'       // hsl(280 100% 95%)
export const CYBERPUNK_MUTED_FOREGROUND: string = '#8B6BAE' // hsl(280 30% 60%)
export const CYBERPUNK_BORDER: string = '#9333EA'           // hsl(280 60% 50%)
export const CYBERPUNK_INPUT: string = '#1A0A3A'
export const CYBERPUNK_CARD: string = '#1A0A3A'             // hsl(260 40% 10%)
export const CYBERPUNK_PRIMARY: string = '#CC00FF'          // hsl(300 100% 50%) 品红
export const CYBERPUNK_PRIMARY_FOREGROUND: string = '#FFFFFF'
export const CYBERPUNK_SECONDARY: string = '#2D1B5E'        // hsl(280 30% 18%)
export const CYBERPUNK_ACCENT: string = '#00FFCC'           // hsl(180 100% 50%) 青色
export const CYBERPUNK_DESTRUCTIVE: string = '#FF0066'      // hsl(330 100% 50%)
export const CYBERPUNK_INCOME: string = '#00CCFF'           // hsl(200 100% 50%) accent3
export const CYBERPUNK_EXPENSE: string = '#FF0099'          // hsl(330 100% 60%) accent1
export const CYBERPUNK_RADIUS: number = 12                   // 0.75rem ≈ 12px
// 赛博朋克专用强调色
export const CYBERPUNK_CYBER_PRIMARY: string = '#CC00FF'     // 品红
export const CYBERPUNK_CYBER_SECONDARY: string = '#00FFCC'   // 青色
export const CYBERPUNK_CYBER_ACCENT1: string = '#FF0066'     // 玫红
export const CYBERPUNK_CYBER_ACCENT2: string = '#FFD700'     // 金黄
export const CYBERPUNK_CYBER_ACCENT3: string = '#00CCFF'     // 天蓝
export const CYBERPUNK_CYBER_ACCENT4: string = '#9933FF'     // 紫色
export const CYBERPUNK_CYBER_ACCENT5: string = '#00FF88'     // 绿色

// ==================== 统一导出的映射 ====================

// 页面背景色
export const PageBackgroundMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_BACKGROUND],
  [UIStyle.Neumorphism, NEUMORPHISM_BACKGROUND],
  [UIStyle.Brutalism, BRUTALISM_BACKGROUND],
  [UIStyle.Cyberpunk, CYBERPUNK_BACKGROUND]
])

// 主文字色
export const PrimaryTextColorMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_FOREGROUND],
  [UIStyle.Neumorphism, NEUMORPHISM_FOREGROUND],
  [UIStyle.Brutalism, BRUTALISM_FOREGROUND],
  [UIStyle.Cyberpunk, CYBERPUNK_FOREGROUND]
])

// 副文字色
export const SecondaryTextColorMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_MUTED_FOREGROUND],
  [UIStyle.Neumorphism, NEUMORPHISM_MUTED_FOREGROUND],
  [UIStyle.Brutalism, BRUTALISM_MUTED_FOREGROUND],
  [UIStyle.Cyberpunk, CYBERPUNK_MUTED_FOREGROUND]
])

// 卡片背景色
export const CardBackgroundMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_CARD],
  [UIStyle.Neumorphism, NEUMORPHISM_CARD],
  [UIStyle.Brutalism, BRUTALISM_CARD],
  [UIStyle.Cyberpunk, CYBERPUNK_CARD]
])

// 卡片边框色
export const CardBorderMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_BORDER],
  [UIStyle.Neumorphism, NEUMORPHISM_BORDER],
  [UIStyle.Brutalism, BRUTALISM_BORDER],
  [UIStyle.Cyberpunk, CYBERPUNK_BORDER]
])

// 圆角值
export const RadiusMap: Map<string, number> = new Map([
  [UIStyle.Minimalist, MINIMALIST_RADIUS],
  [UIStyle.Neumorphism, NEUMORPHISM_RADIUS],
  [UIStyle.Brutalism, BRUTALISM_RADIUS],
  [UIStyle.Cyberpunk, CYBERPUNK_RADIUS]
])

// 主色 (按钮、强调)
export const PrimaryColorMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_PRIMARY],
  [UIStyle.Neumorphism, NEUMORPHISM_PRIMARY],
  [UIStyle.Brutalism, BRUTALISM_ACCENT],
  [UIStyle.Cyberpunk, CYBERPUNK_CYBER_PRIMARY]
])

// 主色前景色 (按钮文字)
export const PrimaryForegroundMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_PRIMARY_FOREGROUND],
  [UIStyle.Neumorphism, NEUMORPHISM_PRIMARY_FOREGROUND],
  [UIStyle.Brutalism, BRUTALISM_FOREGROUND],
  [UIStyle.Cyberpunk, CYBERPUNK_FOREGROUND]
])

// 收入色
export const IncomeColorMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_INCOME],
  [UIStyle.Neumorphism, NEUMORPHISM_INCOME],
  [UIStyle.Brutalism, BRUTALISM_INCOME],
  [UIStyle.Cyberpunk, CYBERPUNK_INCOME]
])

// 支出色
export const ExpenseColorMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_EXPENSE],
  [UIStyle.Neumorphism, NEUMORPHISM_EXPENSE],
  [UIStyle.Brutalism, BRUTALISM_EXPENSE],
  [UIStyle.Cyberpunk, CYBERPUNK_EXPENSE]
])

// 输入框背景色
export const InputBackgroundMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_INPUT],
  [UIStyle.Neumorphism, NEUMORPHISM_INPUT],
  [UIStyle.Brutalism, BRUTALISM_INPUT],
  [UIStyle.Cyberpunk, CYBERPUNK_INPUT]
])

// 输入框边框色
export const InputBorderMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_BORDER],
  [UIStyle.Neumorphism, NEUMORPHISM_BORDER],
  [UIStyle.Brutalism, BRUTALISM_BORDER],
  [UIStyle.Cyberpunk, CYBERPUNK_BORDER]
])

// 分隔线颜色
export const DividerColorMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_BORDER],
  [UIStyle.Neumorphism, NEUMORPHISM_BORDER],
  [UIStyle.Brutalism, BRUTALISM_BORDER],
  [UIStyle.Cyberpunk, CYBERPUNK_BORDER]
])

// 次要背景色 (芯片、标签等)
export const SecondaryBackgroundMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_SECONDARY],
  [UIStyle.Neumorphism, NEUMORPHISM_SECONDARY],
  [UIStyle.Brutalism, BRUTALISM_SECONDARY],
  [UIStyle.Cyberpunk, CYBERPUNK_SECONDARY]
])

// 底部导航栏背景
export const TabBarBackgroundMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, '#FFFFFF'],
  [UIStyle.Neumorphism, '#DDE3ED'],
  [UIStyle.Brutalism, '#FFD700'],
  [UIStyle.Cyberpunk, '#0F0526']
])

// FAB 按钮背景色
export const FABBackgroundMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_PRIMARY],
  [UIStyle.Neumorphism, NEUMORPHISM_PRIMARY],
  [UIStyle.Brutalism, BRUTALISM_ACCENT],
  [UIStyle.Cyberpunk, CYBERPUNK_CYBER_PRIMARY]
])

// FAB 按钮图标色
export const FABIconColorMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, '#FFFFFF'],
  [UIStyle.Neumorphism, '#FFFFFF'],
  [UIStyle.Brutalism, '#0D0D0D'],
  [UIStyle.Cyberpunk, '#FFFFFF']
])

// 过滤芯片激活色
export const ChipActiveMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_PRIMARY],
  [UIStyle.Neumorphism, NEUMORPHISM_PRIMARY],
  [UIStyle.Brutalism, BRUTALISM_FOREGROUND],
  [UIStyle.Cyberpunk, CYBERPUNK_CYBER_PRIMARY]
])

// 过滤芯片非激活色
export const ChipInactiveMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, MINIMALIST_SECONDARY],
  [UIStyle.Neumorphism, NEUMORPHISM_SECONDARY],
  [UIStyle.Brutalism, BRUTALISM_SECONDARY],
  [UIStyle.Cyberpunk, CYBERPUNK_SECONDARY]
])

// 主色浅底色（选中项背景）
export const PrimaryBgMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, '#EBF2FF'],
  [UIStyle.Neumorphism, '#C8D8F0'],
  [UIStyle.Brutalism, '#FFF3B0'],
  [UIStyle.Cyberpunk, '#2D1B5E']
])

// 弹窗遮罩层
export const OverlayMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, 'rgba(0,0,0,0.4)'],
  [UIStyle.Neumorphism, 'rgba(0,0,0,0.3)'],
  [UIStyle.Brutalism, 'rgba(0,0,0,0.5)'],
  [UIStyle.Cyberpunk, 'rgba(15,5,38,0.7)']
])

// 危险/欠款提示背景
export const DangerBgMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, '#FFF5F5'],
  [UIStyle.Neumorphism, '#E8D0D0'],
  [UIStyle.Brutalism, '#FFD700'],
  [UIStyle.Cyberpunk, '#2D0A2D']
])

// 主色前景半透明（渐变卡片上的副文字）
export const PrimaryFgMutedMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, 'rgba(255,255,255,0.8)'],
  [UIStyle.Neumorphism, 'rgba(255,255,255,0.8)'],
  [UIStyle.Brutalism, 'rgba(13,13,13,0.7)'],
  [UIStyle.Cyberpunk, 'rgba(240,230,255,0.8)']
])

// ==================== 卡片阴影参数 ====================
// 阴影半径
export const ShadowRadiusMap: Map<string, number> = new Map([
  [UIStyle.Minimalist, 4],
  [UIStyle.Neumorphism, 16],
  [UIStyle.Brutalism, 0],
  [UIStyle.Cyberpunk, 12]
])
// 阴影颜色
export const ShadowColorMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, 'rgba(0,0,0,0.08)'],
  [UIStyle.Neumorphism, 'rgba(0,0,0,0.15)'],
  [UIStyle.Brutalism, 'rgba(0,0,0,1)'],
  [UIStyle.Cyberpunk, 'rgba(204,0,255,0.4)']
])
// 阴影X偏移
export const ShadowOffsetXMap: Map<string, number> = new Map([
  [UIStyle.Minimalist, 0],
  [UIStyle.Neumorphism, 8],
  [UIStyle.Brutalism, 4],
  [UIStyle.Cyberpunk, 0]
])
// 阴影Y偏移
export const ShadowOffsetYMap: Map<string, number> = new Map([
  [UIStyle.Minimalist, 2],
  [UIStyle.Neumorphism, 8],
  [UIStyle.Brutalism, 4],
  [UIStyle.Cyberpunk, 0]
])
// 新拟态亮面阴影颜色
export const ShadowLightColorMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, 'rgba(0,0,0,0)'],
  [UIStyle.Neumorphism, 'rgba(255,255,255,0.7)'],
  [UIStyle.Brutalism, 'rgba(0,0,0,0)'],
  [UIStyle.Cyberpunk, 'rgba(0,0,0,0)']
])

// ==================== 卡片边框参数 ====================
// 边框宽度
export const BorderWidthMap: Map<string, number> = new Map([
  [UIStyle.Minimalist, 0.5],
  [UIStyle.Neumorphism, 0],
  [UIStyle.Brutalism, 3],
  [UIStyle.Cyberpunk, 1]
])
// 边框颜色
export const BorderColorMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, '#E5E5E5'],
  [UIStyle.Neumorphism, 'transparent'],
  [UIStyle.Brutalism, '#0D0D0D'],
  [UIStyle.Cyberpunk, '#9333EA']
])
// 赛博朋克发光边框颜色（用于 box-shadow 模拟）
export const GlowBorderColorMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, 'rgba(0,0,0,0)'],
  [UIStyle.Neumorphism, 'rgba(0,0,0,0)'],
  [UIStyle.Brutalism, 'rgba(0,0,0,0)'],
  [UIStyle.Cyberpunk, 'rgba(147,51,234,0.3)']
])

// 净资产卡片渐变终止色
export const GradientEndMap: Map<string, string> = new Map([
  [UIStyle.Minimalist, '#8B5CF6'],
  [UIStyle.Neumorphism, '#7C3AED'],
  [UIStyle.Brutalism, '#F59E0B'],
  [UIStyle.Cyberpunk, '#00FFCC']
])