/**
 * 订阅模型
 * 用于管理周期性订阅服务（如 Netflix、Spotify 等）
 * 包含提供商、金额、图标、日期范围和提醒设置
 */
import { getTranslation, getCurrentLanguage } from '../constants/I18n'
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

  static getLocalizedName(key: string): string {
    const t = getTranslation(getCurrentLanguage())
    const nameMap: Map<string, string> = new Map([
      ['food', t.subFood],
      ['transport', t.subTransport],
      ['shopping', t.subShopping],
      ['housing', t.subHousing],
      ['entertainment', t.subEntertainment],
      ['medical', t.subMedical],
      ['education', t.subEducation],
      ['grocery', t.subGrocery],
      ['drink', t.subDrink],
      ['fitness', t.subFitness],
      ['gift', t.subGift],
      ['telecom', t.subTelecom],
      ['clothing', t.subClothing],
      ['social', t.subSocial],
      ['other', t.subOther]
    ])
    return nameMap.get(key) ?? key
  }
}

// Get subscription icons with localized names (called at display time)
export function getSubscriptionIcons(): SubscriptionIconInfo[] {
  return [
    new SubscriptionIconInfo('food', SubscriptionIconInfo.getLocalizedName('food'), '🍜', '#f97316', 0),
    new SubscriptionIconInfo('transport', SubscriptionIconInfo.getLocalizedName('transport'), '🚗', '#3b82f6', 1),
    new SubscriptionIconInfo('shopping', SubscriptionIconInfo.getLocalizedName('shopping'), '🛍️', '#ec4899', 2),
    new SubscriptionIconInfo('housing', SubscriptionIconInfo.getLocalizedName('housing'), '🏠', '#8b5cf6', 3),
    new SubscriptionIconInfo('entertainment', SubscriptionIconInfo.getLocalizedName('entertainment'), '🎮', '#06b6d4', 4),
    new SubscriptionIconInfo('medical', SubscriptionIconInfo.getLocalizedName('medical'), '🏥', '#ef4444', 5),
    new SubscriptionIconInfo('education', SubscriptionIconInfo.getLocalizedName('education'), '📚', '#14b8a6', 6),
    new SubscriptionIconInfo('grocery', SubscriptionIconInfo.getLocalizedName('grocery'), '🧴', '#a3e635', 7),
    new SubscriptionIconInfo('drink', SubscriptionIconInfo.getLocalizedName('drink'), '🧋', '#10b981', 8),
    new SubscriptionIconInfo('fitness', SubscriptionIconInfo.getLocalizedName('fitness'), '💪', '#f59e0b', 9),
    new SubscriptionIconInfo('gift', SubscriptionIconInfo.getLocalizedName('gift'), '🎁', '#ec4899', 10),
    new SubscriptionIconInfo('telecom', SubscriptionIconInfo.getLocalizedName('telecom'), '📱', '#6366f1', 11),
    new SubscriptionIconInfo('clothing', SubscriptionIconInfo.getLocalizedName('clothing'), '👗', '#f43f5e', 12),
    new SubscriptionIconInfo('social', SubscriptionIconInfo.getLocalizedName('social'), '🍻', '#fbbf24', 13),
    new SubscriptionIconInfo('other', SubscriptionIconInfo.getLocalizedName('other'), '📦', '#78716c', 14)
  ]
}

// Legacy static array for backward compatibility
export const SUBSCRIPTION_ICONS: SubscriptionIconInfo[] = getSubscriptionIcons()
