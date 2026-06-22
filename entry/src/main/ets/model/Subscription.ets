/**
 * 订阅模型
 * 用于管理周期性订阅服务（如 Netflix、Spotify 等）
 * 包含提供商、金额、图标、日期范围和提醒设置
 */
@Observed
export class Subscription {
  id: string = ''
  provider: string = ''
  name: string = ''
  amount: number = 0
  currency: string = 'CNY'
  icon: string = '📦'
  iconColor: string = '#3b82f6'
  startDate: string = ''
  endDate: string = ''
  note: string = ''
  notifyEnabled: boolean = false
  notifyDaysBefore: number = 3
  createdAt: number = 0

  constructor(
    id: string = '',
    provider: string = '',
    name: string = '',
    amount: number = 0,
    currency: string = 'CNY',
    icon: string = '📦',
    iconColor: string = '#3b82f6',
    startDate: string = '',
    endDate: string = '',
    note: string = '',
    notifyEnabled: boolean = false,
    notifyDaysBefore: number = 3,
    createdAt: number = Date.now()
  ) {
    this.id = id
    this.provider = provider
    this.name = name
    this.amount = amount
    this.currency = currency
    this.icon = icon
    this.iconColor = iconColor
    this.startDate = startDate
    this.endDate = endDate
    this.note = note
    this.notifyEnabled = notifyEnabled
    this.notifyDaysBefore = notifyDaysBefore
    this.createdAt = createdAt
  }

  /**
   * 判断订阅是否已过期
   */
  isExpired(): boolean {
    if (!this.endDate) {
      return false
    }
    const today = this.getTodayStr()
    return today > this.endDate
  }

  /**
   * 获取剩余天数
   */
  getDaysRemaining(): number {
    if (!this.endDate) {
      return 0
    }
    const today = new Date(this.getTodayStr())
    const end = new Date(this.endDate)
    const diff = end.getTime() - today.getTime()
    return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)))
  }

  private getTodayStr(): string {
    const now = new Date()
    const y = now.getFullYear()
    const m = String(now.getMonth() + 1).padStart(2, '0')
    const d = String(now.getDate()).padStart(2, '0')
    return `${y}-${m}-${d}`
  }

  toJson(): Record<string, Object> {
    return {
      'id': this.id,
      'provider': this.provider,
      'name': this.name,
      'amount': this.amount,
      'currency': this.currency,
      'icon': this.icon,
      'iconColor': this.iconColor,
      'startDate': this.startDate,
      'endDate': this.endDate,
      'note': this.note,
      'notifyEnabled': this.notifyEnabled,
      'notifyDaysBefore': this.notifyDaysBefore,
      'createdAt': this.createdAt
    }
  }
}

/**
 * 从 JSON 对象反序列化 Subscription
 */
export function createSubscriptionFromJson(json: Record<string, Object>): Subscription {
  const sub = new Subscription()
  const id = json['id']
  sub.id = id !== undefined && id !== null ? String(id) : ''
  const provider = json['provider']
  sub.provider = provider !== undefined && provider !== null ? String(provider) : ''
  const name = json['name']
  sub.name = name !== undefined && name !== null ? String(name) : ''
  const amount = json['amount']
  sub.amount = amount !== undefined && amount !== null ? Number(amount) : 0
  const currency = json['currency']
  sub.currency = currency !== undefined && currency !== null ? String(currency) : 'CNY'
  const icon = json['icon']
  sub.icon = icon !== undefined && icon !== null ? String(icon) : '📦'
  const iconColor = json['iconColor']
  sub.iconColor = iconColor !== undefined && iconColor !== null ? String(iconColor) : '#3b82f6'
  const startDate = json['startDate']
  sub.startDate = startDate !== undefined && startDate !== null ? String(startDate) : ''
  const endDate = json['endDate']
  sub.endDate = endDate !== undefined && endDate !== null ? String(endDate) : ''
  const note = json['note']
  sub.note = note !== undefined && note !== null ? String(note) : ''
  const notifyEnabled = json['notifyEnabled']
  sub.notifyEnabled = notifyEnabled !== undefined && notifyEnabled !== null ? Boolean(notifyEnabled) : false
  const notifyDaysBefore = json['notifyDaysBefore']
  sub.notifyDaysBefore = notifyDaysBefore !== undefined && notifyDaysBefore !== null ? Number(notifyDaysBefore) : 3
  const createdAt = json['createdAt']
  sub.createdAt = createdAt !== undefined && createdAt !== null ? Number(createdAt) : 0
  return sub
}

/**
 * 默认订阅图标列表
 */
export const DEFAULT_SUBSCRIPTION_ICONS: string[] = [
  '📺', '🎵', '💻', '🎮', '📱', '☁️', '🛡️', '📦', '📰', '🏋️', '🎓', '🚗'
]

/**
 * 订阅图标详细信息（含名称和颜色）
 */
export class SubscriptionIconInfo {
  id: string = ''
  name: string = ''
  icon: string = ''
  color: string = ''
  order: number = 0

  constructor(id: string, name: string, icon: string, color: string, order: number) {
    this.id = id
    this.name = name
    this.icon = icon
    this.color = color
    this.order = order
  }
}

export const SUBSCRIPTION_ICONS: SubscriptionIconInfo[] = [
  new SubscriptionIconInfo('food', '餐饮', '🍜', '#f97316', 0),
  new SubscriptionIconInfo('transport', '交通', '🚗', '#3b82f6', 1),
  new SubscriptionIconInfo('shopping', '购物', '🛍️', '#ec4899', 2),
  new SubscriptionIconInfo('housing', '住房', '🏠', '#8b5cf6', 3),
  new SubscriptionIconInfo('entertainment', '娱乐', '🎮', '#06b6d4', 4),
  new SubscriptionIconInfo('medical', '医疗', '🏥', '#ef4444', 5),
  new SubscriptionIconInfo('education', '教育', '📚', '#14b8a6', 6),
  new SubscriptionIconInfo('grocery', '日用', '🧴', '#a3e635', 7),
  new SubscriptionIconInfo('drink', '饮料', '🧋', '#10b981', 8),
  new SubscriptionIconInfo('fitness', '健身', '💪', '#f59e0b', 9),
  new SubscriptionIconInfo('gift', '礼品', '🎁', '#ec4899', 10),
  new SubscriptionIconInfo('telecom', '通讯', '📱', '#6366f1', 11),
  new SubscriptionIconInfo('clothing', '服饰', '👗', '#f43f5e', 12),
  new SubscriptionIconInfo('social', '社交', '🍻', '#fbbf24', 13),
  new SubscriptionIconInfo('other', '其他', '📦', '#78716c', 14)
]
