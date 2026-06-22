/**
 * Icon utility - maps lucide icon names to HarmonyOS system symbols
 * Falls back to emoji where no system symbol exists
 */

// Map of icon name -> HarmonyOS system symbol resource
// System symbols available: sys.symbol.xxxxx
const SYSTEM_SYMBOL_MAP: Map<string, string> = new Map([
  // Navigation
  ['chevron-left', 'sys.symbol.chevron_left'],
  ['chevron-right', 'sys.symbol.chevron_right'],
  ['chevron-down', 'sys.symbol.chevron_down'],
  ['chevron-up', 'sys.symbol.chevron_up'],
  ['arrow-right', 'sys.symbol.arrow_right'],
  ['arrow-left', 'sys.symbol.arrow_left'],

  // Actions
  ['plus', 'sys.symbol.plus'],
  ['x', 'sys.symbol.xmark'],
  ['check', 'sys.symbol.checkmark'],
  ['search', 'sys.symbol.magnifyingglass'],
  ['filter', 'sys.symbol.line_horizontal_3_decrease'],
  ['trash-2', 'sys.symbol.trash'],
  ['edit', 'sys.symbol.pencil'],
  ['pencil', 'sys.symbol.pencil'],
  ['settings', 'sys.symbol.gearshape'],
  ['download', 'sys.symbol.arrow_down_doc'],
  ['upload', 'sys.symbol.arrow_up_doc'],

  // Finance
  ['wallet', 'sys.symbol.wallet'],
  ['credit-card', 'sys.symbol.creditcard'],
  ['dollar-sign', 'sys.symbol.dollarsign'],
  ['trending-up', 'sys.symbol.chart_line_uptrend'],
  ['trending-down', 'sys.symbol.chart_line_downtrend'],
  ['bar-chart', 'sys.symbol.chart_bar'],
  ['pie-chart', 'sys.symbol.chart_pie'],

  // Calendar & Time
  ['calendar', 'sys.symbol.calendar'],
  ['clock', 'sys.symbol.clock'],
  ['bell', 'sys.symbol.bell'],
  ['alarm-clock', 'sys.symbol.alarm'],

  // Content
  ['file-text', 'sys.symbol.doc_text'],
  ['tag', 'sys.symbol.tag'],
  ['image', 'sys.symbol.photo'],
  ['link', 'sys.symbol.link'],
  ['bookmark', 'sys.symbol.bookmark'],

  // UI
  ['home', 'sys.symbol.house'],
  ['user', 'sys.symbol.person'],
  ['star', 'sys.symbol.star'],
  ['heart', 'sys.symbol.heart'],
  ['info', 'sys.symbol.info_circle'],
  ['alert-circle', 'sys.symbol.exclamationmark_circle'],
  ['help-circle', 'sys.symbol.questionmark_circle'],
  ['eye', 'sys.symbol.eye'],
  ['eye-off', 'sys.symbol.eye_slash'],
  ['lock', 'sys.symbol.lock'],
  ['unlock', 'sys.symbol.lock_open'],
  ['moon', 'sys.symbol.moon'],
  ['sun', 'sys.symbol.sun_max'],
  ['palette', 'sys.symbol.paintpalette'],
  ['globe', 'sys.symbol.globe'],
  ['building-2', 'sys.symbol.building'],
  ['smartphone', 'sys.symbol.iphone'],
  ['laptop', 'sys.symbol.laptopcomputer'],
  ['monitor', 'sys.symbol.desktopcomputer'],

  // Arrows & Movement
  ['move-up', 'sys.symbol.arrow_up'],
  ['move-down', 'sys.symbol.arrow_down'],
  ['refresh', 'sys.symbol.arrow_clockwise'],
  ['rotate-ccw', 'sys.symbol.arrow_counterclockwise'],
  ['external-link', 'sys.symbol.arrow_up_right'],
  ['repeat', 'sys.symbol.repeat'],
  ['shuffle', 'sys.symbol.shuffle'],
  ['share', 'sys.symbol.share'],
  ['copy', 'sys.symbol.doc_on_doc'],
])

// Emoji fallback for icons without system symbol mapping
const EMOJI_FALLBACK: Map<string, string> = new Map([
  ['wallet', '💰'],
  ['credit-card', '💳'],
  ['dollar-sign', '$'],
  ['filter', '🔽'],
  ['trash-2', '🗑️'],
  ['pencil', '✏️'],
  ['file-text', '📝'],
  ['tag', '🏷️'],
  ['bell', '🔔'],
  ['bar-chart', '📊'],
  ['pie-chart', '🥧'],
  ['calendar', '📅'],
  ['clock', '🕐'],
  ['image', '🖼️'],
  ['bookmark', '🔖'],
  ['link', '🔗'],
  ['building-2', '🏦'],
  ['smartphone', '📱'],
  ['palette', '🎨'],
  ['globe', '🌍'],
  ['moon', '🌙'],
  ['sun', '☀️'],
  ['repeat', '🔄'],
  ['share', '📤'],
  ['copy', '📋'],
  ['move-up', '⬆️'],
  ['move-down', '⬇️'],
])

export function hasSystemSymbol(iconName: string): boolean {
  return SYSTEM_SYMBOL_MAP.has(iconName)
}

export function getSystemSymbol(iconName: string): string {
  return SYSTEM_SYMBOL_MAP.get(iconName) ?? ''
}

export function getEmojiFallback(iconName: string): string {
  return EMOJI_FALLBACK.get(iconName) ?? '●'
}

/**
 * Build a SymbolGlyph or Text component based on icon name.
 * Returns the resource string for SymbolGlyph if available, or emoji fallback.
 */
export function getIconResource(iconName: string): ResourceStr {
  if (hasSystemSymbol(iconName)) {
    return $r(getSystemSymbol(iconName))
  }
  return getEmojiFallback(iconName)
}
