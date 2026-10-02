/**
 * 平台模型
 * 用于标记交易来源平台（支付宝、微信等）
 */
import { getTranslation, getCurrentLanguage } from '../constants/I18n'

@Observed
export class Platform {
  id: string = ''
  name: string = ''
  icon: string = ''
  color: string = '#607D8B'
  order: number = 0

  constructor(
    id: string = '',
    name: string = '',
    icon: string = '',
    color: string = '#607D8B',
    order: number = 0
  ) {
    this.id = id
    this.name = name
    this.icon = icon
    this.color = color
    this.order = order
  }

  toJson(): Record<string, Object> {
    return {
      'id': this.id,
      'name': this.name,
      'icon': this.icon,
      'color': this.color,
      'order': this.order
    }
  }

  static getLocalizedName(key: string): string {
    const t = getTranslation(getCurrentLanguage())
    const nameMap: Map<string, string> = new Map([
      ['plat_alipay', t.platAlipay],
      ['plat_wechat', t.platWechat],
      ['plat_jd', t.platJD],
      ['plat_meituan', t.platMeituan],
      ['plat_douyin', t.platDouyin],
      ['plat_taobao', t.platTaobao],
      ['plat_pdd', t.platPDD],
      ['plat_other', t.platOther]
    ])
    return nameMap.get(key) ?? key
  }
}

/**
 * 从 JSON 对象反序列化 Platform
 */
export function createPlatformFromJson(json: Record<string, Object>): Platform {
  const plat = new Platform()
  const id = json['id']
  plat.id = id !== undefined && id !== null ? String(id) : ''
  const name = json['name']
  plat.name = name !== undefined && name !== null ? String(name) : ''
  const icon = json['icon']
  plat.icon = icon !== undefined && icon !== null ? String(icon) : ''
  const color = json['color']
  plat.color = color !== undefined && color !== null ? String(color) : '#607D8B'
  const order = json['order']
  plat.order = order !== undefined && order !== null ? Number(order) : 0
  return plat
}

// Get default platforms with localized names (called at display time)
export function getDefaultPlatforms(): Platform[] {
  return [
    new Platform('plat_alipay', Platform.getLocalizedName('plat_alipay'), '📱', '#1677FF', 0),
    new Platform('plat_wechat', Platform.getLocalizedName('plat_wechat'), '💬', '#07C160', 1),
    new Platform('plat_jd', Platform.getLocalizedName('plat_jd'), '🛒', '#E2231A', 2),
    new Platform('plat_meituan', Platform.getLocalizedName('plat_meituan'), '🍜', '#FFD100', 3),
    new Platform('plat_douyin', Platform.getLocalizedName('plat_douyin'), '🎵', '#161823', 4),
    new Platform('plat_taobao', Platform.getLocalizedName('plat_taobao'), '🛍️', '#FF5000', 5),
    new Platform('plat_pdd', Platform.getLocalizedName('plat_pdd'), '🏷️', '#E02E24', 6),
    new Platform('plat_other', Platform.getLocalizedName('plat_other'), '📌', '#78909C', 7)
  ]
}

// Legacy static array for backward compatibility
export const DEFAULT_PLATFORMS: Platform[] = getDefaultPlatforms()
