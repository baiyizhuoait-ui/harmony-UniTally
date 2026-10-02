/**
 * 钱包账户模型
 * 支持 cash/savings/credit/ewallet 四种类型
 * 信用卡类型 UI 层面显示"可用额度"而非"当前余额"
 */
import { WalletType } from '../constants/CurrencyConst'
import { getTranslation, getCurrentLanguage } from '../constants/I18n'

@Observed
export class Wallet {
  id: string = ''
  name: string = ''
  color: string = '#607D8B'
  icon: string = '💰'
  currency: string = 'CNY'
  balance: number = 0
  type: WalletType = WalletType.Cash
  creditLimit: number = 0    // 信用卡特有: 信用额度
  billingDay: number = 1     // 账单日
  dueDay: number = 1         // 还款日
  remindDays: number = 3     // 提前提醒天数
  isDefault: boolean = false
  order: number = 0

  constructor(
    id: string = '',
    name: string = '',
    color: string = '#607D8B',
    icon: string = '💰',
    currency: string = 'CNY',
    balance: number = 0,
    type: WalletType = WalletType.Cash,
    order: number = 0
  ) {
    this.id = id
    this.name = name
    this.color = color
    this.icon = icon
    this.currency = currency
    this.balance = balance
    this.type = type
    this.order = order
  }

  /**
   * 获取显示余额
   * 信用卡类型显示可用额度 = creditLimit + balance（balance 为负数表示欠款）
   * 其他类型直接显示 balance
   */
  getDisplayBalance(): number {
    if (this.type === WalletType.Credit) {
      return this.creditLimit + this.balance
    }
    return this.balance
  }

  /**
   * 判断是否为信用卡类型
   */
  isCreditCard(): boolean {
    return this.type === WalletType.Credit
  }

  /**
   * 序列化为 JSON 对象
   */
  toJson(): Record<string, Object> {
    return {
      'id': this.id,
      'name': this.name,
      'color': this.color,
      'icon': this.icon,
      'currency': this.currency,
      'balance': this.balance,
      'type': this.type,
      'creditLimit': this.creditLimit,
      'billingDay': this.billingDay,
      'dueDay': this.dueDay,
      'remindDays': this.remindDays,
      'isDefault': this.isDefault,
      'order': this.order
    }
  }
}

/**
 * 根据货币自动创建默认现金钱包
 */
export function createDefaultCashWallet(currency: string, color: string): Wallet {
  return new Wallet(
    `wallet_${Date.now()}`,
    getTranslation(getCurrentLanguage()).defaultCash,
    color,
    '💰',
    currency,
    0,
    WalletType.Cash,
    0
  )
}

/**
 * 从 JSON 对象反序列化 Wallet
 */
export function createWalletFromJson(json: Record<string, Object>): Wallet {
  const wallet = new Wallet()
  const id = json['id']
  wallet.id = id !== undefined && id !== null ? String(id) : ''
  const name = json['name']
  wallet.name = name !== undefined && name !== null ? String(name) : ''
  const color = json['color']
  wallet.color = color !== undefined && color !== null ? String(color) : '#607D8B'
  const icon = json['icon']
  wallet.icon = icon !== undefined && icon !== null ? String(icon) : '💰'
  const currency = json['currency']
  wallet.currency = currency !== undefined && currency !== null ? String(currency) : 'CNY'
  const balance = json['balance']
  wallet.balance = balance !== undefined && balance !== null ? Number(balance) : 0
  const type = json['type']
  if (type !== undefined && type !== null) {
    if (type === WalletType.Cash || type === WalletType.Savings || type === WalletType.Credit || type === WalletType.EWallet) {
      wallet.type = type as WalletType
    }
  }
  const creditLimit = json['creditLimit']
  wallet.creditLimit = creditLimit !== undefined && creditLimit !== null ? Number(creditLimit) : 0
  const billingDay = json['billingDay']
  wallet.billingDay = billingDay !== undefined && billingDay !== null ? Number(billingDay) : 1
  const dueDay = json['dueDay']
  wallet.dueDay = dueDay !== undefined && dueDay !== null ? Number(dueDay) : 1
  const remindDays = json['remindDays']
  wallet.remindDays = remindDays !== undefined && remindDays !== null ? Number(remindDays) : 3
  const isDefault = json['isDefault']
  wallet.isDefault = isDefault !== undefined && isDefault !== null ? Boolean(isDefault) : false
  const order = json['order']
  wallet.order = order !== undefined && order !== null ? Number(order) : 0
  return wallet
}
