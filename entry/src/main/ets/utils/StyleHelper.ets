/**
 * 共享样式辅助函数
 * 供 Index 及所有子组件使用，避免在每个 @Component 中重复定义 sXxx() 方法
 */
import {
  UIStyle,
  PrimaryTextColorMap, SecondaryTextColorMap,
  CardBackgroundMap, CardBorderMap, RadiusMap, PrimaryColorMap,
  IncomeColorMap, ExpenseColorMap, SecondaryBackgroundMap,
  TabBarBackgroundMap, FABBackgroundMap, FABIconColorMap,
  ChipActiveMap, ChipInactiveMap, PrimaryForegroundMap,
  PrimaryBgMap, OverlayMap, DangerBgMap, PrimaryFgMutedMap,
  ShadowRadiusMap, ShadowColorMap, ShadowOffsetXMap, ShadowOffsetYMap,
  ShadowLightColorMap, BorderWidthMap, BorderColorMap, GlowBorderColorMap,
  GradientEndMap
} from '../constants/UIStyleConst'

// 阴影配置接口
export interface CardShadowConfig {
  radius: number
  color: string
  offsetX: number
  offsetY: number
}

export class StyleHelper {
  static sPageBg(style: string): string { return '#F1F3F5' }
  static sFg(style: string): string { return PrimaryTextColorMap.get(style) ?? '#1A1A1A' }
  static sFgMuted(style: string): string { return SecondaryTextColorMap.get(style) ?? '#737373' }
  static sCardBg(style: string): string { return CardBackgroundMap.get(style) ?? '#FFFFFF' }
  static sCardBorder(style: string): string { return CardBorderMap.get(style) ?? '#E5E5E5' }
  static sRadius(style: string): number { return RadiusMap.get(style) ?? 8 }
  static sPrimary(themeColor: string): string { return themeColor }
  static sPrimaryFg(style: string): string { return PrimaryForegroundMap.get(style) ?? '#FFFFFF' }
  static sIncome(style: string): string { return IncomeColorMap.get(style) ?? '#22C55E' }
  static sExpense(style: string): string { return ExpenseColorMap.get(style) ?? '#EF4444' }
  static sSecondaryBg(style: string): string { return SecondaryBackgroundMap.get(style) ?? '#F5F5F5' }
  static sTabBarBg(style: string): string { return TabBarBackgroundMap.get(style) ?? '#FFFFFF' }
  static sFABBg(themeColor: string): string { return themeColor }
  static sFABIcon(style: string): string { return FABIconColorMap.get(style) ?? '#FFFFFF' }
  static sChipActive(themeColor: string): string { return themeColor }
  static sChipInactive(style: string): string { return ChipInactiveMap.get(style) ?? '#F5F5F5' }
  static sPrimaryBg(style: string): string { return PrimaryBgMap.get(style) ?? '#EBF2FF' }
  static sOverlay(style: string): string { return OverlayMap.get(style) ?? 'rgba(0,0,0,0.4)' }
  static sDangerBg(style: string): string { return DangerBgMap.get(style) ?? '#FFF5F5' }
  static sPrimaryFgMuted(style: string): string { return PrimaryFgMutedMap.get(style) ?? 'rgba(255,255,255,0.8)' }
  static sIsBrutalism(style: string): boolean { return style === UIStyle.Brutalism }
  static sIsNeumorphism(style: string): boolean { return style === UIStyle.Neumorphism }
  static sIsCyberpunk(style: string): boolean { return style === UIStyle.Cyberpunk }

  // 卡片主阴影
  static sCardShadow(style: string): CardShadowConfig {
    return {
      radius: ShadowRadiusMap.get(style) ?? 4,
      color: ShadowColorMap.get(style) ?? 'rgba(0,0,0,0.08)',
      offsetX: ShadowOffsetXMap.get(style) ?? 0,
      offsetY: ShadowOffsetYMap.get(style) ?? 2
    }
  }
  // 新拟态亮面阴影（仅新拟态风格有效）
  static sCardShadowLight(style: string): CardShadowConfig {
    return {
      radius: 16,
      color: ShadowLightColorMap.get(style) ?? 'rgba(0,0,0,0)',
      offsetX: -8,
      offsetY: -8
    }
  }
  // 卡片边框宽度
  static sBorderWidth(style: string): number { return BorderWidthMap.get(style) ?? 0.5 }
  // 卡片边框颜色
  static sBorderColor(style: string): string { return BorderColorMap.get(style) ?? '#E5E5E5' }
  // 赛博朋克发光边框颜色
  static sGlowBorderColor(style: string): string { return GlowBorderColorMap.get(style) ?? 'rgba(0,0,0,0)' }
  // 净资产卡片渐变终止色
  static sGradientEnd(style: string): string { return GradientEndMap.get(style) ?? '#8B5CF6' }
}
