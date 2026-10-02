/**
 * 平台模型
 * 用于标记交易来源平台（支付宝、微信等）
 */
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

// 默认平台列表
export const DEFAULT_PLATFORMS: Platform[] = [
  new Platform('plat_alipay', '支付宝', '📱', '#1677FF', 0),
  new Platform('plat_wechat', '微信支付', '💬', '#07C160', 1),
  new Platform('plat_jd', '京东', '🛒', '#E2231A', 2),
  new Platform('plat_meituan', '美团', '🍜', '#FFD100', 3),
  new Platform('plat_douyin', '抖音', '🎵', '#161823', 4),
  new Platform('plat_taobao', '淘宝', '🛍️', '#FF5000', 5),
  new Platform('plat_pdd', '拼多多', '🏷️', '#E02E24', 6),
  new Platform('plat_other', '其他', '📌', '#78909C', 7)
]
